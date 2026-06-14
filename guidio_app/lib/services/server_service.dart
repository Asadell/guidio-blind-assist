import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Emulator Android  : 10.0.2.2:8000
// Device fisik      : ganti dengan IP laptop di jaringan yang sama, misal 192.168.1.x:8000
const String _serverHost = '10.0.2.2:8000';
const String _httpBase   = 'http://$_serverHost';
const String _wsBase     = 'ws://$_serverHost';
// ──────────────────────────────────────────────────────────────────────────

class ServerDetectionResult {
  final List<Detection> detections;
  final RiskZone? riskZone;
  const ServerDetectionResult({required this.detections, this.riskZone});
}

class ServerService {
  static final ServerService instance = ServerService._();
  ServerService._();

  WebSocketChannel? _channel;
  bool _connected = false;
  bool get isConnected => _connected;

  final _streamController =
      StreamController<ServerDetectionResult>.broadcast();
  Stream<ServerDetectionResult> get detectionStream => _streamController.stream;

  /// Connect WebSocket untuk Mode Tuntun/Navigasi.
  /// [lat], [lng] dikirim sebagai query param untuk Risk Zone (opsional).
  Future<void> connect({double lat = 0, double lng = 0}) async {
    try {
      final uri = Uri.parse('$_wsBase/ws/detect?lat=$lat&lng=$lng');
      _channel  = WebSocketChannel.connect(uri);
      _connected = true;

      _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          if (json['type'] == 'detections') {
            final dets = (json['detections'] as List)
                .map((e) => Detection.fromJson(e as Map<String, dynamic>))
                .toList();

            RiskZone? rz;
            if (json['risk_zone'] != null) {
              rz = RiskZone.fromJson(json['risk_zone'] as Map<String, dynamic>);
            }

            _streamController.add(
              ServerDetectionResult(detections: dets, riskZone: rz),
            );
          }
        },
        onError: (_) => _connected = false,
        onDone:  ()  => _connected = false,
      );
    } catch (_) {
      _connected = false;
      rethrow;
    }
  }

  /// Kirim JPEG frame via WebSocket (Mode Tuntun server path).
  void sendFrame(Uint8List jpegBytes) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jpegBytes);
    }
  }

  /// Single-shot detect untuk Voice Assistant (REST).
  Future<List<Detection>> detectOnce(Uint8List jpegBytes) async {
    final res = await http.post(
      Uri.parse('$_httpBase/api/detect'),
      headers: {'Content-Type': 'application/octet-stream'},
      body: jpegBytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['detections'] as List)
        .map((e) => Detection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// OCR — Mode Baca Teks.
  Future<Map<String, dynamic>> readText(Uint8List jpegBytes) async {
    final res = await http.post(
      Uri.parse('$_httpBase/api/ocr'),
      headers: {'Content-Type': 'application/octet-stream'},
      body: jpegBytes,
    );
    if (res.statusCode != 200) {
      throw Exception('OCR error ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Minta narasi natural dari Claude Haiku berdasarkan deteksi.
  Future<String> getNarasi(List<Detection> detections, {String context = 'voice'}) async {
    final body = jsonEncode({
      'detections': detections.map((d) => {
        'label_id':       d.labelId,
        'distance_meter': d.distanceMeter,
        'direction':      d.direction,
        'danger_level':   d.dangerLevel,
      }).toList(),
      'context': context,
    });
    final res = await http.post(
      Uri.parse('$_httpBase/api/narasi'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception('Narasi error ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['narasi'] as String? ?? 'Area sekitar tampak aman.';
  }

  /// Cek risk zone via REST.
  Future<RiskZone?> checkRiskZone(double lat, double lng) async {
    final res = await http.get(
      Uri.parse('$_httpBase/api/risk-zone?lat=$lat&lng=$lng'),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['risk_zone'] == null) return null;
    return RiskZone.fromJson(json['risk_zone'] as Map<String, dynamic>);
  }

  /// LLM intent routing untuk Voice Assistant.
  /// Return: 'describe_scene' | 'ocr' | 'navigation' | 'chitchat'
  /// Fallback ke 'describe_scene' jika server tidak tersedia atau timeout.
  Future<String> routeIntent(String text) async {
    try {
      final res = await http.post(
        Uri.parse('$_httpBase/api/route-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode != 200) return 'describe_scene';
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['intent'] as String? ?? 'describe_scene';
    } catch (_) {
      return 'describe_scene'; // offline atau timeout → fallback aman
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
