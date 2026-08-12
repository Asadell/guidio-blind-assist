import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/net/api_client.dart';
import '../models/detection.dart';
import '../models/risk_zone.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Emulator Android  : 10.0.2.2:8000
// Device fisik      : ganti lewat Pengaturan → Alamat server (PG-08).
const String kDefaultServerHost = '10.0.2.2:8000';
// ──────────────────────────────────────────────────────────────────────────

class ServerDetectionResult {
  final List<Detection> detections;
  final RiskZone? riskZone;
  const ServerDetectionResult({required this.detections, this.riskZone});
}

class ServerService {
  static final ServerService instance = ServerService._();
  ServerService._();

  /// Alamat server aktif (PG-08). Dulu ini konstanta hardcoded, jadi
  /// pengaturan "Alamat server" tersimpan ke disk tapi **tidak berpengaruh
  /// sama sekali** — aplikasi mengatakan "tersimpan" untuk perubahan yang
  /// tidak pernah terjadi. Itu pelanggaran bagian 4.1 yang sama seperti
  /// konfirmasi ganti mode palsu, hanya di tempat berbeda.
  ///
  /// Sekarang [host] adalah sumber kebenaran tunggal untuk seluruh endpoint,
  /// diisi `SettingsProvider` saat boot dan setiap kali pengguna menyimpan
  /// alamat baru.
  String _host = kDefaultServerHost;
  String get host => _host;

  /// Mengganti alamat. WebSocket yang sedang tersambung diputus supaya
  /// sambungan berikutnya memakai alamat baru — kalau tidak, mode Deteksi
  /// Objek akan tetap menempel di server lama sampai aplikasi dimatikan.
  void setHost(String value) {
    final next = value.trim();
    if (next.isEmpty || next == _host) return;
    _host = next;
    if (_connected) disconnect();
  }

  String get _wsBase => 'ws://$_host';

