// Home screen — text input, familiarity selection, recent sessions, and prepare button.
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/surah.dart';
import '../services/surah_service.dart';
import '../widgets/familiarity_pills.dart';

/// Filters [surahs] by case-insensitive substring match on [nameSimple].
/// Returns an empty list when [query] is empty or starts with a digit
/// (indicating a page-range input like "50–54").
List<Surah> filterSurahs(List<Surah> surahs, String query) {
  final trimmed = query.trimLeft();
  if (trimmed.isEmpty || RegExp(r'^\d').hasMatch(trimmed)) return [];
  final lowerQuery = trimmed.toLowerCase();
  return surahs
      .where((s) => s.nameSimple.toLowerCase().contains(lowerQuery))
      .toList();
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final SurahService _surahService = SurahService();
  final TextEditingController _textController = TextEditingController();

  List<Surah>? _surahs;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await _surahService.fetchSurahs();
      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load surah data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
              // Typeahead surah search
              TypeAheadField<Surah>(
                controller: _textController,
                suggestionsCallback: (search) {
                  if (_isLoading) return <Surah>[];
                  return filterSurahs(_surahs ?? [], search);
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 50–54 or Surah Al-Baqarah',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.textHint,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      filled: false,
                    ),
                  );
                },
                itemBuilder: (context, surah) {
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          surah.nameSimple,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onSelected: (surah) {
                  _textController.text = surah.nameSimple;
                },
                emptyBuilder: (context) {
                  // Hide the dropdown when input looks like a page number
                  final text = _textController.text.trimLeft();
                  if (text.isEmpty || RegExp(r'^\d').hasMatch(text)) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'No surahs found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context) {
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                decorationBuilder: (context, child) {
                  return Material(
                    type: MaterialType.card,
                    elevation: 4,
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
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
              const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderLight,
              ),
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
