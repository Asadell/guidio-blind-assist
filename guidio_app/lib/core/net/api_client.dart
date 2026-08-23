import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Kelas timeout per jenis operasi. Satu angka timeout untuk semua endpoint
/// selalu salah di salah satu sisi: terlalu pendek untuk OCR, terlalu panjang
/// untuk health check yang seharusnya gagal cepat.
enum ApiOp {
  /// Health, capabilities, intent - pengguna menunggu jawabannya sekarang.
  interactive(Duration(seconds: 4)),

  /// Satu frame ke server dan kembali - segmentasi jalur, cari objek.
  frame(Duration(seconds: 8)),

  /// OCR, unggah antrean - berat, pengguna sudah diberi tahu akan lama.
  heavy(Duration(seconds: 20)),

  /// Telemetri - tidak ada yang menunggu.
  background(Duration(seconds: 5));

  final Duration timeout;
  const ApiOp(this.timeout);
}

/// Dilempar saat server menjawab dengan status non-200. Dipisah dari kegagalan
/// jaringan supaya pemanggil bisa membedakan "server hidup tapi menolak" dari
/// "server tidak terjangkau" - dua kondisi itu punya naskah suara berbeda
/// (BT-14 "bukan karena gambarmu" vs ER-03 "server tidak bisa dihubungi").
class ApiStatusException implements Exception {
  final int statusCode;
  final String path;
  final String? body;
  const ApiStatusException(this.statusCode, this.path, [this.body]);

  @override
  String toString() => 'ApiStatusException($statusCode, $path)';
}

/// Dilempar saat jaringan tidak terjangkau atau melewati timeout.
class ApiUnreachableException implements Exception {
  final String path;
  final Object? cause;
  const ApiUnreachableException(this.path, [this.cause]);

  @override
  String toString() => 'ApiUnreachableException($path, $cause)';
}

/// Klien HTTP bersama untuk seluruh aplikasi.
///
/// **Kenapa satu klien, bukan `http.post()` lepasan.** Fungsi tingkat atas
/// `http.post()` membuat `Client` baru tiap panggilan lalu menutupnya. Artinya
/// tiap permintaan membayar handshake TCP baru - di jaringan seluler itu
/// ratusan milidetik yang terbuang, tiap frame, tiap kali. Satu `Client` yang
/// hidup selama aplikasi berjalan memakai ulang koneksi (keep-alive), dan itu
/// penghematan latensi terbesar yang bisa didapat tanpa mengubah apa pun di
/// server.
///
/// Selain itu klien ini memusatkan empat hal yang kalau ditulis ulang per
/// endpoint pasti tidak konsisten: timeout per jenis operasi, percobaan ulang
/// dengan backoff **hanya untuk operasi idempoten**, kunci idempotensi untuk
/// yang tidak, dan pembedaan error jaringan vs error server.
class ApiClient {
  ApiClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final _rand = Random();

  /// Dipanggil sebelum tiap permintaan untuk mendapat host aktif. Dibuat
  /// sebagai callback, bukan field, supaya perubahan alamat server (PG-08)
  /// langsung berlaku pada permintaan berikutnya tanpa membangun ulang klien.
  late String Function() hostProvider;