  /// Satu klien HTTP untuk seluruh aplikasi — koneksi dipakai ulang
  /// (keep-alive) alih-alih handshake baru tiap permintaan. Lihat
  /// [ApiClient] untuk alasan lengkapnya.
  late final ApiClient _api = ApiClient()..hostProvider = (() => _host);
  ApiClient get api => _api;

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
    final json = await _api.postBytes('/api/detect', jpegBytes);
    return (json['detections'] as List)
        .map((e) => Detection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Minta narasi natural dari Claude Haiku berdasarkan deteksi.
  Future<String> getNarasi(List<Detection> detections, {String context = 'voice'}) async {
    final json = await _api.postJson('/api/narasi', {
      'detections': detections
          .map((d) => {
                'label_id': d.labelId,
                'distance_meter': d.distanceMeter,
                'direction': d.direction,
                'danger_level': d.dangerLevel,
              })
          .toList(),
      'context': context,
    }, op: ApiOp.frame);
    return json['narasi'] as String? ?? 'Area sekitar tampak aman.';
  }

  /// Cek risk zone via REST.
  Future<RiskZone?> checkRiskZone(double lat, double lng) async {
    final json = await _api.getJson('/api/risk-zone', query: {
      'lat': '$lat',
      'lng': '$lng',
    });
    if (json['risk_zone'] == null) return null;
    return RiskZone.fromJson(json['risk_zone'] as Map<String, dynamic>);
  }

  /// LLM intent routing untuk Voice Assistant.
  /// Return: 'describe_scene' | 'ocr' | 'navigation' | 'chitchat'
  /// Fallback ke 'describe_scene' jika server tidak tersedia atau timeout.
  Future<String> routeIntent(String text) async {
    try {
      final json = await _api.postJson('/api/route-intent', {'text': text});
      return json['intent'] as String? ?? 'describe_scene';
    } catch (_) {
      return 'describe_scene'; // offline atau timeout → fallback aman
    }
  }

  // ── Mode Cari Objek ─────────────────────────────────────────────────────

  /// Cari satu barang di satu frame. `found: false` dengan reason
  /// `not_in_frame` adalah kondisi NORMAL (CO-10) — aplikasi menyuruh
  /// pengguna memutar badan lalu memanggil ini lagi.
  Future<Map<String, dynamic>> cariObjek(String target, Uint8List jpegBytes) =>
      _api.postMultipart(
        '/api/cari-objek',
        bytes: jpegBytes,
        fields: {'target': target},
        op: ApiOp.frame,
      );

  /// Daftar barang yang dikenali — dipakai CO-12 untuk menawarkan
  /// barang lain saat target tidak dikenal.
  Future<List<String>> cariObjekTargets() async {
    final json = await _api.getJson('/api/cari-objek/targets');
    return (json['targets'] as List).cast<String>();
  }

  // ── Mode Navigasi (segmentasi jalur 3 zona) ─────────────────────────────

  Future<Map<String, dynamic>> segmentasiJalur(
    Uint8List jpegBytes, {
    double lat = 0,
    double lng = 0,
  }) =>
      _api.postMultipart(
        '/api/navigasi',
        bytes: jpegBytes,
        fields: {'lat': '$lat', 'lng': '$lng'},
        op: ApiOp.frame,
      );

  // ── Kemampuan server ────────────────────────────────────────────────────

  /// Mode mana yang server-nya hidup, DITANYAKAN SEBELUM pengguna menekan
  /// tombol. Menentukan item `limited`/`disabled` di ModePickerSheet dan
  /// aktif-tidaknya tombol utama Mode Baca Teks.
  Future<Map<String, dynamic>?> capabilities() async {
    try {
      return await _api.getJson('/api/capabilities');
    } catch (_) {
      return null; // offline: pemanggil menganggap semua mode server mati
    }
  }

  /// Health check + waktu tempuh — PG-08c membacakan latensinya.
  Future<Map<String, dynamic>?> health({Duration? timeout}) =>
      healthAt(_host, timeout: timeout);

  /// Health check ke alamat tertentu **tanpa mengubah alamat aktif** — dipakai
  /// PG-08b untuk menguji kandidat sebelum disimpan. Memisahkan "menguji" dari
  /// "memakai" itulah yang membuat PG-08e mungkin: uji boleh gagal tanpa
  /// merusak sambungan yang sedang bekerja.
  Future<Map<String, dynamic>?> healthAt(String host, {Duration? timeout}) async {
    // Klien sementara dengan host tetap — tidak menyentuh alamat aktif.
    final probe = ApiClient()..hostProvider = (() => host);
    final sw = Stopwatch()..start();
    try {
      final json = await probe.getJson('/health', retries: 0);
      sw.stop();
      json['round_trip_ms'] = sw.elapsedMilliseconds;
      return json;
    } catch (_) {
      return null;
    } finally {
      probe.close();
    }
  }

  // ── Perintah suara ──────────────────────────────────────────────────────

  /// Resolusi perintah yang TIDAK cocok di CommandParser lokal.
  /// `resolved: false` berarti aplikasi harus menawarkan dua tebakan
  /// (AS-18 / AS-19), bukan bilang "perintah gagal".
  Future<Map<String, dynamic>?> resolveIntent(String text) async {
    try {
      return await _api.postJson('/api/intent', {'text': text});
    } catch (_) {
      return null;
    }
  }

  // ── Telemetri, crash, antrean offline ───────────────────────────────────

  /// Telemetri alur. Sengaja fire-and-forget: kegagalan mengirim statistik
  /// tidak boleh terasa oleh pengguna.
  Future<void> sendEvents(String deviceId, List<Map<String, dynamic>> events) async {
    try {
      await _api.postJson(
        '/api/events',
        {'device_id': deviceId, 'events': events},
        op: ApiOp.background,
      );
    } catch (_) {
      // Diabaikan dengan sengaja.
    }
  }

  Future<bool> sendCrashReport(Map<String, dynamic> report) async {
    try {
      await _api.postJson('/api/crash-report', report, op: ApiOp.background);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ER-06 — mode terakhir sebelum crash, untuk dipulihkan otomatis.
  Future<String?> lastModeBeforeCrash(String deviceId) async {
    try {
      final json = await _api.getJson(
        '/api/crash-report/last-mode',
        query: {'device_id': deviceId},
      );
      return json['mode'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// BT-13 — kirim ulang gambar yang tertahan saat offline.
  /// [idempotencyKey] mencegah pemrosesan dobel di server: unggah ulang tidak
  /// idempoten dengan sendirinya, jadi kuncinya yang membuatnya aman diulang.
  Future<Map<String, dynamic>?> flushQueue({
    required String deviceId,
    required String idempotencyKey,
    required String kind,
    required Uint8List jpegBytes,
  }) async {
    try {
      return await _api.postMultipart(
        '/api/queue/flush',
        bytes: jpegBytes,
        filename: 'queued.jpg',
        fields: {
          'device_id': deviceId,
          'idempotency_key': idempotencyKey,
          'kind': kind,
        },
        op: ApiOp.heavy,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Kamus label & manifest model ────────────────────────────────────────

  /// Pemetaan label model → frasa Indonesia (DO-08, DO-19). Ada di server
  /// supaya perbaikan nama tidak perlu rilis ulang aplikasi.
  Future<List<Map<String, dynamic>>?> labels({String lang = 'id'}) async {
    try {
      final json = await _api.getJson('/api/labels', query: {'lang': lang});
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
      final json = await _api.getJson('/api/models/manifest');
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
