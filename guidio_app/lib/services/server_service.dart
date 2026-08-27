import 'dart:typed_data';
import '../core/net/api_client.dart';

// ── Konfigurasi Server ─────────────────────────────────────────────────────
// Bawaan            : 127.0.0.1:8000 (server berjalan di perangkat yang sama)
// Emulator Android  : 10.0.2.2:8000  - alias emulator untuk localhost laptop
// Device fisik      : IP laptop di jaringan yang sama, mis. 192.168.1.5:8000
//
// Semuanya diganti lewat Pengaturan → Alamat server (PG-08), dan alamat yang
// pernah disimpan SELALU menang atas nilai bawaan ini - jadi mengubahnya di
// sini hanya berpengaruh pada pemasangan baru.
const String kDefaultServerHost = '127.0.0.1:8000';
// ──────────────────────────────────────────────────────────────────────────

/// Klien untuk **hanya** yang benar-benar butuh server.
///
/// Setelah OCR pindah ke ML Kit, uang ke TFLite, deteksi ke SSD MobileNet, dan
/// intent parsing ke `CommandParser`, yang tersisa di server tinggal yang
/// memang tidak ada di perangkat: YOLOE (Cari Objek), Moondream2 (Deskripsi
/// Suasana), dan segmentasi jalur sebagai cadangan PIDNet on-device.
///
/// Dua belas method lain - `detectOnce`, `routeIntent`, `resolveIntent`,
/// `cariObjekTargets`, `health`, `sendEvents`, `sendCrashReport`,
/// `lastModeBeforeCrash`, `flushQueue`, `labels`, `modelManifest`,
/// `checkRiskZone` - dihapus karena tidak punya satu pun pemanggil. Endpoint
/// backend-nya ikut diarsipkan.
class ServerService {
  static final ServerService instance = ServerService._();
  ServerService._();

  /// Alamat server aktif (PG-08). Dulu ini konstanta hardcoded, jadi
  /// pengaturan "Alamat server" tersimpan ke disk tapi **tidak berpengaruh
  /// sama sekali** - aplikasi mengatakan "tersimpan" untuk perubahan yang
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

  /// Satu klien HTTP untuk seluruh aplikasi - koneksi dipakai ulang
  /// (keep-alive) alih-alih handshake baru tiap permintaan. Lihat
  /// [ApiClient] untuk alasan lengkapnya.
  late final ApiClient _api = ApiClient()..hostProvider = (() => _host);
  ApiClient get api => _api;

  // ── Deteksi rintangan: TIDAK ADA jalur server ───────────────────────────
  //
  // `WS /ws/detect`, `POST /api/detect`, dan `POST /api/narasi` dihapus.
  // Deteksi rintangan sepenuhnya on-device (SSD MobileNet TFLite) dan
  // narasinya dirangkai `narration_engine.dart` - keduanya sudah ada di
  // perangkat, jadi jalur server hanya menggandakan kode di mode paling
  // kritis keselamatan sambil menambahkan ketergantungan diam-diam pada
  // laptop yang menyala.
  // ─────────────────────────────────────────────────────────────────────────

  /// Kirim satu frame ke backend YOLOE untuk mencari [target].
  ///
  /// Backend YOLOE open-vocabulary (300+ barang Bahasa Indonesia) - jauh lebih
  /// fleksibel dari on-device ONNX 80 kelas. Melempar exception saat gagal.
  ///
  /// `found: false` dengan reason `not_in_frame` adalah kondisi NORMAL (CO-10)
  /// - pengguna cukup arahkan kamera ke tempat lain lalu tekan kirim lagi.
  Future<Map<String, dynamic>> cariObjek(Uint8List jpegBytes, String target) =>
      _api.postMultipart(
        '/api/cari-objek',
        bytes: jpegBytes,
        fileField: 'file',
        filename: 'frame.jpg',
        fields: {'target': target},
        op: ApiOp.frame,
      );

  /// Daftar barang yang dikenali - dipakai CO-12 untuk menawarkan
  /// barang lain saat target tidak dikenal.
  Future<List<String>> cariObjekTargets() async {
    final json = await _api.getJson('/api/cari-objek/targets');
    return (json['targets'] as List).cast<String>();
  }

