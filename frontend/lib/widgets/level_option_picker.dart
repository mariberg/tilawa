// Shared widget for selecting an Arabic proficiency level.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LevelOptionPicker extends StatelessWidget {
  final String? selectedLevel;
  final ValueChanged<String> onSelected;

  const LevelOptionPicker({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
  });

  static const _options = [
    {'label': "I'm a beginner", 'value': 'beginner'},
    {'label': 'I can follow along', 'value': 'intermediate'},
    {'label': 'I read with understanding', 'value': 'advanced'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _options.map((option) {
        final value = option['value']!;
        final isSelected = selectedLevel == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(option['label']!, style: AppTextStyles.body),
            ),
          ),
        );
      }).toList(),
    );
  }
}
