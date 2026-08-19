import 'dart:typed_data';
import '../core/net/api_client.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Emulator Android  : 10.0.2.2:8000
// Device fisik      : ganti lewat Pengaturan → Alamat server (PG-08).
const String kDefaultServerHost = '10.0.2.2:8000';
// ──────────────────────────────────────────────────────────────────────────

/// Klien untuk **hanya** yang benar-benar butuh server.
///
/// Setelah OCR pindah ke ML Kit, uang ke TFLite, deteksi ke SSD MobileNet, dan
/// intent parsing ke `CommandParser`, yang tersisa di server tinggal yang
/// memang tidak ada di perangkat: YOLOE (Cari Objek), Moondream2 (Deskripsi
/// Suasana), dan segmentasi jalur sebagai cadangan PIDNet on-device.
///
/// Dua belas method lain — `detectOnce`, `routeIntent`, `resolveIntent`,
/// `cariObjekTargets`, `health`, `sendEvents`, `sendCrashReport`,
/// `lastModeBeforeCrash`, `flushQueue`, `labels`, `modelManifest`,
/// `checkRiskZone` — dihapus karena tidak punya satu pun pemanggil. Endpoint
/// backend-nya ikut diarsipkan.
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

  /// Mengganti alamat. Permintaan berikutnya langsung memakai alamat baru
  /// karena [ApiClient] membaca [_host] lewat `hostProvider`.
  void setHost(String value) {
    final next = value.trim();
    if (next.isEmpty || next == _host) return;
    _host = next;
  }

  /// Satu klien HTTP untuk seluruh aplikasi — koneksi dipakai ulang
  /// (keep-alive) alih-alih handshake baru tiap permintaan. Lihat
  /// [ApiClient] untuk alasan lengkapnya.
  late final ApiClient _api = ApiClient()..hostProvider = (() => _host);
  ApiClient get api => _api;

  // ── Deteksi rintangan: TIDAK ADA jalur server ───────────────────────────
  //
  // `WS /ws/detect`, `POST /api/detect`, dan `POST /api/narasi` dihapus.
  // Deteksi rintangan sepenuhnya on-device (SSD MobileNet TFLite) dan
  // narasinya dirangkai `narration_engine.dart` — keduanya sudah ada di
  // perangkat, jadi jalur server hanya menggandakan kode di mode paling
  // kritis keselamatan sambil menambahkan ketergantungan diam-diam pada
  // laptop yang menyala.
  // ─────────────────────────────────────────────────────────────────────────

  /// Kirim satu frame ke backend YOLOE untuk mencari [target].
  ///
  /// Backend YOLOE open-vocabulary (300+ barang Bahasa Indonesia) — jauh lebih
  /// fleksibel dari on-device ONNX 80 kelas. Melempar exception saat gagal.
  ///
  /// `found: false` dengan reason `not_in_frame` adalah kondisi NORMAL (CO-10)
  /// — pengguna cukup arahkan kamera ke tempat lain lalu tekan kirim lagi.
  Future<Map<String, dynamic>> cariObjek(Uint8List jpegBytes, String target) =>
      _api.postMultipart(
        '/api/cari-objek',
        bytes: jpegBytes,
        fileField: 'file',
        filename: 'frame.jpg',
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

  /// Scene Description via Moondream2.
  /// Mengirim gambar JPEG ke /api/describe dan mengembalikan deskripsi
  /// suasana dalam Bahasa Inggris (output langsung Moondream2, tanpa terjemahan).
  /// Mobile membacanya via TTSService.speakEnglish() dengan locale 'en-US'.
  Future<String?> describeScene(Uint8List jpegBytes) async {
    try {
      final result = await _api.postMultipart(
        '/api/describe',
        bytes: jpegBytes,
        filename: 'scene.jpg',
        fields: {},
        op: ApiOp.heavy,
      );
      return result['description_en'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _api.close();
}