  // ── Mode Navigasi: TIDAK ADA jalur server ───────────────────────────────
  //
  // `segmentasiJalur()` yang memanggil `POST /api/navigasi` dihapus. Router
  // itu sudah tidak didaftarkan di `backend/main.py` sejak navigasi dipindah
  // on-device, dan `NavigationProvider` tidak pernah memanggilnya. Yang
  // tertinggal hanyalah method yang TERLIHAT seperti cadangan server padahal
  // ujungnya cuma 404 - dan pesan errornya akan menyalahkan jaringan untuk
  // endpoint yang memang sengaja tidak disediakan.
  // ─────────────────────────────────────────────────────────────────────────

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

  /// Health check ke alamat tertentu **tanpa mengubah alamat aktif** - dipakai
  /// PG-08b untuk menguji kandidat sebelum disimpan. Memisahkan "menguji" dari
  /// "memakai" itulah yang membuat PG-08e mungkin: uji boleh gagal tanpa
  /// merusak sambungan yang sedang bekerja.
  Future<Map<String, dynamic>?> healthAt(String host, {Duration? timeout}) async {
    // Klien sementara dengan host tetap - tidak menyentuh alamat aktif.
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
  ///
  /// Mengirim gambar JPEG ke /api/describe. Deskripsinya Bahasa Inggris
  /// (output langsung Moondream2, tanpa terjemahan); mobile membacanya via
  /// `TTSService.speakEnglish()` dengan locale 'en-US'.
  ///
  /// Balasannya dibungkus [SceneDescription] alih-alih dikembalikan sebagai
  /// String telanjang, supaya `message` dari server ikut terbawa. Server
  /// sekarang menolak foto yang tidak layak dengan instruksi konkret Bahasa
  /// Indonesia ("Terlalu gelap. Cari tempat yang lebih terang"), dan
  /// membuangnya lalu menggantinya dengan "Maaf, tidak bisa mendeskripsikan"
  /// akan menukar sesuatu yang bisa ditindaklanjuti dengan sesuatu yang
  /// tidak.
  Future<SceneDescription> describeScene(Uint8List jpegBytes) async {
    try {
      final result = await _api.postMultipart(
        '/api/describe',
        bytes: jpegBytes,
        // Backend mendeklarasikan parameternya `image`, bukan `file`
        // (`routers/describe.py`). Memakai nilai bawaan `postMultipart`
        // membuat FastAPI membalas 422 untuk SETIAP permintaan - dan
        // kegagalannya ditelan `catch` di bawah lalu dilaporkan sebagai
        // `network_error`, sehingga pengguna mendengar aplikasi menyalahkan
        // jaringan yang sebenarnya sehat.
        fileField: 'image',
        filename: 'scene.jpg',
        fields: {},
        op: ApiOp.heavy,
      );
      return SceneDescription(
        descriptionEn: result['description_en'] as String? ?? '',
        message: result['message'] as String? ?? '',
        reason: result['reason'] as String? ?? '',
      );
    } catch (_) {
      return const SceneDescription(
        descriptionEn: '',
        message: '',
        reason: 'network_error',
      );
    }
  }

  void dispose() => _api.close();
}


/// Hasil POST /api/describe.
class SceneDescription {
  /// Caption Bahasa Inggris dari Moondream2. Kosong berarti tidak ada
  /// deskripsi yang layak dibacakan.
  final String descriptionEn;

  /// Pesan Bahasa Indonesia dari server. Diisi saat gagal (instruksi
  /// perbaikan) maupun saat berhasil dengan kualitas pas-pasan (catatan
  /// ketidakpastian). Kosong berarti tidak ada yang perlu ditambahkan.
  final String message;

  /// Kode mesin penyebab kegagalan; kosong saat berhasil.
  final String reason;

  const SceneDescription({
    required this.descriptionEn,
    required this.message,
    required this.reason,
  });

  bool get hasDescription => descriptionEn.trim().isNotEmpty;
}
