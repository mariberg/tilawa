import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modal bottom sheet for revisit sessions, offering two choices.
/// Returns `'revisit'` or `'moveOn'` via [Navigator.pop], or `null` on dismiss.
class RevisitBottomSheet extends StatelessWidget {
  final String revisitLabel;
  final String moveOnLabel;

  const RevisitBottomSheet({
    super.key,
    required this.revisitLabel,
    required this.moveOnLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Revisit option
          _optionRow(
            context,
            icon: '↻',
            label: revisitLabel,
            onTap: () => Navigator.pop(context, 'revisit'),
          ),
          // Move on option
          _optionRow(
            context,
            icon: '→',
            label: moveOnLabel,
            onTap: () => Navigator.pop(context, 'moveOn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _optionRow(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 0.5),
          ),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
