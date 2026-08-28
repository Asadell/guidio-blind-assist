import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../services/server_service.dart';
import '../../widgets/tier_icon.dart' show AlertTier;

/// Satu kondisi global aktif (offline, baterai kritis, penyimpanan penuh,
/// ponsel panas). Storage dan thermal tidak punya sensor resmi yang murah di
/// Flutter - keduanya dipicu manual lewat [setStorageLow] / [setDeviceHot]
/// (mis. dari panel debug atau pengukuran kasar), sesuai bagian 2 dokumen:
/// "boleh dipalsukan" untuk hal yang bukan inti keselamatan.
class _Condition {
  final String id;
  final AlertTier tier;
  final String label;
  const _Condition(this.id, this.tier, this.label);
}

/// Hasil StatusBanner setelah kondisi digabung - bagian 5.7 & 13.
class MergedBanner {
  final AlertTier tier;
  final String message;
  final String? sub;
  final String? actionLabel;
  const MergedBanner({required this.tier, required this.message, this.sub, this.actionLabel});
}

/// GlobalConditions - penggabungan StatusBanner sesuai bagian 4 & 13.
/// Maksimum SATU banner di layar. 1 kondisi → pesan+sub. 2 kondisi →
/// digabung satu kalimat. 3+ kondisi → dua disebut, sisanya "dan N masalah
/// lain" + aksi "Lihat semua".
class GlobalConditionsProvider extends ChangeNotifier {
  bool _offline = false;
  bool _serverUnreachable = false;
  bool _cameraError = false;
  int? _batteryPercent;
  bool _storageLow = false;
  bool _deviceHot = false;

  StreamSubscription? _connSub;
  Timer? _batteryTimer;
  Timer? _serverTimer;

  bool get isOffline => _offline;

  /// Ada jaringan, tapi server tidak menjawab.
  ///
  /// Ini kasus paling umum saat demo: ponsel tersambung WiFi sementara laptop
  /// backend mati, IP-nya berubah, atau firewall menutup port. Kondisi lama
  /// hanya membaca `ConnectivityResult.none`, jadi keadaan ini **tidak pernah
  /// terdeteksi** - ModePickerSheet menampilkan semua mode sehat, lalu Cari
  /// Objek gagal saat ditekan.
  bool get isServerUnreachable => _serverUnreachable;

  /// Server tidak bisa dipakai, apa pun sebabnya.
  bool get isBackendDown => _offline || _serverUnreachable;

  bool get isCameraError => _cameraError;
  int? get batteryPercent => _batteryPercent;

  /// Ambang dokumen: <10%. Versi kode lama memakai <15% **dan** tier Critical,
  /// sehingga banner baterai bisa menyingkirkan banner kamera error - padahal
  /// kamera error jauh lebih menentukan keselamatan.
  bool get isBatteryCritical => (_batteryPercent ?? 100) < 10;
  bool get isStorageLow => _storageLow;
  bool get isDeviceHot => _deviceHot;

