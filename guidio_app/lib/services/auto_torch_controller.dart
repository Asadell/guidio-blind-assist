/// Keputusan "kapan lampu senter dinyalakan dan dimatikan sendiri".
///
/// Dipisah dari [CameraProvider] karena seluruh isinya adalah aturan waktu dan
/// ambang yang HARUS bisa diuji tanpa kamera: satu jam sesudah ditulis, tidak
/// ada cara lain memastikan lampunya tidak berkedip-kedip selain menjalankan
/// aturannya di atas urutan angka kecerahan buatan.
///
/// ## Masalah yang sebenarnya diselesaikan berkas ini
///
/// Menyalakan lampu itu mudah. Yang sulit adalah **mematikannya**, dan
/// sulitnya bukan soal kode:
///
/// > Begitu lampu menyala, frame kamera menjadi terang - dan yang membuatnya
/// > terang adalah lampu itu sendiri, bukan cahaya sekitar.
///
/// Aturan naif "kalau terang, matikan" karena itu selalu berakhir di putaran:
/// nyala -> terang -> mati -> gelap -> nyala. Untuk pengguna tunanetra
/// akibatnya bukan lampu yang berkedip - itu bahkan tidak dia lihat -
/// melainkan aplikasi yang mengumumkan "Lampu dinyalakan", "Lampu dimatikan",
/// "Lampu dinyalakan" tanpa henti, dan menutupi setiap peringatan rintangan
/// di antaranya.
///
/// Histeresis saja (ambang mati jauh di atas ambang nyala) tidak menutup
/// lubang ini. Lampu senter yang mengarah ke dinding sejarak 30 cm membuat
/// frame jauh lebih terang daripada siang hari, jadi ambang setinggi apa pun
/// tetap terlewati oleh lampu itu sendiri.
///
/// ## Jalan keluarnya: bertanya, bukan menebak
///
/// Saat frame tampak cukup terang untuk dimatikan, lampunya **dimatikan
/// sebentar tanpa suara** lalu cahaya sekitar diukur ([AutoTorchAction.probeOff]).
///
/// * Masih gelap -> lampu dinyalakan lagi, tetap tanpa suara
///   ([AutoTorchAction.revertOn]). Yang tadi terang ternyata lampunya sendiri.
/// * Sudah terang -> lampu tetap mati dan barulah diumumkan
///   ([AutoTorchAction.confirmOff]).
///
/// Ini yang membuat kalimat "Lampu dimatikan." selalu benar. Tanpa pengukuran
/// itu, aplikasi bisa mengumumkan lampu dimatikan di ruangan yang masih gelap
/// gulita - satu-satunya hal yang tidak bisa diperiksa sendiri oleh orang yang
/// tidak melihat.
///
/// Kedipannya dibatasi [_probeCooldownAwal] dan digandakan tiap pengukuran
/// yang gagal, supaya kasus terburuk (kamera menempel di permukaan terang)
/// tidak berubah jadi kedipan tiap setengah menit selamanya.
library;

/// Rata-rata luma (0..255) di bawah ini dianggap gelap.
///
/// Angkanya SAMA dengan ambang `isDark` yang sudah dipakai CameraProvider.
/// Dua ambang gelap yang berbeda di satu aplikasi berarti ada keadaan di mana
/// layar berkata "terlalu gelap" sementara lampu otomatis diam saja, dan tidak
/// ada satu pun cara bagi pengguna untuk mengerti kenapa.
const double kAutoTorchDarkLuma = 30;

/// Di atas ini frame dianggap terang. Jaraknya ke [kAutoTorchDarkLuma] adalah
/// histeresisnya - tiga kali lipat, supaya goyangan kecil kecerahan di
/// ruangan yang sama tidak pernah cukup untuk membalik keputusan.
///
/// Ia bukan bukti cahaya sekitar sudah kembali, cuma alasan untuk MENGUKUR.
/// Buktinya datang dari [AutoTorchAction.probeOff].
const double kAutoTorchBrightLuma = 90;

