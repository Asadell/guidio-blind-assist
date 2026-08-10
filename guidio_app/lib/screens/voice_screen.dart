import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../widgets/index.dart';

/// VoiceScreen — UI only, semua logic di VoiceProvider.
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();
    final cam = context.watch<CameraProvider>();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cam.isInitialized && cam.controller != null)
            Positioned.fill(child: CameraPreview(cam.controller!))
          else
            const ColoredBox(color: Colors.black),

          Positioned(
            top: topInset + AppSpacing.s2,
            left: AppSpacing.screenMargin,
            child: const ModeBadge(mode: AppMode.voice),
          ),

          // Orb — pusat perhatian utama saat idle, terselip di atas kartu saat aktif
          if (voice.state == VoiceState.idle)
            Center(
              child: VoiceOrb(
                state: voice.isListening ? VoiceOrbState.listening : VoiceOrbState.idle,
              ),
            ),

          if (voice.state != VoiceState.idle)
            Positioned(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              bottom: bottomInset + AppSizes.bottomActionBarHeight + AppSpacing.s2,
              child: _ChatBubble(voice: voice),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomActionBar(
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

/// Adaptasi ChatBubble (F12) untuk satu jawaban VoiceProvider.
class _ChatBubble extends StatelessWidget {
  final VoiceProvider voice;
  const _ChatBubble({required this.voice});

  String get _eyebrow => switch (voice.state) {
        VoiceState.listening  => 'Mendengarkan…',
        VoiceState.processing => 'Memproses…',
        VoiceState.responding => 'Vinara menjawab',
        VoiceState.idle       => '',
      };

  String get _body => switch (voice.state) {
        VoiceState.listening  => voice.lastText.isEmpty ? 'Silakan berbicara…' : voice.lastText,
        VoiceState.processing => 'Menyusun jawaban…',
        VoiceState.responding => voice.response,
        VoiceState.idle       => '',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$_eyebrow $_body',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.card,
          boxShadow: AppElevation.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (voice.state == VoiceState.processing) ...[
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.actionLabel),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                ],
                Text(_eyebrow, style: AppTypography.eyebrow(color: AppColors.actionLabel)),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(_body, style: AppTypography.body()),
          ],
        ),
      ),
    );
  }
}