  Future<void> init() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      _offline = initial.contains(ConnectivityResult.none);
    } catch (_) {
      _offline = false;
    }
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nowOffline = results.contains(ConnectivityResult.none);
      if (nowOffline != _offline) {
        _offline = nowOffline;
        notifyListeners();
        unawaited(_pollServer());
      }
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _pollBattery());
    _serverTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollServer());
    await Future.wait([_pollBattery(), _pollServer()]);
  }

  /// Catat hasil pemeriksaan server yang SUDAH terbukti, tanpa menunggu
  /// giliran polling berikutnya.
  ///
  /// Polling berjalan tiap 15 detik. Itu cukup untuk mengabarkan server yang
  /// mati di tengah jalan, tapi terlalu lambat untuk satu momen: pengguna
  /// baru saja menekan "Uji koneksi", mendengar "Terhubung, waktu tempuh 40
  /// milidetik", lalu menekan "Simpan alamat". Di detik itu dia sudah punya
  /// bukti yang lebih segar daripada apa pun yang dipegang kelas ini, dan
  /// tetap harus menunggu sampai polling menyusul sebelum Cari Objek dan
  /// Deskripsi Suasana berhenti ditandai mati.
  ///
  /// Menunggu itu tidak sekadar lambat, ia membingungkan: aplikasi baru saja
  /// mengucapkan "Terhubung", lalu lembar Pilih Mode masih berkata "Tidak
  /// tersedia, butuh internet". Dua kalimat dari aplikasi yang sama, saling
  /// bertentangan, dan pengguna tunanetra tidak punya cara memutuskan mana
  /// yang benar.
  ///
  /// Hanya untuk hasil yang benar-benar diuji ke alamat yang sedang dipakai.
  /// Menebak di sini akan menyalakan mode yang sebenarnya mati.
  void markServerReachable(bool reachable) {
    if (_serverUnreachable == !reachable) return;
    _serverUnreachable = !reachable;
    notifyListeners();
  }

  /// Dipanggil CameraProvider saat kamera gagal disiapkan.
  void setCameraError(bool value) {
    if (_cameraError == value) return;
    _cameraError = value;
    notifyListeners();
  }

  Future<void> _pollServer() async {
    if (_offline) {
      if (!_serverUnreachable) {
        _serverUnreachable = true;
        notifyListeners();
      }
      return;
    }
    final health = await ServerService.instance.healthAt(
      ServerService.instance.host,
      timeout: const Duration(seconds: 3),
    );
    final unreachable = health == null;
    if (unreachable != _serverUnreachable) {
      _serverUnreachable = unreachable;
      notifyListeners();
    }
  }

  Future<void> _pollBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (level != _batteryPercent) {
        _batteryPercent = level;
        notifyListeners();
      }
    } catch (_) {
      // Platform tanpa dukungan battery_plus (mis. desktop web debug) - abaikan.
    }
  }

  void setStorageLow(bool value) {
    if (_storageLow == value) return;
    _storageLow = value;
    notifyListeners();
  }

  void setDeviceHot(bool value) {
    if (_deviceHot == value) return;
    _deviceHot = value;
    notifyListeners();
  }

  List<_Condition> get _active => [
        // Kamera bermasalah = mode utama benar-benar buta. Tidak ada kondisi
        // lain yang lebih menentukan, jadi hanya ini yang boleh Critical.
        if (_cameraError)
          const _Condition('camera', AlertTier.critical, 'Kamera bermasalah'),
        if (_offline) const _Condition('offline', AlertTier.warning, 'Tanpa internet'),
        // Dibedakan dari offline: tindakan pengguna berikutnya berbeda -
        // menyalakan data seluler, atau memeriksa server.
        if (!_offline && _serverUnreachable)
          const _Condition('server', AlertTier.info, 'Server tidak terhubung'),
        if (isBatteryCritical)
          _Condition('battery', AlertTier.warning, 'Baterai ${_batteryPercent ?? 0} persen'),
        if (_storageLow) const _Condition('storage', AlertTier.warning, 'Penyimpanan hampir penuh'),
        if (_deviceHot) const _Condition('thermal', AlertTier.warning, 'Ponsel panas'),
      ];

  /// null = tidak ada banner. Urutan penyebutan: baterai/critical dulu, baru
  /// yang lain - "sebut yang masih hidup dulu, baru yang mati" (bagian 17)
  /// diterjemahkan di layar mode masing-masing; di sini tier tertinggi yang
  /// menentukan urutan tampil.
  MergedBanner? get merged {
    final active = [..._active]..sort((a, b) => b.tier.index.compareTo(a.tier.index));
    if (active.isEmpty) return null;

    final topTier = active.first.tier;
    const subDetection = 'Deteksi rintangan tetap jalan';

    if (active.length == 1) {
      final c = active.first;
      return MergedBanner(
        tier: c.tier,
        message: c.label,
        sub: c.id == 'offline' ? subDetection : null,
      );
    }

    if (active.length == 2) {
      final msg = active.map((c) => c.label).join(', ');
      return MergedBanner(tier: topTier, message: msg, sub: subDetection);
    }

    final first2 = active.take(2).map((c) => c.label).join(', ');
    final rest = active.length - 2;
    return MergedBanner(
      tier: topTier,
      message: first2,
      sub: 'dan $rest masalah lain',
      actionLabel: 'Lihat semua',
    );
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _batteryTimer?.cancel();
    _serverTimer?.cancel();
    super.dispose();
  }
}
