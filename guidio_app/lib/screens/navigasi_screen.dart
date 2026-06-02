import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../widgets/index.dart';

class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

class _NavigasiScreenState extends State<NavigasiScreen> {
  final TextEditingController _destCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mode Navigasi: YOLO tetap aktif sebagai obstacle detection
      context.read<DetectionProvider>().startRealtime();
      context.read<CameraProvider>().startStream();
    });
  }

  @override
  void dispose() {
    context.read<DetectionProvider>().stopRealtime();
    context.read<CameraProvider>().stopStream();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _startNav() async {
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) return;
    await context.read<NavigationProvider>().startNavigation(dest);
  }

  @override
  Widget build(BuildContext context) {
    final nav  = context.watch<NavigationProvider>();
    final det  = context.watch<DetectionProvider>();
    final cam  = context.watch<CameraProvider>();
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera sebagai background
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),
  
          // Nav card atau input tujuan
          Positioned(
            top: 8, left: 16, right: 16,
            child: nav.isNavigating && nav.currentStep != null
                ? _NavCard(
                    step:   nav.currentStep!,
                    onStop: () => context.read<NavigationProvider>().stopNavigation(),
                  )
                : _DestInput(
                    ctrl:      _destCtrl,
                    onStart:   _startNav,
                    favorites: nav.favorites,
                  ),
          ),
  
          // Obstacle warnings dari YOLO
          if (det.detections.isNotEmpty)
            Positioned(
              bottom: 100, left: 16, right: 16,
              child: Column(
                children: det.detections.map((d) => DetectionCard(detection: d)).toList(),
              ),
            ),
  
          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: const BottomBar(),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final NavigationStep step;
  final VoidCallback   onStop;
  const _NavCard({required this.step, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [const BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.instruction,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onStop),
        ],
      ),
    );
  }
}

class _DestInput extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback           onStart;
  final Map<String, String>    favorites;
  const _DestInput({required this.ctrl, required this.onStart, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [const BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText:   'Mau ke mana?',
                    border:     InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              ElevatedButton(onPressed: onStart, child: const Text('Mulai')),
            ],
          ),
          if (favorites.isNotEmpty) ...[
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Favorit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ...favorites.entries.map(
              (e) => ListTile(
                leading:  const Icon(Icons.star, color: Colors.amber),
                title:    Text(e.key),
                dense:    true,
                onTap: () {
                  ctrl.text = e.key;
                  onStart();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