/// Berapa lama gelap harus bertahan sebelum lampu dinyalakan.
///
/// Dua detik, sengaja lebih pendek daripada peringatan "Terlalu gelap, ...
/// Nyalakan lampu" milik CameraProvider yang berbunyi pada detik ketiga.
/// Urutannya menentukan: kalau lampu menyala lebih dulu, frame jadi terang,
/// `isDark` jatuh ke false, dan peringatan itu membatalkan dirinya sendiri.
/// Kalau dibalik, pengguna disuruh menyalakan lampu yang semilidetik kemudian
/// menyala sendiri - nasihat yang membuatnya menebak apakah aplikasi ini tahu
/// apa yang sedang dilakukannya.
const Duration kAutoTorchOnDwell = Duration(seconds: 2);

/// Berapa lama terang harus bertahan sebelum lampu diuji untuk dimatikan.
///
/// Jauh lebih lama daripada [kAutoTorchOnDwell], dan itu disengaja. Terlambat
/// menyalakan berarti pengguna berjalan beberapa detik tanpa penerangan;
/// terlambat mematikan cuma memboroskan baterai. Yang kedua jauh lebih murah,
/// jadi keraguannya selalu dimenangkan ke arah "biarkan menyala".
const Duration kAutoTorchOffDwell = Duration(seconds: 5);

/// Frame pertama sesudah lampu dimatikan DIBUANG.
///
/// Eksposur otomatis kamera butuh waktu menyesuaikan diri. Frame yang diambil
/// tepat saat lampu padam masih memakai setelan eksposur untuk pemandangan
/// terang, jadi ia terbaca jauh lebih gelap daripada keadaan sekitar yang
/// sebenarnya - dan pengukurannya akan selalu menyimpulkan "masih gelap".
const Duration kAutoTorchProbeSettle = Duration(milliseconds: 500);

/// Panjang jendela pengukuran, dihitung sejak lampu dimatikan. Yang dipakai
/// hanya bagian sesudah [kAutoTorchProbeSettle].
const Duration kAutoTorchProbeWindow = Duration(milliseconds: 1400);

/// Jeda minimum sebelum pengukuran berikutnya, sesudah satu pengukuran gagal.
/// Digandakan tiap kegagalan berturut-turut sampai [_probeCooldownMaks].
const Duration _probeCooldownAwal = Duration(seconds: 30);
const Duration _probeCooldownMaks = Duration(minutes: 2);

/// Apa yang harus dikerjakan pemanggil pada lampu senter.
enum AutoTorchAction {
  /// Tidak ada yang berubah.
  none,

  /// Nyalakan lampu, lalu umumkan bahwa ia menyala karena gelap.
  turnOn,

  /// Matikan lampu **tanpa suara** - ini pengukuran, bukan keputusan.
  probeOff,

  /// Pengukuran menunjukkan sekitarnya masih gelap: nyalakan lagi, tetap
  /// tanpa suara. Bagi pengguna, tidak ada yang pernah terjadi.
  revertOn,

  /// Pengukuran menunjukkan cahaya sekitar sudah kembali: biarkan mati, dan
  /// barulah umumkan.
  confirmOff,
}

/// Keadaan pengendali. Dibuka ke publik supaya bisa diperiksa uji dan panel
/// debug, bukan supaya diubah dari luar.
enum AutoTorchState {
  /// Lampu tidak dipegang fitur ini. Menunggu keadaan gelap.
  idle,

  /// Lampu menyala ATAS PERINTAH fitur ini - dan cuma yang begini yang boleh
  /// dimatikannya sendiri.
  lit,

  /// Lampu sedang dimatikan sementara untuk mengukur cahaya sekitar.
  probing,

  /// Pengguna mematikan lampu dengan tangannya sendiri.
  ///
  /// Fitur ini berhenti sampai cahaya sekitar benar-benar kembali terang -
  /// bukan sampai batas waktu tertentu. Bedanya menentukan: penangguhan
  /// berbatas waktu akan menyalakan lampu lagi di ruangan gelap yang sama
  /// yang barusan pengguna matikan lampunya, dan pengguna yang harus
  /// mematikan hal yang sama dua kali menyimpulkan tombolnya tidak bekerja.
  suppressed,
}

