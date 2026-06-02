import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../widgets/index.dart';

class TuntunScreen extends StatefulWidget {
  const TuntunScreen({super.key});

  @override
  State<TuntunScreen> createState() => _TuntunScreenState();
}

class _TuntunScreenState extends State<TuntunScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionProvider>().startRealtime();
      context.read<CameraProvider>().startStream();
    });
  }

  @override
  void dispose() {
    context.read<DetectionProvider>().stopRealtime();
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam   = context.watch<CameraProvider>();
    final det   = context.watch<DetectionProvider>();
    final top   = MediaQuery.of(context).padding.top;
    final dets  = det.detections;
    final rz    = det.riskZone;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Kamera fullscreen
        if (cam.isInitialized && cam.controller != null)
          Positioned.fill(
            child: CameraPreview(cam.controller!),
          )
        else
          const ColoredBox(color: Colors.black),

        // Mode badge
        Positioned(
          top: top + 12, left: 16,
          child: _badge('Mode: Deteksi Objek'),
        ),

        // Camera health banner
        if (cam.healthMessage != null)
          Positioned(
            top: top + 52, left: 16, right: 16,
            child: CameraHealthBanner(message: cam.healthMessage!),
          ),

        // Risk zone warning
        if (rz != null)
          Positioned(
            top: top + 52 + (cam.healthMessage != null ? 48 : 0),
            left: 16, right: 16,
            child: CameraHealthBanner(
              message: rz.warning,
              color: Colors.red.shade700,
            ),
          ),

        // Detection cards — maks 2 (sudah difilter oleh DetectionFilter)
        if (dets.isNotEmpty)
          Positioned(
            bottom: 100, left: 16, right: 16,
            child: Column(
              children: dets.map((d) => DetectionCard(detection: d)).toList(),
            ),
          ),

        // Bottom bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: const BottomBar(),
        ),
      ],
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
}
