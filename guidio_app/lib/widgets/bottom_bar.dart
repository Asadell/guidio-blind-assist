import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/index.dart';
import 'mode_sheet.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;

  const BottomBar({super.key, this.onCameraPressed, this.onMicPressed});

  @override
  Widget build(BuildContext context) {
    final voice  = context.watch<VoiceProvider>();
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tombol kiri: kamera / scan
          _BarButton(
            icon:  Icons.camera_alt_outlined,
            onTap: onCameraPressed ?? () {},
          ),

          // Tombol tengah: mic besar biru
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final hasVib = await Vibration.hasVibrator() ?? false;
              if (hasVib) Vibration.vibrate(duration: 100);

              if (onMicPressed != null) {
                onMicPressed!();
              } else {
                final v = context.read<VoiceProvider>();
                if (v.isListening) {
                  v.stopListening();
                } else {
                  v.startListening();
                }
              }
            },
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: voice.isListening ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color:       (voice.isListening ? Colors.red : Colors.blue)
                        .withOpacity(0.4),
                    blurRadius:  16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                voice.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size:  32,
              ),
            ),
          ),

          // Tombol kanan: pilih mode
          _BarButton(
            icon:  Icons.grid_view_rounded,
            onTap: () => showModeSheet(context),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;

  const _BarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color:        Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 28, color: Colors.black87),
      ),
    );
  }
}
