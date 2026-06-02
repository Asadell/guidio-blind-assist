import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

/// NavigationProvider — placeholder tanpa GPS/Google Maps.
/// GPS + Directions API akan diimplementasikan di sprint berikutnya.
class NavigationStep {
  final String instruction;
  final int    distanceM;
  const NavigationStep({required this.instruction, required this.distanceM});
}

class NavigationProvider extends ChangeNotifier {
  bool              _navigating  = false;
  String?           _destination;
  List<NavigationStep> _steps    = [];
  int               _currentIdx  = 0;
  final Map<String, String> _favorites = {};

  bool                get isNavigating  => _navigating;
  String?             get destination   => _destination;
  NavigationStep?     get currentStep   =>
      (_navigating && _steps.isNotEmpty && _currentIdx < _steps.length)
          ? _steps[_currentIdx]
          : null;
  Map<String, String> get favorites     => Map.unmodifiable(_favorites);

  Future<void> startNavigation(String dest) async {
    _destination = dest;
    _currentIdx  = 0;
    _navigating  = true;
    // Placeholder step — GPS/Directions API menyusul
    _steps = [
      NavigationStep(
        instruction: 'Navigasi ke $dest belum tersedia. GPS akan ditambahkan.',
        distanceM:   0,
      ),
    ];
    notifyListeners();
    await TTSService.instance.speak(
      'Mode navigasi aktif. Tujuan: $dest. Fitur navigasi GPS segera hadir.',
    );
  }

  void stopNavigation() {
    _navigating  = false;
    _destination = null;
    _steps       = [];
    _currentIdx  = 0;
    notifyListeners();
  }

  void saveFavorite(String name, String destination) {
    _favorites[name] = destination;
    notifyListeners();
  }
}
