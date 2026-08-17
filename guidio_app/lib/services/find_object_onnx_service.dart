/// FindObjectOnnxService — inferensi YOLOE on-device via ONNX Runtime.
///
/// Pipeline per-frame:
///   1. Decode JPEG → resize 640×640 → float32 normalized [0,1]
///   2. Jalankan ONNX (output [1,116,8400])
///   3. Parse bbox + class scores (80 kelas COCO)
///   4. Filter by target class indices + confidence threshold
///   5. NMS sederhana
///   6. Color check pada bbox region (opsional, jika ada color constraint)
///   7. Return {found, direction, distance_meter, total_match, message}
///
/// Model: yoloe_find.onnx (11.6 MB INT8 quantized dari yoloe-11s-seg)
library find_object_onnx_service;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../core/voice/object_label_map.dart';

const String _modelAsset = 'assets/models/yoloe_find.onnx';
const int _inputSize = 640;
const double _confThreshold = 0.35;
const double _nmsIouThreshold = 0.5;
const int _numClasses = 80;

class FindObjectOnnxService {
  OrtSession? _session;
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;

  // ──────────────────────────────────── Lazy load ──────────────────────────

  Future<bool> ensureLoaded() async {
    if (_loaded) return true;
    if (_loading) {
      // Tunggu selesai
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _loaded;
    }
    _loading = true;
    try {
      OrtEnv.instance.init();
      final bytes = await rootBundle.load(_modelAsset);
      final modelData = bytes.buffer.asUint8List();
      final opts = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelData, opts);
      _loaded = true;
      return true;
    } catch (e) {
      return false;
    } finally {
      _loading = false;
    }
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _loaded = false;
  }

  // ──────────────────────────────────── Inference ──────────────────────────

  /// Cari objek dalam [jpegBytes].
  /// [queryId] = nama objek dalam bahasa Indonesia (mis. "tas merah").
  /// Returns map dengan kunci: found, direction, distance_meter, total_match, message.
  Future<Map<String, dynamic>> findObject(
    Uint8List jpegBytes,
    String queryId,
  ) async {
    if (!await ensureLoaded()) {
      return _result(found: false, message: 'Model belum siap.', reason: 'model_unavailable');
    }

    // ── Parse query ───────────────────────────────────────────────────────
    final (objectKey, colorKey) = parseQuery(queryId);
    final targetIndices = resolveClassIndices(objectKey);
    if (targetIndices.isEmpty) {
      return _result(
        found: false,
        message: 'Maaf, "$queryId" belum saya kenali. Coba nama lain.',
        reason: 'unknown_object',
      );
    }

    // ── Decode & preprocess ───────────────────────────────────────────────
    final image = img.decodeImage(jpegBytes);
    if (image == null) {
      return _result(found: false, message: 'Frame tidak terbaca.', reason: 'invalid_frame');
    }
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final inputData = _imageToFloat32(resized);

    // ── ONNX inference ────────────────────────────────────────────────────
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, 3, _inputSize, _inputSize],
    );
    final feeds = {'images': inputTensor};
    List<OrtValue?>? outputs;
    try {
      outputs = await _session!.runAsync(OrtRunOptions(), feeds);
    } catch (_) {
      inputTensor.release();
      return _result(found: false, message: 'Gagal memproses frame.', reason: 'inference_failed');
    }
    inputTensor.release();

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      return _result(found: false, message: 'Output tidak valid.', reason: 'inference_failed');
    }

    // ── Parse output [1, 116, 8400] ──────────────────────────────────────
    final rawOutput = outputs[0]!.value as List; // [1][116][8400]
    final anchors = _parseAnchors(rawOutput);

    // Release outputs
    for (final o in outputs) {
      o?.release();
    }

    // ── Filter by confidence & target class ───────────────────────────────
    final candidates = <_Detection>[];
    for (final anchor in anchors) {
      if (anchor.confidence < _confThreshold) continue;
      if (!targetIndices.contains(anchor.classIdx)) continue;
      candidates.add(anchor);
    }

    if (candidates.isEmpty) {
      return _result(found: false, message: 'Putar badan perlahan, saya sedang memindai.', reason: 'not_in_frame');
    }

    // ── NMS ───────────────────────────────────────────────────────────────
    final kept = _nms(candidates);

    // ── Color filter ─────────────────────────────────────────────────────
    final filtered = colorKey != null
        ? _filterByColor(kept, image, colorKey)
        : kept;

    if (filtered.isEmpty) {
      return _result(
        found: false,
        message: 'Ada ${kept.length > 1 ? "${kept.length} " : ""}${objectKey.isNotEmpty ? objectKey : queryId} di sekitar, tapi tidak ada yang $colorKey.',
        reason: 'not_in_frame',
      );
    }

    // ── Sort by closest (largest bbox = closest) ──────────────────────────
    filtered.sort((a, b) => b.bboxH.compareTo(a.bboxH));
    final nearest = filtered.first;
    final cocoName = cocoLabels[nearest.classIdx];
    final distanceM = estimateDistance(nearest.bboxH * _inputSize, cocoName).clamp(0.3, 10.0);
    final direction = _bboxToDirection(nearest.cx);

    final distText = distanceM < 1.0
        ? 'kurang dari satu meter'
        : '${distanceM.toStringAsFixed(1)} meter';
    final colorText = colorKey != null ? '$colorKey ' : '';
    final countText = filtered.length > 1
        ? 'Ada ${filtered.length} $colorText$objectKey. Yang terdekat'
        : colorText.isNotEmpty
            ? colorText[0].toUpperCase() + colorText.substring(1)
            : objectKey[0].toUpperCase() + objectKey.substring(1);
    final message = '$countText di $direction, sekitar $distText.';

    return {
      'found': true,
      'nearest': {
        'direction': direction,
        'distance_meter': distanceM,
      },
      'total_match': filtered.length,
      'message': message,
    };
  }

  // ──────────────────────────────────── Helpers ─────────────────────────────

  Float32List _imageToFloat32(img.Image image) {
    final data = Float32List(3 * _inputSize * _inputSize);
    int idx = 0;
    // ONNX input format: CHW (channel-first), normalized 0..1
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = image.getPixel(x, y);
          final val = c == 0
              ? pixel.r.toDouble()
              : c == 1
                  ? pixel.g.toDouble()
                  : pixel.b.toDouble();
          data[idx++] = val / 255.0;
        }
      }
    }
    return data;
  }

  /// Parse raw ONNX output shape [1][116][8400] → list of Detection.
  List<_Detection> _parseAnchors(List rawOutput) {
    // rawOutput[0] = tensor batch 0 → shape [116][8400]
    final batch = rawOutput[0] as List; // 116 channels
    final numAnchors = (batch[0] as List).length; // 8400

    final detections = <_Detection>[];
    for (int i = 0; i < numAnchors; i++) {
      // bbox (cx, cy, w, h) — normalized to input size 640
      final cx = (batch[0] as List)[i] as double;
      final cy = (batch[1] as List)[i] as double;
      final w = (batch[2] as List)[i] as double;
      final h = (batch[3] as List)[i] as double;

      // Class scores [4..83]
      double maxScore = 0;
      int maxIdx = 0;
      for (int c = 0; c < _numClasses; c++) {
        final score = _sigmoid((batch[4 + c] as List)[i] as double);
        if (score > maxScore) {
          maxScore = score;
          maxIdx = c;
        }
      }

      detections.add(_Detection(
        cx: cx / _inputSize,
        cy: cy / _inputSize,
        bboxW: w / _inputSize,
        bboxH: h / _inputSize,
        confidence: maxScore,
        classIdx: maxIdx,
      ));
    }
    return detections;
  }

  List<_Detection> _nms(List<_Detection> dets) {
    final sorted = List.of(dets)..sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <_Detection>[];
    final suppressed = List.filled(sorted.length, false);

    for (int i = 0; i < sorted.length; i++) {
      if (suppressed[i]) continue;
      kept.add(sorted[i]);
      for (int j = i + 1; j < sorted.length; j++) {
        if (_iou(sorted[i], sorted[j]) > _nmsIouThreshold) suppressed[j] = true;
      }
    }
    return kept;
  }

  double _iou(_Detection a, _Detection b) {
    final ax1 = a.cx - a.bboxW / 2, ay1 = a.cy - a.bboxH / 2;
    final ax2 = a.cx + a.bboxW / 2, ay2 = a.cy + a.bboxH / 2;
    final bx1 = b.cx - b.bboxW / 2, by1 = b.cy - b.bboxH / 2;
    final bx2 = b.cx + b.bboxW / 2, by2 = b.cy + b.bboxH / 2;
    final interX = (ax2 < bx2 ? ax2 : bx2) - (ax1 > bx1 ? ax1 : bx1);
    final interY = (ay2 < by2 ? ay2 : by2) - (ay1 > by1 ? ay1 : by1);
    if (interX <= 0 || interY <= 0) return 0;
    final inter = interX * interY;
    final aArea = a.bboxW * a.bboxH;
    final bArea = b.bboxW * b.bboxH;
    return inter / (aArea + bArea - inter);
  }

  List<_Detection> _filterByColor(
    List<_Detection> dets,
    img.Image originalImage,
    String colorKey,
  ) {
    final result = <_Detection>[];
    final srcW = originalImage.width.toDouble();
    final srcH = originalImage.height.toDouble();

    for (final det in dets) {
      // Crop bbox dari gambar asli (sebelum resize)
      final x1 = ((det.cx - det.bboxW / 2) * srcW).clamp(0, srcW - 1).toInt();
      final y1 = ((det.cy - det.bboxH / 2) * srcH).clamp(0, srcH - 1).toInt();
      final x2 = ((det.cx + det.bboxW / 2) * srcW).clamp(x1 + 1, srcW).toInt();
      final y2 = ((det.cy + det.bboxH / 2) * srcH).clamp(y1 + 1, srcH).toInt();

      // Ambil sampel piksel (max 100 titik untuk efisiensi)
      final samples = <List<int>>[];
      final stepX = ((x2 - x1) / 10).ceil().clamp(1, 999);
      final stepY = ((y2 - y1) / 10).ceil().clamp(1, 999);
      for (int y = y1; y < y2; y += stepY) {
        for (int x = x1; x < x2; x += stepX) {
          final p = originalImage.getPixel(x, y);
          samples.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
        }
      }

      if (checkColorMatch(colorKey, samples)) result.add(det);
    }
    return result;
  }

  String _bboxToDirection(double cx) {
    if (cx < 0.33) return 'kiri';
    if (cx > 0.66) return 'kanan';
    return 'depan';
  }

  double _sigmoid(double x) => 1.0 / (1.0 + _exp(-x));
  double _exp(double x) => x < -88 ? 0 : x > 88 ? 1e38 : _expApprox(x);
  double _expApprox(double x) {
    // Fast exp approximation — cukup akurat untuk sigmoid classification
    var v = 1.0 + x / 256.0;
    v *= v; v *= v; v *= v; v *= v;
    v *= v; v *= v; v *= v; v *= v;
    return v;
  }

  Map<String, dynamic> _result({
    required bool found,
    required String message,
    String reason = 'not_in_frame',
  }) => {'found': found, 'message': message, 'reason': reason};
}

// ─────────────────────────────────────────────────────────────────────────────

class _Detection {
  final double cx, cy, bboxW, bboxH, confidence;
  final int classIdx;
  const _Detection({
    required this.cx,
    required this.cy,
    required this.bboxW,
    required this.bboxH,
    required this.confidence,
    required this.classIdx,
  });
}
