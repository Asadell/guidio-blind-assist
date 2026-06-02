import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  bool         _scanning  = false;
  bool         _hasResult = false;
  String       _fullText  = '';
  List<String> _lines     = [];

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
    setState(() { _scanning = true; _hasResult = false; });

    try {
      final jpeg   = await context.read<CameraProvider>().captureJpeg();
      final result = await ServerService.instance.readText(jpeg);

      _fullText = result['text'] as String? ?? '';
      _lines    = List<String>.from(result['lines'] as List? ?? []);

      setState(() { _hasResult = true; });

      if (_fullText.isNotEmpty) {
        await TTSService.instance.speak(_fullText);
      } else {
        await TTSService.instance.speak('Tidak ada teks yang terdeteksi');
      }
    } catch (e) {
      await TTSService.instance.speak('Gagal membaca teks, coba lagi');
    } finally {
      setState(() { _scanning = false; });
    }
  }

  Future<void> _repeat() async {
    if (_fullText.isEmpty) return;
    await TTSService.instance.speak(_fullText);
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
    final cam    = context.watch<CameraProvider>();
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera fullscreen
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: _cameraWithOverlay(cam))
          else
            const ColoredBox(color: Colors.black),
  
          // Mode badge
          Positioned(
            top: 12, left: 16,
            child: _badge(),
          ),
  
          // Hasil OCR card dari bawah
          if (_hasResult)
            Positioned(
              left: 0, right: 0, bottom: 90,
              child: _ResultCard(
                lines:    _lines,
                onRepeat: _repeat,
                onCopy:   _copy,
              ),
            ),
  
          // Loading indicator
          if (_scanning)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
  
          // Bottom bar — tombol kamera = scan
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: BottomBar(onCameraPressed: _scan),
          ),
        ],
      ),
    );
  }

  Widget _cameraWithOverlay(CameraProvider cam) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CameraPreview(cam.controller!)),
        // Kotak scan di tengah layar
        Center(
          child: Container(
            width: 280, height: 120,
            decoration: BoxDecoration(
              border:       Border.all(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 140),
            child: Text(
              'Arahkan ke teks lalu tekan tombol kamera',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Mode: Baca Teks',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onRepeat;
  final VoidCallback onCopy;
  const _ResultCard({required this.lines, required this.onRepeat, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    [const BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HASIL BACAAN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...lines.take(4).map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line, style: const TextStyle(fontSize: 15)),
              )),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.volume_up, size: 14, color: Colors.blueAccent),
              SizedBox(width: 4),
              Text('Sedang dibacakan...', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRepeat,
                  child: const Text('Ulangi'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onCopy,
                  child: const Text('Salin Teks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