class AutoTorchController {
  AutoTorchState _state = AutoTorchState.idle;
  AutoTorchState get state => _state;

  bool _enabled = true;
  bool get enabled => _enabled;

  DateTime? _darkSince;
  DateTime? _brightSince;

  DateTime? _probeStartedAt;
  double _probeTotal = 0;
  int _probeSamples = 0;

  DateTime? _lastProbeAt;
  Duration _probeCooldown = _probeCooldownAwal;

  /// True saat lampu sedang menyala karena fitur ini - dipakai pemanggil untuk
  /// memutuskan apakah mematikan fitur ini harus ikut mematikan lampunya.
  bool get ownsTorch => _state == AutoTorchState.lit;

  /// Umpan satu frame. [luma] rata-rata kecerahan 0..255.
  AutoTorchAction update({required double luma, required DateTime now}) {
    if (!_enabled) return AutoTorchAction.none;

    switch (_state) {
      case AutoTorchState.suppressed:
        _darkSince = null;
        _brightSince = null;
        // Syaratnya cahaya sekitar yang sungguh terang, bukan sekadar "tidak
        // gelap lagi". Ambang yang longgar di sini membuat penangguhannya
        // batal oleh satu lampu jalan yang lewat.
        if (luma >= kAutoTorchBrightLuma) _state = AutoTorchState.idle;
        return AutoTorchAction.none;

      case AutoTorchState.idle:
        _brightSince = null;
        if (luma >= kAutoTorchDarkLuma) {
          _darkSince = null;
          return AutoTorchAction.none;
        }
        _darkSince ??= now;
        if (now.difference(_darkSince!) < kAutoTorchOnDwell) {
          return AutoTorchAction.none;
        }
        _darkSince = null;
        _state = AutoTorchState.lit;
        // Berhasil menyala berarti keadaan sekitar memang berubah, bukan
        // kamera yang menempel di permukaan terang. Hukuman pengukuran yang
        // sudah terkumpul karena itu dihapus.
        _resetProbeBackoff();
        return AutoTorchAction.turnOn;

      case AutoTorchState.lit:
        _darkSince = null;
        if (luma <= kAutoTorchBrightLuma) {
          _brightSince = null;
          return AutoTorchAction.none;
        }
        _brightSince ??= now;
        if (now.difference(_brightSince!) < kAutoTorchOffDwell) {
          return AutoTorchAction.none;
        }
        // `_brightSince` sengaja TIDAK dinolkan di sini. Kalau masa tunggu
        // pengukuran belum lewat, syarat terangnya tetap terpenuhi dan
        // pengukuran berikutnya berangkat begitu jedanya habis - bukan
        // memulai hitungan lima detiknya dari awal lagi.
        if (_lastProbeAt != null &&
            now.difference(_lastProbeAt!) < _probeCooldown) {
          return AutoTorchAction.none;
        }
        _brightSince = null;
        _probeStartedAt = now;
        _probeTotal = 0;
        _probeSamples = 0;
        _state = AutoTorchState.probing;
        return AutoTorchAction.probeOff;

      case AutoTorchState.probing:
        final started = _probeStartedAt;
        if (started == null) {
          // Tidak bisa terjadi lewat jalur normal; dipulihkan alih-alih
          // dibiarkan menggantung dengan lampu mati.
          _state = AutoTorchState.lit;
          return AutoTorchAction.revertOn;
        }
        final elapsed = now.difference(started);
        if (elapsed < kAutoTorchProbeSettle) return AutoTorchAction.none;
        if (elapsed < kAutoTorchProbeWindow) {
          _probeTotal += luma;
          _probeSamples++;
          return AutoTorchAction.none;
        }

        _lastProbeAt = now;
        _probeStartedAt = null;
        final rata = _probeSamples == 0 ? luma : _probeTotal / _probeSamples;

        if (rata < kAutoTorchDarkLuma) {
          // Yang tadi terang adalah lampunya sendiri.
          _state = AutoTorchState.lit;
          _probeCooldown = _probeCooldown * 2 > _probeCooldownMaks
              ? _probeCooldownMaks
              : _probeCooldown * 2;
          return AutoTorchAction.revertOn;
        }

        _state = AutoTorchState.idle;
        _resetProbeBackoff();
        return AutoTorchAction.confirmOff;
    }
  }

