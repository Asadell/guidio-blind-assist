import 'package:flutter/material.dart';

import '../theme/index.dart';

/// ChatBubble (5.12) - Mode Asisten Suara. Giliran dipisah garis, bukan
/// gelembung berwarna. Live region polite, MergeSemantics per giliran.
enum ChatSpeaker { user, vinara }

class ChatBubble extends StatelessWidget {
  final ChatSpeaker speaker;
  final String text;
  /// Giliran terbaru mendapat live region - bagian 12 "AS-12: hanya giliran
  /// terbaru dibacakan".
  final bool isLatest;

  const ChatBubble({super.key, required this.speaker, required this.text, this.isLatest = false});

  String get _speakerLabel => speaker == ChatSpeaker.user ? 'Kamu' : 'Vinara';
  Color get _speakerColor => speaker == ChatSpeaker.user ? AppColors.ink2 : AppColors.actionLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isLatest,
      child: MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_speakerLabel,
                  style: AppTypography.label(color: _speakerColor).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(text, style: AppTypography.body()),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.hairline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar giliran percakapan - membungkus scroll + aturan ringkas riwayat
/// (AS-13: 8 giliran diringkas).
class ChatTranscript extends StatelessWidget {
  final List<ChatBubble> turns;
  final double maxHeight;

  const ChatTranscript({super.key, required this.turns, this.maxHeight = 320});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: turns),
      ),
    );
  }
}
