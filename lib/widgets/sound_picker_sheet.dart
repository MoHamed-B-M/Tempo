import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

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
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardOf(context),
      builder: (_) => SoundPickerSheet(
        selectedSound: selectedSound,
        onSoundSelected: onSoundSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.dimWhiteOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ALARM SOUND',
            style: AppTextStyles.buttonLabel(context),
          ),
          const SizedBox(height: 16),
          ...sounds.map(
            (sound) => _SoundTile(
              id: sound.$1,
              label: sound.$2,
              isSelected: selectedSound == sound.$1,
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
  final VoidCallback onTap;

  const _SoundTile({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked;

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
              color: isSelected
                  ? AppColors.primaryTextOf(context)
                  : AppColors.secondaryTextOf(context),
            ),
            const SizedBox(width: 16),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.body(context).copyWith(
                color: isSelected
                    ? AppColors.primaryTextOf(context)
                    : AppColors.secondaryTextOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
