import 'package:flutter/material.dart';

class SoundPickerSheet extends StatelessWidget {
  final String selectedSound;
  final ValueChanged<String> onSoundSelected;

  static const sounds = [
    ('default', 'Default'),
    ('radar', 'Radar'),
    ('crystal', 'Crystal'),
    ('pulse', 'Pulse'),
    ('echo', 'Echo'),
    ('ripple', 'Ripple'),
  ];

  const SoundPickerSheet({
    super.key,
    required this.selectedSound,
    required this.onSoundSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedSound,
    required ValueChanged<String> onSoundSelected,
  }) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      builder: (_) => SoundPickerSheet(
        selectedSound: selectedSound,
        onSoundSelected: onSoundSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ALARM SOUND',
            style: TextStyle(
              fontFamily: 'GoogleFonts.plusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...sounds.map(
            (sound) => _SoundTile(
              id: sound.$1,
              label: sound.$2,
              isSelected: selectedSound == sound.$1,
              cs: cs,
              onTap: () {
                onSoundSelected(sound.$1);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _SoundTile({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'GoogleFonts.plusJakartaSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
