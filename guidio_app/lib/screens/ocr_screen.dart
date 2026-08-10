import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  bool   _scanning = false;
  bool   _speaking = false;
  bool   _failed   = false;
  String _fullText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().startStream();
    });
  }

  @override
  void dispose() {
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() { _scanning = true; _failed = false; });

    try {
      final jpeg   = await context.read<CameraProvider>().captureJpeg();
      final result = await ServerService.instance.readText(jpeg);
      _fullText = result['text'] as String? ?? '';

      if (!mounted) return;
      setState(() { _scanning = false; });

      if (_fullText.isNotEmpty) {
        setState(() => _speaking = true);
        await TTSService.instance.speak(_fullText);
        if (mounted) setState(() => _speaking = false);
      } else {
        await TTSService.instance.speak('Tidak ada teks yang terdeteksi');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _scanning = false; _failed = true; });
      await TTSService.instance.speak('Gagal membaca teks, coba lagi');
    }
  }

  Future<void> _replay() async {
    if (_fullText.isEmpty) return;
    setState(() => _speaking = true);
    await TTSService.instance.speak(_fullText);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _stopSpeaking() async {
    await TTSService.instance.stop();
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _copy() async {
    if (_fullText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _fullText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks disalin ke clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = context.watch<CameraProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;
    final hasResult = _fullText.isNotEmpty || _failed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: _cameraWithGuide(cam))
          else
            const ColoredBox(color: Colors.black),

          Positioned(
            top: topInset + AppSpacing.s2,
            left: AppSpacing.screenMargin,
            child: const ModeBadge(mode: AppMode.ocr),
          ),

          if (hasResult)
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
              child: ResultPanel(
                text: _fullText,
                speaking: _speaking,
                failed: _failed,
                onReplay: _replay,
                onTogglePlayback: _speaking ? _stopSpeaking : _replay,
                onRetry: _scan,
                secondaryLabel: _fullText.isNotEmpty ? 'Salin teks' : null,
                onSecondary: _copy,
              ),
            ),

          if (_scanning)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(onCameraPressed: _scan, cameraLabel: 'Baca teks'),
          ),
        ],
      ),
    );
  }

  Widget _cameraWithGuide(CameraProvider cam) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CameraPreview(cam.controller!)),
        Center(
          child: SizedBox(
            width: 280,
            height: 190,
            child: GuideFrame(fit: _scanning ? FrameFit.fit : FrameFit.empty),
          ),
        ),
      ],
    );
  }
}
