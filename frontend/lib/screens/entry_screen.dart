// Home screen — text input, familiarity selection, recent sessions, and prepare button.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/familiarity_pills.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'What are you about to recite?',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Text input
              TextField(
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  hintText: 'e.g. 50–54 or Surah Al-Baqarah',
                  hintStyle: TextStyle(fontSize: 15, color: AppColors.textHint),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: false,
                ),
              ),
              const SizedBox(height: 24),
              // Familiarity
              Text('FAMILIARITY', style: AppTextStyles.label),
              const SizedBox(height: 10),
              const FamiliarityPills(),
              const SizedBox(height: 28),
              // Recent sessions
              Text('CONTINUE WHERE YOU LEFT OFF', style: AppTextStyles.label),
              const SizedBox(height: 12),
              _recentRow('Pages 50–54', 'Yesterday'),
              const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
              _recentRow('Pages 12–15', '3 days ago'),
              const Spacer(),
              // Prepare button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/prep'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Prepare'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _recentRow(String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
