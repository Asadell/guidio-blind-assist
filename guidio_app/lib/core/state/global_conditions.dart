import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../widgets/tier_icon.dart' show AlertTier;

/// Satu kondisi global aktif (offline, baterai kritis, penyimpanan penuh,
/// ponsel panas). Storage dan thermal tidak punya sensor resmi yang murah di
/// Flutter — keduanya dipicu manual lewat [setStorageLow] / [setDeviceHot]
/// (mis. dari panel debug atau pengukuran kasar), sesuai bagian 2 dokumen:
/// "boleh dipalsukan" untuk hal yang bukan inti keselamatan.
class _Condition {
  final String id;
  final AlertTier tier;
  final String label;
  const _Condition(this.id, this.tier, this.label);
}

/// Hasil StatusBanner setelah kondisi digabung — bagian 5.7 & 13.
class MergedBanner {
  final AlertTier tier;
  final String message;
  final String? sub;
  final String? actionLabel;
  const MergedBanner({required this.tier, required this.message, this.sub, this.actionLabel});
}

/// GlobalConditions — penggabungan StatusBanner sesuai bagian 4 & 13.
/// Maksimum SATU banner di layar. 1 kondisi → pesan+sub. 2 kondisi →
/// digabung satu kalimat. 3+ kondisi → dua disebut, sisanya "dan N masalah
/// lain" + aksi "Lihat semua".
class GlobalConditionsProvider extends ChangeNotifier {
  bool _offline = false;
  int? _batteryPercent;
  bool _storageLow = false;
  bool _deviceHot = false;

  StreamSubscription? _connSub;
  Timer? _batteryTimer;

  bool get isOffline => _offline;
  int? get batteryPercent => _batteryPercent;
  bool get isBatteryCritical => (_batteryPercent ?? 100) < 15;
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
      }
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _pollBattery());
    await _pollBattery();
  }

  Future<void> _pollBattery() async {
    try {
      final level = await Battery().batteryLevel;
      if (level != _batteryPercent) {
        _batteryPercent = level;
        notifyListeners();
      }
    } catch (_) {
      // Platform tanpa dukungan battery_plus (mis. desktop web debug) — abaikan.
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
        if (_offline) const _Condition('offline', AlertTier.warning, 'Tanpa internet'),
        if (isBatteryCritical)
          _Condition('battery', AlertTier.critical, 'Baterai ${_batteryPercent ?? 0} persen'),
        if (_storageLow) const _Condition('storage', AlertTier.warning, 'Penyimpanan hampir penuh'),
        if (_deviceHot) const _Condition('thermal', AlertTier.warning, 'Ponsel panas'),
      ];

  /// null = tidak ada banner. Urutan penyebutan: baterai/critical dulu, baru
  /// yang lain — "sebut yang masih hidup dulu, baru yang mati" (bagian 17)
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
    super.dispose();
  }
}