  String get _base => 'http://${hostProvider()}';

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  // ── GET / POST JSON ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    ApiOp op = ApiOp.interactive,
    int retries = 2,
  }) async {
    final res = await _send(
      () => _inner.get(_uri(path, query)),
      path: path,
      op: op,
      // GET selalu idempoten - aman diulang.
      retries: retries,
    );
    return _decode(res, path);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    ApiOp op = ApiOp.interactive,
    int retries = 0,
  }) async {
    final res = await _send(
      () => _inner.post(
        _uri(path),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
      path: path,
      op: op,
      retries: retries,
    );
    return _decode(res, path);
  }

  // ── Unggah gambar ───────────────────────────────────────────────────────

  /// Unggah JPEG mentah sebagai `application/octet-stream`.
  ///
  /// Dipakai untuk endpoint yang hanya butuh gambar tanpa metadata. Lebih
  /// murah daripada multipart: tanpa boundary, tanpa header per bagian.
  ///
  /// **Gambarnya harus sudah diperkecil sebelum sampai di sini.** Lihat
  /// `FrameCodec.encodeForUpload` - memperkecil di sisi klien adalah satu
  /// keputusan yang paling menentukan waktu unggah, jauh di atas pilihan
  /// protokol apa pun.
  Future<Map<String, dynamic>> postBytes(
    String path,
    Uint8List bytes, {
    ApiOp op = ApiOp.frame,
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
  }) async {
    final res = await _send(
      () => _inner.post(
        _uri(path),
        headers: {'Content-Type': contentType, ...?headers},
        body: bytes,
      ),
      path: path,
      op: op,
      // Unggah gambar tidak idempoten kecuali diberi kunci - jangan diulang
      // diam-diam. Pengulangan yang benar lewat antrean (BT-13).
      retries: 0,
    );
    return _decode(res, path);
  }

  /// Unggah multipart - gambar + field. Dipakai saat server butuh metadata
  /// menyertai gambar (target pencarian, koordinat, kunci idempotensi).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List bytes,
    String fileField = 'file',
    String filename = 'frame.jpg',
    Map<String, String> fields = const {},
    ApiOp op = ApiOp.frame,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));

    try {
      final streamed = await _inner.send(req).timeout(op.timeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw ApiStatusException(streamed.statusCode, path, body);
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } on ApiStatusException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiUnreachableException(path, e);
    } catch (e) {
      throw ApiUnreachableException(path, e);
    }
  }

  // ── Inti pengiriman ─────────────────────────────────────────────────────

  /// Backoff eksponensial **dengan jitter**. Jitter penting: tanpa itu, semua
  /// klien yang gagal pada detik yang sama akan mencoba lagi pada detik yang
  /// sama juga, dan server yang baru pulih langsung dijatuhkan lagi.
  Duration _backoff(int attempt) {
    final base = 200 * (1 << attempt); // 200, 400, 800 ms
    final jitter = _rand.nextInt(120);
    return Duration(milliseconds: base + jitter);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() run, {
    required String path,
    required ApiOp op,
    required int retries,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) await Future.delayed(_backoff(attempt - 1));
      try {
        final res = await run().timeout(op.timeout);

        // 5xx layak diulang (server sedang pulih); 4xx tidak - permintaannya
        // sendiri yang salah, mengulang hanya membuang waktu pengguna.
        if (res.statusCode >= 500 && attempt < retries) {
          lastError = ApiStatusException(res.statusCode, path);
          continue;
        }
        if (res.statusCode != 200) {
          throw ApiStatusException(res.statusCode, path, res.body);
        }
        return res;
      } on ApiStatusException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt >= retries) break;
      }
    }
    throw ApiUnreachableException(path, lastError);
  }

  Map<String, dynamic> _decode(http.Response res, String path) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiStatusException(res.statusCode, path, res.body);
    }
  }

  void close() => _inner.close();
}

/// Pengatur laju frame untuk mode yang mengalirkan gambar terus-menerus
/// (Navigasi, Cari Objek).
///
/// **Aturan: frame terbaru menang, frame lama dibuang.** Kalau server lambat,
/// mengantrekan frame justru berbahaya - pengguna akan mendengar arahan untuk
/// pemandangan yang sudah lewat beberapa detik lalu, sementara ia sudah
/// berjalan maju. Untuk aplikasi yang menuntun orang berjalan, arahan basi
/// lebih buruk daripada tidak ada arahan.
///
/// Karena itu kelas ini menjaga **paling banyak satu permintaan in-flight**.
/// Frame yang datang saat masih ada yang berjalan langsung dibuang, bukan
/// diantre. Ditambah [minInterval] sebagai batas bawah supaya kamera 30 fps
/// tidak membanjiri server yang sanggup melayani 3 fps.
class FramePacer {
  FramePacer({this.minInterval = const Duration(milliseconds: 350)});

  final Duration minInterval;
  bool _inFlight = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  int _dropped = 0;

  /// Berapa frame dibuang sejak terakhir dibaca - berguna untuk menurunkan
  /// laju kamera saat server konsisten tidak mengejar (NV-13, NV-24).
  int takeDroppedCount() {
    final n = _dropped;
    _dropped = 0;
    return n;
  }

  bool get isBusy => _inFlight;

  /// Menjalankan [task] kalau slot kosong dan jeda minimum sudah lewat.
  /// Mengembalikan null kalau frame dibuang.
  Future<T?> run<T>(Future<T> Function() task) async {
    final now = DateTime.now();
    if (_inFlight || now.difference(_lastSent) < minInterval) {
      _dropped++;
      return null;
    }
    _inFlight = true;
    _lastSent = now;
    try {
      return await task();
    } finally {
      _inFlight = false;
    }
  }

  void reset() {
    _inFlight = false;
    _dropped = 0;
    _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Kunci idempotensi untuk operasi yang **tidak** aman diulang begitu saja
/// (unggah antrean BT-13). Server memakai kunci ini untuk mengenali kiriman
/// ulang dan tidak memproses dua kali.
String newIdempotencyKey() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final salt = Random().nextInt(1 << 32);
  return '$now-${salt.toRadixString(16)}';
}

@visibleForTesting
ApiClient debugApiClient(http.Client inner) => ApiClient(inner: inner);
