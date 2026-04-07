// Interactive keyword flashcard with flip animation.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KeywordCard extends StatelessWidget {
  final Map<String, dynamic> keyword;
  final bool isFlipped;
  final VoidCallback onTap;
  const KeywordCard({
    super.key,
    required this.keyword,
    required this.isFlipped,
    required this.onTap,
  });

  Widget _buildTag() {
    final isFocus = keyword['type'] == 'focus';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isFocus ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: isFocus ? null : Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        isFocus ? 'Focus word' : 'Advanced word',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isFocus ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTag(),
        const SizedBox(height: 24),
        Text(
          keyword['arabic'],
          style: AppTextStyles.arabic,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to reveal',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildBack(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTag(),
        const SizedBox(height: 16),
        Text(
          keyword['arabic'],
          style: AppTextStyles.arabicSmall,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Text(
          keyword['translation'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            keyword['hint'],
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isFlipped
              ? _buildBack(context)
              : _buildFront(),
        ),
      ),
    );
  }
}
