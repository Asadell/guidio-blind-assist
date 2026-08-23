/// Pengawas kecepatan perangkat untuk Mode Navigasi.
///
/// Mode ini menjalankan tiga model per frame. Di ponsel baru satu siklus
/// selesai dalam ratusan milidetik; di ponsel lima tahun dengan RAM 2 GB bisa
/// berkali lipat, dan bertambah lagi saat prosesornya diturunkan sendiri
/// karena panas.
///
/// Yang berbahaya bukan lambatnya, melainkan **diamnya**. Arahan tetap
/// diucapkan dengan nada yakin dari pemandangan beberapa detik lalu, sementara
/// pengguna sudah melangkah melewatinya. Untuk orang yang tidak bisa
/// memeriksa sendiri, panduan basi yang terdengar yakin lebih berbahaya
/// daripada panduan yang mengaku tertinggal.
///
/// Urutan tindakannya sengaja dari yang paling tidak mengganggu:
///
///   1. **Ukur.** Rata-rata bergerak, bukan nilai terakhir.
///   2. **Kurangi beban sendiri.** Matikan lapis COCO diam-diam.
///   3. **Katakan apa adanya.** Hanya kalau langkah 2 pun tidak cukup.
///
/// Ditulis sebagai kelas murni tanpa Timer, tanpa TTS, dan tanpa provider,
/// supaya bisa diuji tanpa perangkat maupun model. Ini keputusan yang
/// menentukan apakah pengguna diberi tahu bahwa panduannya tertinggal, dan
/// keputusan seperti itu tidak boleh cuma dibuktikan lewat uji lapangan.
class DevicePaceWatch {
  DevicePaceWatch({
    this.dropCocoAboveMs = 1200,
    this.warnUserAboveMs = 2500,
    this.smoothing = 0.3,
  });

  /// Di atas ini, lapis COCO dimatikan sendiri.
  ///
  /// 1200 ms dipilih karena di angka itu jeda antar arahan sudah melewati satu
  /// langkah kaki penuh, sekitar 0,7 detik pada kecepatan jalan normal.
  final double dropCocoAboveMs;

  /// Di atas ini, pipeline yang sudah dikurangi pun tidak mengejar.
  final double warnUserAboveMs;

  /// Bobot nilai baru pada rata-rata bergerak.
  ///
  /// Sengaja kecil: satu frame yang kebetulan lambat karena aplikasi lain
  /// menyalip bukan alasan menurunkan kualitas panduan.
  final double smoothing;

  double _ema = 0;
  bool _cocoDropped = false;
  bool _warned = false;

  /// Rata-rata bergerak durasi siklus, dalam milidetik. 0 sebelum ada sampel.
  double get emaMs => _ema;

  /// Lapis COCO sedang dimatikan karena perangkat tidak mengejar.
  bool get cocoDropped => _cocoDropped;

  /// Pengguna sudah diberi tahu bahwa perangkat tertinggal.
  bool get warned => _warned;

  /// Catat satu siklus. Kembalikan tindakan yang perlu diambil pemanggil.
  PaceAction record(int ms) {
    if (ms < 0) return PaceAction.none;
    _ema = _ema == 0 ? ms.toDouble() : _ema * (1 - smoothing) + ms * smoothing;

    // Lapis COCO yang dikorbankan lebih dulu, bukan PIDNet atau YOLO.
    //
    // Ia satu-satunya yang menambah cakupan tanpa menopang mode ini. PIDNet
    // memberi arahan jalur dan YOLO memberi bahaya lubang serta tangga;
    // keduanya tidak punya pengganti, jadi mematikannya demi kecepatan berarti
    // menukar keterlambatan dengan kebutaan.
    if (!_cocoDropped && _ema > dropCocoAboveMs) {
      _cocoDropped = true;
      return PaceAction.dropCocoLayer;
    }

    // Sekali saja per sesi. Mengulanginya tiap frame justru memakan waktu
    // bicara yang dibutuhkan peringatan bahaya.
    if (!_warned && _ema > warnUserAboveMs) {
      _warned = true;
      return PaceAction.warnUser;
    }

    return PaceAction.none;
  }

  /// Mulai sesi baru dari nol.
  ///
  /// Ponsel yang tadi lambat karena aplikasi lain sedang berat belum tentu
  /// lambat sekarang, dan menghukumnya selamanya berarti membuang lapis COCO
  /// tanpa alasan.
  void reset() {
    _ema = 0;
    _cocoDropped = false;
    _warned = false;
  }
}

/// Tindakan yang diminta [DevicePaceWatch] dari pemanggilnya.
enum PaceAction {
  /// Kecepatan masih wajar.
  none,

  /// Matikan lapis COCO. Tidak perlu diumumkan: pengguna tidak kehilangan
  /// panduan jalur maupun peringatan lubang.
  dropCocoLayer,

  /// Beri tahu pengguna bahwa arahan bisa datang terlambat.
  warnUser,
}
