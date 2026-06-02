import '../models/risk_zone.dart';
import 'server_service.dart';

/// Wrapper lokal untuk Risk Zone — simpan warning terakhir di memory.
class RiskZoneLocalService {
  static final RiskZoneLocalService instance = RiskZoneLocalService._();
  RiskZoneLocalService._();

  RiskZone? _currentWarning;
  RiskZone? get currentWarning => _currentWarning;

  Future<void> checkAndUpdate(double lat, double lng) async {
    try {
      _currentWarning = await ServerService.instance.checkRiskZone(lat, lng);
    } catch (_) {
      // Gagal check = tidak ada warning, bukan crash
      _currentWarning = null;
    }
  }

  void clearWarning() => _currentWarning = null;
}
