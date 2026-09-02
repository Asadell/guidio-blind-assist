/// Jejak jalur perintah suara, dari bunyi sampai handler yang dijalankan.
///
/// KENAPA ADA
/// ---------
/// Bug "di Mode Cari Objek saya bilang 'carikan gitar saya', tapi aplikasi
/// malah masuk Deskripsi Suasana" tidak bisa dibaca dari log mana pun. Log
/// perangkat penuh dengan baris kamera, TTS, dan ML Kit, tapi tidak satu pun
/// mencatat DUA hal yang menentukan:
///
///   1. Teks apa yang sebenarnya keluar dari pengenal suara.
///   2. Intent apa yang dipilih `CommandParser` dari teks itu.
///
/// Tanpa keduanya, satu-satunya cara menebak penyebabnya adalah membaca ulang
/// seluruh bank frasa dengan mata. Untuk aplikasi yang perintahnya masuk lewat
/// suara - kanal yang paling mudah meleset dan paling tidak bisa diulang
/// persis - itu bukan kekurangan kecil.
///
/// SATU TANDA UNTUK SEMUA
/// ----------------------
/// Semua baris memakai awalan `[VOICE]` supaya satu perintah cukup:
///
///     flutter run | grep '\[VOICE\]'
///     adb logcat | grep '\[VOICE\]'
///
/// Baris yang diawali `!!` menandai kejanggalan yang layak dicurigai lebih
/// dulu saat membaca log, bukan sekadar catatan langkah.
///
/// HANYA DI DEBUG
/// --------------
/// [enabled] mengikuti [kDebugMode]. Isi baris ini memuat ucapan pengguna apa
/// adanya, dan ucapan itu bisa mengandung apa saja - nama orang, alamat, isi
/// percakapan yang kebetulan tertangkap mikrofon. Itu tidak pantas mengalir ke
/// logcat perangkat pengguna sungguhan hanya karena berguna saat pengembangan.
library;

import 'package:flutter/foundation.dart';

class VoiceLog {
  VoiceLog._();

  static const String _tag = '[VOICE]';

  /// Bisa dimatikan/dinyalakan dari test. Di rilis selalu mati.
  static bool enabled = kDebugMode;

  /// Peristiwa siklus hidup satu sesi STT (mulai, selesai, galat).
  static void stt(int epoch, String owner, String message) =>
      _write('stt#$epoch $owner $message');

  /// Teks yang keluar dari pengenal suara.
  ///
  /// Hasil parsial ikut dicatat, tapi hanya saat teksnya BERUBAH - lihat
  /// pemanggilnya. Mesin pengenal memancarkan parsial berkali-kali per detik
  /// dengan isi yang sama, dan mencatat semuanya membuat baris yang penting
  /// tenggelam di antara ratusan baris kembar.
  static void heard(
    int epoch,
    String owner,
    String text, {
    required bool isFinal,
  }) =>
      _write('stt#$epoch $owner ${isFinal ? "FINAL" : "parsial"} "$text"');

  /// Keputusan router: teks apa jadi intent apa, saat mode apa.
  static void route(String message) => _write('route $message');

  /// Kejanggalan yang perlu dicurigai duluan saat membaca log.
  static void warn(String message) => _write('!! $message');

  static void _write(String message) {
    if (!enabled) return;
    debugPrint('$_tag $message');
  }
}

/// Pemilik sesi `SpeechToText` yang sedang berjalan.
///
/// KENAPA STATIS, BUKAN PER-OBJEK
/// ------------------------------
/// `SpeechToText()` di paket `speech_to_text` adalah **singleton**:
///
///     // speech_to_text.dart
///     static final SpeechToText _instance = SpeechToText.withMethodChannel();
///     factory SpeechToText() => _instance;
///
/// Aplikasi ini memanggilnya di dua tempat - `VoiceProvider` (tombol bicara di
/// tengah) dan `FindObjectScreen` (tombol "Sebutkan barang"). Keduanya menyangka
/// memegang sesi sendiri, padahal keduanya memegang objek yang SAMA. Dan
/// `listen()` menimpa `_resultListener` tanpa syarat apa pun, jadi pemanggil
/// terakhir memiliki hasilnya - termasuk hasil dari ucapan yang ditujukan ke
/// tombol milik pemanggil sebelumnya.
///
/// Penghitung statis di sini sengaja meniru kenyataan itu: satu sesi global,
/// satu pemilik pada satu waktu. Sesi yang hasilnya datang dengan nomor lawas
/// berarti ucapannya nyasar ke pemilik yang salah, dan [claim] mencatatnya
/// dengan jelas.
///
/// Kelas ini TIDAK mengubah perilaku apa pun - ia hanya mencatat. Menjatuhkan
/// hasil yang nyasar adalah perbaikan tersendiri, dan perbaikan tidak boleh
/// menyelinap masuk lewat berkas yang tugasnya mendiagnosis.
class SttSession {
  SttSession._();

  static int _epoch = 0;
  static String _owner = '-';

  /// Nomor sesi yang sedang berjalan.
  static int get epoch => _epoch;

  /// Nama pemilik sesi yang sedang berjalan.
  static String get owner => _owner;

  /// Tandai sesi baru dimulai. Nilai kembaliannya disimpan pemanggil, lalu
  /// disertakan setiap kali ia menerima hasil.
  static int begin(String owner, {String? detail}) {
    _epoch++;
    _owner = owner;
    VoiceLog.stt(_epoch, owner, 'listen mulai${detail == null ? '' : ' ($detail)'}');
    return _epoch;
  }

  static void end(int epoch, String owner, String how) =>
      VoiceLog.stt(epoch, owner, 'sesi ditutup ($how)');

  /// Apakah [epoch] masih sesi yang sedang berjalan.
  static bool isCurrent(int epoch) => epoch == _epoch;

  /// Periksa kepemilikan hasil, dan catat kalau nyasar.
  ///
  /// Mengembalikan false untuk hasil dari sesi lawas. Pemanggil boleh
  /// mengabaikan nilai itu - yang penting kejadiannya tercatat, karena inilah
  /// tanda tangan bug "ucapan untuk satu tombol dijalankan tombol lain".
  static bool claim(int epoch, String owner) {
    if (isCurrent(epoch)) return true;
    VoiceLog.warn(
      'hasil stt#$epoch milik "$owner" datang saat sesi aktif stt#$_epoch '
      'milik "$_owner" - satu SpeechToText dipakai dua pemilik, ucapan nyasar',
    );
    return false;
  }

  /// Kembalikan ke keadaan awal. HANYA untuk test.
  @visibleForTesting
  static void resetForTest() {
    _epoch = 0;
    _owner = '-';
  }
}
