import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../providers/app_mode_provider.dart';
import '../theme/index.dart';

/// Ikon garis per mode - dipakai bersama oleh ModeBadge & ModePickerSheet.
IconData modeIcon(AppMode mode) => switch (mode) {
      AppMode.tuntun     => Icons.remove_red_eye_outlined,
      AppMode.money      => Icons.payments_outlined,
      AppMode.ocr        => Icons.article_outlined,
      AppMode.navigasi   => Icons.explore_outlined,
      AppMode.voice      => Icons.mic_none_rounded,
      AppMode.findObject => Icons.search_rounded,
    };

/// ModeBadge (F1) - pill identitas mode, opaque #202432, di atas kamera.
/// Bukan tombol untuk ganti mode (itu lewat tombol Pilih Mode / suara), tapi
/// ketuk 5× membuka panel debug tersembunyi (state switcher) bila disediakan
/// lewat [onDebugActivate] - mekanisme baku bagian 2 "Cara memalsukan fitur".
class ModeBadge extends StatefulWidget {
  final AppMode mode;
  final bool transitioning;
  final bool busy;
  final VoidCallback? onDebugActivate;

  const ModeBadge({
    super.key,
    required this.mode,
    this.transitioning = false,
    this.busy = false,
    this.onDebugActivate,
  });

  @override
  State<ModeBadge> createState() => _ModeBadgeState();
}

class _ModeBadgeState extends State<ModeBadge> {
  int _tapCount = 0;
  Timer? _tapResetTimer;

  void _onTap() {
    if (widget.onDebugActivate == null) return;
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(milliseconds: 800), () => _tapCount = 0);
    if (_tapCount >= 5) {
      _tapCount = 0;
      widget.onDebugActivate!();
    }
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    super.dispose();
  }

  IconData get _icon => modeIcon(widget.mode);

  String get _label {
    if (widget.transitioning) return 'Berpindah ke mode ${widget.mode.label}';
    if (widget.busy) return 'Mode aktif: ${widget.mode.label}, sedang mengenali';
    return 'Mode aktif: ${widget.mode.label}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Urutan fokus 3 - bagian 10, sesudah StatusBanner dan aksinya.
      sortKey: const OrdinalSortKey(3),
      header: true,
      label: _label,
      liveRegion: widget.transitioning || widget.busy,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: Container(
            key: ValueKey('${widget.mode.name}-${widget.transitioning}-${widget.busy}'),
            height: AppSizes.modeBadgeHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(color: AppColors.pillBg, borderRadius: AppRadius.pillShape),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.transitioning
                  ? [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onDark,
                          valueColor: AlwaysStoppedAnimation(AppColors.onDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Beralih ke ${widget.mode.label}…',
                          style: AppTypography.metricMono(color: AppColors.onDark.withValues(alpha: .9))),
                    ]
                  : widget.busy
                      ? [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: ExcludeSemantics(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onDark,
                                valueColor: AlwaysStoppedAnimation(AppColors.onDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const ExcludeSemantics(
                            child: Text('Mengenali…', style: TextStyle(color: AppColors.onDark, fontSize: 14)),
                          ),
                        ]
                      : [
                          ExcludeSemantics(child: Icon(_icon, size: 18, color: AppColors.onDark)),
                          const SizedBox(width: 8),
                          ExcludeSemantics(
                            child: Text('Mode: ${widget.mode.label}', style: AppTypography.label(color: AppColors.onDark)),
                          ),
                        ],
            ),
          ),
        ),
      ),
    );
  }
}
