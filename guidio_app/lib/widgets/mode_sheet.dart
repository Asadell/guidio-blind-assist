import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/index.dart';

void showModeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ModeSheet(),
  );
}

class _ModeSheet extends StatelessWidget {
  const _ModeSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppModeProvider>().mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pilih Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'atau ucapkan nama mode via tombol MIC',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...AppMode.values.map((mode) => _ModeTile(
                mode:      mode,
                isCurrent: mode == current,
                onTap: () {
                  context.read<AppModeProvider>().setMode(mode);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final AppMode       mode;
  final bool          isCurrent;
  final VoidCallback  onTap;
  const _ModeTile({required this.mode, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(mode.icon, style: const TextStyle(fontSize: 20)),
      title:   Text(mode.label),
      trailing: isCurrent
          ? const Chip(
              label:           Text('AKTIF'),
              backgroundColor: Color(0xFFE3F2FD),
            )
          : null,
      selected: isCurrent,
      onTap:    onTap,
    );
  }
}
