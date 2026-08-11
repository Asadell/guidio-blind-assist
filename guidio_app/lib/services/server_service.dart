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

  // ── Mode Cari Objek ─────────────────────────────────────────────────────

  /// Cari satu barang di satu frame. `found: false` dengan reason
  /// `not_in_frame` adalah kondisi NORMAL (CO-10) — aplikasi menyuruh
  /// pengguna memutar badan lalu memanggil ini lagi.
  Future<Map<String, dynamic>> cariObjek(String target, Uint8List jpegBytes) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_httpBase/api/cari-objek'))
      ..fields['target'] = target
      ..files.add(http.MultipartFile.fromBytes('file', jpegBytes, filename: 'frame.jpg'));
    final streamed = await req.send().timeout(const Duration(seconds: 12));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Cari objek error ${streamed.statusCode}');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Daftar barang yang dikenali — dipakai CO-12 untuk menawarkan
  /// barang lain saat target tidak dikenal.
  Future<List<String>> cariObjekTargets() async {
    final res = await http
        .get(Uri.parse('$_httpBase/api/cari-objek/targets'))
        .timeout(const Duration(seconds: 5));
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['targets'] as List).cast<String>();
  }

  // ── Mode Navigasi (segmentasi jalur 3 zona) ─────────────────────────────

  Future<Map<String, dynamic>> segmentasiJalur(
    Uint8List jpegBytes, {
    double lat = 0,
    double lng = 0,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_httpBase/api/navigasi'))
      ..fields['lat'] = '$lat'
      ..fields['lng'] = '$lng'
      ..files.add(http.MultipartFile.fromBytes('file', jpegBytes, filename: 'frame.jpg'));
    final streamed = await req.send().timeout(const Duration(seconds: 8));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Navigasi error ${streamed.statusCode}');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ── Kemampuan server ────────────────────────────────────────────────────

  /// Mode mana yang server-nya hidup, DITANYAKAN SEBELUM pengguna menekan
  /// tombol. Menentukan item `limited`/`disabled` di ModePickerSheet dan
  /// aktif-tidaknya tombol utama Mode Baca Teks.
  Future<Map<String, dynamic>?> capabilities() async {
    try {
      final res = await http
          .get(Uri.parse('$_httpBase/api/capabilities'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null; // offline: pemanggil menganggap semua mode server mati
    }
  }

  /// Health check + waktu tempuh — PG-08c membacakan latensinya.
  Future<Map<String, dynamic>?> health({Duration? timeout}) async {
    final sw = Stopwatch()..start();
    try {
      final res = await http
          .get(Uri.parse('$_httpBase/health'))
          .timeout(timeout ?? const Duration(seconds: 4));
      sw.stop();
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      json['round_trip_ms'] = sw.elapsedMilliseconds;
      return json;
    } catch (_) {
      return null;
    }
  }

  // ── Perintah suara ──────────────────────────────────────────────────────

  /// Resolusi perintah yang TIDAK cocok di CommandParser lokal.
  /// `resolved: false` berarti aplikasi harus menawarkan dua tebakan
  /// (AS-18 / AS-19), bukan bilang "perintah gagal".
  Future<Map<String, dynamic>?> resolveIntent(String text) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_httpBase/api/intent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Telemetri, crash, antrean offline ───────────────────────────────────

  /// Telemetri alur. Sengaja fire-and-forget: kegagalan mengirim statistik
  /// tidak boleh terasa oleh pengguna.
  Future<void> sendEvents(String deviceId, List<Map<String, dynamic>> events) async {
    try {
      await http
          .post(
            Uri.parse('$_httpBase/api/events'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'device_id': deviceId, 'events': events}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Diabaikan dengan sengaja.
    }
  }

  Future<bool> sendCrashReport(Map<String, dynamic> report) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_httpBase/api/crash-report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(report),
          )
          .timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ER-06 — mode terakhir sebelum crash, untuk dipulihkan otomatis.
  Future<String?> lastModeBeforeCrash(String deviceId) async {
    try {
      final res = await http
          .get(Uri.parse('$_httpBase/api/crash-report/last-mode?device_id=$deviceId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      return (jsonDecode(res.body) as Map<String, dynamic>)['mode'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// BT-13 — kirim ulang gambar yang tertahan saat offline.
  /// [idempotencyKey] mencegah pemrosesan dobel di server.
  Future<Map<String, dynamic>?> flushQueue({
    required String deviceId,
    required String idempotencyKey,
    required String kind,
    required Uint8List jpegBytes,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_httpBase/api/queue/flush'))
        ..fields['device_id'] = deviceId
        ..fields['idempotency_key'] = idempotencyKey
        ..fields['kind'] = kind
        ..files.add(http.MultipartFile.fromBytes('file', jpegBytes, filename: 'queued.jpg'));
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) return null;
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Kamus label & manifest model ────────────────────────────────────────

  /// Pemetaan label model → frasa Indonesia (DO-08, DO-19). Ada di server
  /// supaya perbaikan nama tidak perlu rilis ulang aplikasi.
  Future<List<Map<String, dynamic>>?> labels({String lang = 'id'}) async {
    try {
      final res = await http
          .get(Uri.parse('$_httpBase/api/labels?lang=$lang'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['labels'];
      if (list is! List) return null;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// UG-18 — emisi uang baru = update model, bukan update aplikasi.
  Future<List<Map<String, dynamic>>?> modelManifest() async {
    try {
      final res = await http
          .get(Uri.parse('$_httpBase/api/models/manifest'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['models'];
      if (list is! List) return null;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
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
