import 'package:flutter/material.dart';

import '../core/speech/tts_queue.dart';
import '../providers/camera_provider.dart';
import 'contextual_action_slot.dart';

/// Slot lampu senter - satu implementasi untuk semua mode yang memakainya.
///
/// ## Kapan ia muncul
///
/// Saat sekitar **gelap**, ATAU saat lampunya **sedang menyala**. Syarat kedua
/// itu yang membuatnya bisa dipercaya: tanpa itu, menyalakan lampu akan
/// membuat sekitarnya terang, `isDark` berubah false, dan tombol untuk
/// mematikannya lenyap - lampu menyala tanpa satu pun cara mematikannya
/// selain perintah suara.
///
/// ## Di mode mana
///
/// Mode yang kegagalannya benar-benar ditentukan cahaya: **Deteksi Objek,
/// Baca Teks, Kenali Uang, Cari Objek.** Di sana gelap bukan membuat hasilnya
/// kurang bagus, melainkan membuat fiturnya tidak menghasilkan apa-apa - label
/// obat yang tidak terbaca, nominal yang tidak terkenali, barang yang tidak
/// terlihat.
///
/// Mode Navigasi dan Deskripsi Sekitar sengaja tidak memakainya. Keduanya
/// dipakai sambil berjalan, dan satu slot tambahan di atas bar menggeser
/// kartu peringatan yang justru paling perlu terbaca cepat di sana. Lampu di
/// dua mode itu tetap bisa diatur lewat perintah suara, yang berlaku di
/// keenam mode tanpa kecuali.
///
/// ## Kenapa satu widget, bukan disalin empat kali
///
/// Isi slot ini bukan tombol biasa: ia mengucapkan hasil, dan hasil itu harus
/// jujur. Empat salinan berarti empat peluang salah satunya mengucapkan
/// "Lampu dinyalakan." untuk lampu yang tetap padam - dan pengguna tunanetra
/// tidak punya cara memeriksanya sendiri.
class TorchSlot extends StatelessWidget {
  final CameraProvider cam;

  /// Kalimat yang menyusul saat pengguna memilih "Lewati", menjelaskan bahwa
  /// modenya tetap berjalan. Isinya beda tiap mode karena yang "tetap
  /// berjalan" memang beda.
  final String dismissMessage;

  const TorchSlot({
    super.key,
    required this.cam,
    required this.dismissMessage,
  });

  /// Apakah slot ini perlu digambar sama sekali.
  ///
  /// Dipakai layar untuk dua hal sekaligus: memutuskan menggambar slotnya, dan
  /// menggeser kontennya ke atas sebanyak [slotHeight]. Keduanya WAJIB memakai
  /// nilai yang sama - kartu hasil yang tertutup slot sama saja dengan tidak
  /// ada.
  static bool visible(CameraProvider cam, {required bool hasCameraPermission}) =>
      hasCameraPermission && (cam.isTorchOn || (cam.isDark && !cam.darkDismissed));

  /// Tinggi yang dipesan slot ini. Selalu versi bermessage, karena slot ini
  /// selalu punya baris keterangan di atas tombolnya.
  static const double slotHeight = ContextualActionSlot.slotHeightWithMsg;

  /// Ubah senter, lalu katakan apa yang BENAR-BENAR terjadi.
  ///
  /// `setTorch` mengembalikan false kalau lampunya tidak jadi berubah - kamera
  /// belum siap, atau perangkatnya menolak. Mengucapkan konfirmasi tanpa
  /// memeriksa nilai itu berarti memberi pengguna satu-satunya informasi yang
  /// dia punya tentang keadaan sekitarnya, dan isinya salah.
  static Future<void> apply(CameraProvider cam, bool on) async {
    final changed = await cam.setTorch(on);
    TtsQueue().speak(
      changed
          ? (on ? 'Lampu dinyalakan.' : 'Lampu dimatikan.')
          : (on
              ? 'Lampu tidak bisa dinyalakan sekarang.'
              : 'Lampu tidak bisa dimatikan sekarang.'),
      tier: SpeechTier.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final on = cam.isTorchOn;
    return ContextualActionSlot(
      message: on ? 'Lampu senter menyala' : 'Sekitar gelap - perlu nyalakan lampu?',
      primaryLabel: on ? 'Matikan Lampu' : 'Nyalakan Lampu',
      primaryIcon: on ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
      onPrimary: () => apply(cam, !on),
      // "Lewati" berarti dua hal yang berbeda tergantung keadaan, dan itu
      // disengaja: saat lampu menyala ia jalan keluar tercepat untuk
      // mematikannya, saat lampu mati ia menolak tawarannya.
      secondaryLabel: on ? 'Matikan' : 'Lewati',
      secondaryIcon: on ? Icons.flashlight_off_rounded : Icons.close_rounded,
      onSecondary: () {
        if (on) {
          apply(cam, false);
          return;
        }
        cam.dismissDarkOffer();
        TtsQueue().speak(dismissMessage, tier: SpeechTier.info);
      },
    );
  }
}