  void _resetProbeBackoff() {
    _probeCooldown = _probeCooldownAwal;
    _lastProbeAt = null;
  }

  /// Nyalakan / matikan fitur (saklar di Pengaturan).
  ///
  /// Mengembalikan aksi yang harus dijalankan pemanggil. Mematikan fitur
  /// selagi lampunya menyala karena fitur ini WAJIB ikut mematikan lampunya:
  /// pengguna yang mematikannya di dalam bioskop mematikannya justru supaya
  /// lampunya padam, bukan supaya lampu yang sudah menyala dibiarkan menyala.
  AutoTorchAction setEnabled(bool value) {
    if (_enabled == value) return AutoTorchAction.none;
    _enabled = value;
    if (value) {
      _hardReset();
      return AutoTorchAction.none;
    }
    final wasHolding =
        _state == AutoTorchState.lit || _state == AutoTorchState.probing;
    _hardReset();
    return wasHolding ? AutoTorchAction.confirmOff : AutoTorchAction.none;
  }

  /// Pengguna mengubah lampu dengan tangannya sendiri.
  ///
  /// Menyalakan sendiri berarti fitur ini mundur jadi penonton: lampunya milik
  /// pengguna, dan bukan tugas fitur ini mematikan sesuatu yang tidak
  /// dinyalakannya. Mematikan sendiri berarti penangguhan penuh - lihat
  /// [AutoTorchState.suppressed].
  void onManualTorchChange(bool on) {
    _darkSince = null;
    _brightSince = null;
    _probeStartedAt = null;
    _state = on ? AutoTorchState.idle : AutoTorchState.suppressed;
  }

  /// Pengguna menolak tawaran lampu ("Lewati"). Diperlakukan sama dengan
  /// mematikan lampu sendiri.
  void onLightDeclined() => onManualTorchChange(false);

  /// Lampu tidak jadi berubah - perangkatnya menolak, atau memang tidak punya
  /// lampu sama sekali.
  ///
  /// Keadaan dikembalikan ke posisi sebelum perintah tadi supaya fitur ini
  /// tidak mengira memegang lampu yang tidak pernah menyala. Tanpa ini, satu
  /// kegagalan menyalakan akan membuatnya berhenti mencoba selamanya.
  void onTorchFailed(AutoTorchAction attempted) {
    switch (attempted) {
      case AutoTorchAction.turnOn:
      case AutoTorchAction.revertOn:
        _state = AutoTorchState.idle;
      case AutoTorchAction.probeOff:
        // Lampunya masih menyala - pengukurannya yang tidak jadi.
        _state = AutoTorchState.lit;
        _probeStartedAt = null;
        _lastProbeAt = DateTime.now();
      case AutoTorchAction.confirmOff:
      case AutoTorchAction.none:
        break;
    }
    _darkSince = null;
    _brightSince = null;
  }

  /// Aliran frame berhenti (ganti mode, memotret, aplikasi ditinggalkan).
  ///
  /// Pengukuran yang sedang berjalan HARUS dibereskan di sini. Kalau tidak,
  /// alirannya berhenti tepat di tengah pengukuran, lampu tinggal mati, dan
  /// tidak ada satu frame pun lagi yang akan datang untuk menyalakannya
  /// kembali - pengguna ditinggal di ruangan gelap oleh fitur yang ada untuk
  /// meneranginya.
  AutoTorchAction onFramesStopped() {
    _darkSince = null;
    _brightSince = null;
    if (_state != AutoTorchState.probing) return AutoTorchAction.none;
    _probeStartedAt = null;
    _state = AutoTorchState.lit;
    return AutoTorchAction.revertOn;
  }

  void _hardReset() {
    _state = AutoTorchState.idle;
    _darkSince = null;
    _brightSince = null;
    _probeStartedAt = null;
    _probeTotal = 0;
    _probeSamples = 0;
    _resetProbeBackoff();
  }
}
