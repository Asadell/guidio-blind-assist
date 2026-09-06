import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Jembatan ke pembaca layar (TalkBack di Android, VoiceOver di iOS).
///
/// ## Kenapa lapisan ini ada
///
/// Aplikasi ini punya suaranya sendiri: `TTSService` lewat `TtsQueue`. Selama
/// TalkBack mati, itu satu-satunya suara di ponsel dan semuanya rapi.
///
/// Begitu TalkBack menyala, ada DUA mesin suara yang bicara ke telinga yang
/// sama, dan keduanya tidak saling tahu. TalkBack mengumumkan apa pun yang
/// baru mendapat fokus - judul mode, banner, tombol - sementara mesin suara
/// aplikasi sedang membacakan hasil. Yang terdengar pengguna bukan dua
/// kalimat berurutan, melainkan dua kalimat bertumpuk, dan yang kalah
/// biasanya justru kalimat yang paling dia butuhkan: hasilnya.
///
/// Aturan yang dipakai seluruh aplikasi sesudah ini:
///
/// 1. **Kalau TalkBack menyala, TalkBack yang membacakan hasil.** Mesin suara
///    aplikasi mundur untuk teks panjang yang sudah ada di layar (hasil OCR,
///    panel hasil), supaya tidak ada dua suara membaca kalimat yang sama.
/// 2. **Fokus dipindahkan, bukan diharapkan.** Saat hasil muncul, fokus
///    aksesibilitas digeser ke kartu hasilnya lewat [focusOn]. Tanpa itu
///    TalkBack menaruh fokus di mana pun yang menurutnya masuk akal -
///    biasanya komponen paling atas layar - dan pengguna mendengar "Mode
///    aktif: Baca Teks" alih-alih tulisan yang barusan dia foto.
/// 3. **Peringatan tetap milik mesin suara aplikasi.** Bahaya, kegagalan, dan
///    konfirmasi tombol tidak boleh menunggu giliran fokus TalkBack.
///
/// ## Aturan `liveRegion` di seluruh aplikasi ini
///
/// `Semantics(liveRegion: true)` menyuruh TalkBack mengucapkan sebuah node
/// setiap kali isinya berubah, tanpa diminta dan tanpa peduli apa yang sedang
/// berbunyi. Di aplikasi biasa itu tepat: tidak ada suara lain yang bisa
/// mengabarkan perubahan.
///
/// Di aplikasi ini hampir setiap perubahan SUDAH diucapkan sendiri oleh
/// modenya - kartu rintangan, kartu nominal, kartu barang ketemu, tawaran
/// lampu, indikator zona. Menandainya `liveRegion` berarti kalimat yang sama
/// dibacakan dua mesin suara sekaligus, dan yang kedua memotong yang pertama
/// di tengah kata.
///
/// Karena itu aturannya dibalik dari bawaan Flutter:
///
/// > **`liveRegion` hanya untuk yang TIDAK diucapkan mesin suara aplikasi.**
///
/// Yang tersisa memenuhi syarat itu praktis cuma `StatusBanner` - offline,
/// baterai kritis, penyimpanan penuh - yang memang tidak pernah dibacakan
/// siapa pun. Sisanya dimatikan, dan tidak ada informasi yang hilang: node
/// yang bukan live region tetap punya label, tetap bisa disapu, dan tetap
/// dibacakan begitu fokus mendarat di sana. Yang hilang cuma pemaksaannya.
class ScreenReader {
  const ScreenReader._();

  /// Apakah pembaca layar sedang menyala.
  ///
  /// `accessibleNavigation` inilah tanda yang dipakai Flutter untuk "ada
  /// layanan aksesibilitas yang mengambil alih navigasi sentuh" - persis
  /// keadaan saat sentuhan pertama memindahkan fokus alih-alih menekan.
  static bool isOn(BuildContext context) =>
      MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

  /// Geser fokus pembaca layar ke node milik [key].
  ///
  /// Dipanggil sesudah frame berikutnya digambar: pada saat hasil selesai
  /// diproses, widget-nya sering belum terpasang, dan mengirim peristiwa
  /// fokus ke render object yang belum ada tidak melakukan apa-apa dan tidak
  /// memberi galat apa pun - kegagalan paling sulit terlihat dari semuanya.
  ///
  /// Percobaan diulang beberapa kali dengan jeda pendek karena pohon semantik
  /// dibangun sedikit di belakang pohon render; percobaan pertama bisa jatuh
  /// tepat sebelum nodenya terdaftar.
  static void focusOn(GlobalKey key, {int attempts = 3}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sent = _sendFocus(key);
      if (sent || attempts <= 1) return;
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => focusOn(key, attempts: attempts - 1),
      );
    });
  }

  static bool _sendFocus(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;
    final render = ctx.findRenderObject();
    if (render == null || !render.attached) return false;
    render.sendSemanticsEvent(const FocusSemanticEvent());
    return true;
  }

  /// Suruh pembaca layar mengucapkan satu kalimat sekarang.
  ///
  /// Dipakai hanya untuk kabar yang TIDAK punya tempat tetap di layar (mis.
  /// "Hasil ditutup"). Kabar yang punya kartunya sendiri lebih baik lewat
  /// [focusOn]: kalimatnya jadi bisa diulang pengguna dengan menyapu kembali
  /// ke kartunya, sementara pengumuman lepas seperti ini hilang sesudah
  /// diucapkan sekali.
  /// [context] dipakai untuk menemukan `FlutterView` yang sedang tampil -
  /// `SemanticsService.announce` tanpa view sudah usang sejak Flutter 3.35.
  static void announce(
    BuildContext context,
    String message, {
    bool assertive = true,
  }) {
    if (message.trim().isEmpty) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(
      view,
      message,
      TextDirection.ltr,
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }
}
