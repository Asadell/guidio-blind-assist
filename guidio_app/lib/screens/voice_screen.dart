import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../widgets/index.dart';

/// VoiceScreen — UI only, semua logic di VoiceProvider.
/// Fix dari doc 5 masalah 11: Screen hanya tampilkan state dari Provider.
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voice  = context.watch<VoiceProvider>();
    final cam    = context.watch<CameraProvider>();
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera background
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),
  
          // Mode badge
          Positioned(
            top: 12, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mode: Asisten Suara',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
  
          // Response card — muncul saat ada state apapun kecuali idle
          if (voice.state != VoiceState.idle)
            Positioned(
              left: 16, right: 16,
              top: 60,
              child: _GuidioCard(voice: voice),
            ),
  
          // Bottom bar — mic toggle
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: BottomBar(
              onMicPressed: () async {
                final v = context.read<VoiceProvider>();
                if (v.isListening) {
                  await v.stopListening();
                } else {
                  await v.startListening();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidioCard extends StatelessWidget {
  final VoiceProvider voice;
  const _GuidioCard({required this.voice});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headerText,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bodyText,
            style: const TextStyle(fontSize: 15),
          ),
          if (voice.state == VoiceState.responding) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.volume_up, size: 14, color: Colors.blueAccent),
                SizedBox(width: 4),
                Text(
                  'Sedang dibacakan...',
                  style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _headerText => switch (voice.state) {
        VoiceState.listening   => 'Mendengarkan...',
        VoiceState.processing  => 'Memproses...',
        VoiceState.responding  => 'Guidio menjawab',
        VoiceState.idle        => '',
      };

  String get _bodyText => switch (voice.state) {
        VoiceState.listening   => voice.lastText.isEmpty
            ? 'Silakan berbicara...'
            : voice.lastText,
        VoiceState.processing  => 'Sedang menganalisis...',
        VoiceState.responding  => voice.response,
        VoiceState.idle        => '',
      };
}
