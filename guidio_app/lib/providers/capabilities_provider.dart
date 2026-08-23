import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/server_service.dart';
import 'app_mode_provider.dart';

/// Kemampuan server per mode - `GET /api/capabilities`.
///
/// **Ditanyakan sebelum pengguna menekan apa pun.** Tanpa ini, satu-satunya
/// cara mengetahui sebuah mode sedang mati adalah masuk ke sana lalu gagal -
/// dan untuk pengguna yang tidak melihat layar, "masuk lalu gagal" berarti
/// beberapa detik kebingungan di tempat yang salah. Item sheet karena itu
/// sudah menyebut alasannya sejak sebelum ditekan (bagian 16: "Item nonaktif
/// menyebut alasannya sebagai bagian nilai").
///
/// Offline dan server-mati sengaja dibedakan. Keduanya menghasilkan item yang
/// tidak bisa dipakai, tapi alasannya beda dan tindakan pengguna berikutnya
/// juga beda: menyalakan data seluler, atau menunggu.
enum CapState { up, limited, down }

class ModeCapability {
  final CapState state;
  final String note;
  const ModeCapability(this.state, this.note);
}

class CapabilitiesProvider extends ChangeNotifier {
  /// null = belum pernah berhasil bertanya.
  Map<String, ModeCapability>? _modes;
  DateTime? _fetchedAt;
  bool _fetching = false;

  bool get isKnown => _modes != null;

  /// Hasil cukup lama dianggap basi. Server bisa mati kapan saja, tapi
  /// bertanya tiap kali sheet dibuka akan menambah jeda sebelum sheet tampil.
  static const _staleAfter = Duration(seconds: 45);

  bool get _isStale =>
      _fetchedAt == null || DateTime.now().difference(_fetchedAt!) > _staleAfter;

  ModeCapability? _capOf(AppMode mode) => _modes?[_key(mode)];

  /// State efektif mode ini sekarang, menggabungkan jaringan dan server.
  CapState stateOf(AppMode mode, {required bool offline}) {
    if (!mode.needsServer) return CapState.up;
    if (offline) {
      return mode.disabledWhenOffline ? CapState.down : CapState.limited;
    }
    // Belum tahu - jangan menghalangi. Menebak "mati" akan mengunci pengguna
    // dari mode yang sebenarnya sehat hanya karena satu permintaan lambat.
    return _capOf(mode)?.state ?? CapState.up;
  }

  bool isAvailable(AppMode mode, {required bool offline}) =>
      stateOf(mode, offline: offline) != CapState.down;

  /// Alasan yang dibacakan **sebagai bagian nilai item**, bukan sebagai teks
  /// terpisah yang bisa terlewat saat swipe TalkBack (bagian 16).
  String? unavailableReason(AppMode mode, {required bool offline}) {
    if (!mode.needsServer) return null;

    if (offline) {
      return mode.disabledWhenOffline
          ? 'Tidak tersedia, butuh internet'
          : 'Tanpa internet: sebagian fitur mati';
    }

    final cap = _capOf(mode);
    return switch (cap?.state) {
      CapState.down => 'Tidak tersedia, ${_lowerFirst(cap!.note)}',
      CapState.limited => cap!.note,
      _ => null,
    };
  }

  String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// Menyegarkan kalau sudah basi. Aman dipanggil tiap kali sheet dibuka:
  /// panggilan berturut-turut dalam rentang segar tidak menyentuh jaringan.
  Future<void> refreshIfStale({required bool offline}) async {
    if (offline || _fetching || !_isStale) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final res = await ServerService.instance.capabilities();
      if (res == null) {
        // Server tidak menjawab - seluruh mode yang butuh server dianggap mati.
        _modes = {
          for (final m in AppMode.values)
            if (m.needsServer)
              _key(m): const ModeCapability(CapState.down, 'server tidak menjawab'),
        };
      } else {
        _modes = _parse(res);
      }
      _fetchedAt = DateTime.now();
      notifyListeners();
    } finally {
      _fetching = false;
    }
  }

  Map<String, ModeCapability> _parse(Map<String, dynamic> res) {
    final raw = res['capabilities'];
    final out = <String, ModeCapability>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is! Map) return;
        final state = switch (value['state']) {
          'up' => CapState.up,
          'limited' => CapState.limited,
          'down' => CapState.down,
          _ => CapState.up,
        };
        out['$key'] = ModeCapability(state, value['note'] as String? ?? '');
      });
    }
    return out;
  }

  /// Nama mode versi backend. Dipisah eksplisit supaya penggantian nama di
  /// satu sisi tidak diam-diam membuat semua mode terlihat sehat.
  String _key(AppMode mode) => switch (mode) {
        AppMode.tuntun => 'detection',
        AppMode.money => 'money',
        AppMode.ocr => 'read_text',
        AppMode.navigasi => 'navigation',
        AppMode.voice => 'assistant',
        AppMode.findObject => 'find_object',
      };
}
