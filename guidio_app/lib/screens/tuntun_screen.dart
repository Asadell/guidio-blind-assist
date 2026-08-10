import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/index.dart';
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
    final cam = context.watch<CameraProvider>();
    final det = context.watch<DetectionProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;
    final dets = det.detections;
    final rz = det.riskZone;

    final banner = rz != null
        ? StatusBanner(tier: AlertTier.critical, message: rz.warning)
        : cam.healthMessage != null
            ? StatusBanner(tier: AlertTier.warning, message: cam.healthMessage!)
            : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // z0 — kamera adalah lantai, full bleed
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          // z70 — StatusBanner, kondisional, di atas segalanya kecuali sheet
          if (banner != null)
            Positioned(top: topInset, left: 0, right: 0, child: banner),

          // z25 — ModeBadge band
          Positioned(
            top: topInset + (banner != null ? AppSizes.statusBannerHeight : 0) + AppSpacing.s2,
            left: AppSpacing.screenMargin,
            child: const ModeBadge(mode: AppMode.tuntun),
          ),

          // z40 — tumpukan AlertCard, maks 2, menempel ke atas BottomActionBar
          if (dets.isNotEmpty)
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
              child: AlertCardStack(
                cards: dets.map((d) => DetectionCard(detection: d)).toList(),
              ),
            ),

          // z60 — BottomActionBar, selalu ada, selalu di tempat yang sama
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomActionBar()),
        ],
      ),
    );
  }
}
