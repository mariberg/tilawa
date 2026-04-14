// Home screen — text input, familiarity selection, recent sessions, and prepare button.
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/surah.dart';
import '../services/surah_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
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
  AuthService? _authService;
  SessionService? _sessionService;
  bool _didExtractArgs = false;

  final SurahService _surahService = SurahService();
  final TextEditingController _textController = TextEditingController();

  List<Surah>? _surahs;
  Surah? _selectedSurah;
  String? _error;
  bool _isLoading = true;
  bool _isPreparing = false;
  String _familiarity = 'New';

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didExtractArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null || args is! AuthService) {
        // After a full refresh, arguments are lost — redirect to login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
        return;
      }
      _authService = args;
      _sessionService = SessionService(authService: _authService!);
      _didExtractArgs = true;
    }
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

  /// Validates page input. Only accepts a single number (e.g. "50")
  /// or a range with a dash (e.g. "50-54" or "50–54"). Returns the
  /// normalized pages string (using "-") or null if input is not pages.
  /// Throws if the format starts with a digit but is invalid.
  String? _parsePages(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    // Not a page input if it doesn't start with a digit
    if (!RegExp(r'^\d').hasMatch(trimmed)) return null;
    // Single page number
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
    // Range like "50-54" or "50–54" (with optional spaces around dash)
    final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      return '${rangeMatch.group(1)}-${rangeMatch.group(2)}';
    }
    // Anything else starting with a digit is invalid (commas, spaces, etc.)
    throw FormatException(
      'Invalid page format. Use a single page (e.g. 50) or a range (e.g. 50-54).',
    );
  }

  Future<void> _prepare() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Please enter pages or a surah name.');
      return;
    }

    setState(() {
      _error = null;
      _isPreparing = true;
    });

    try {
      final pages = _parsePages(input);
      final surah = pages == null ? input : null;

      final response = await _sessionService!.prepare(
        pages: pages,
        surah: surah,
        familiarity: _familiarity,
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/prep', arguments: {
        'sessionId': response.sessionId,
        'overview': response.overview,
        'keywords': response.keywords.map((k) => k.toJson()).toList(),
        'pages': pages,
        'surah': _selectedSurah?.id,
        'authService': _authService!,
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
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
              const SizedBox(height: 24),
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
                  _selectedSurah = surah;
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
              FamiliarityPills(
                onChanged: (value) => _familiarity = value,
              ),
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
                  onPressed: _isPreparing ? null : _prepare,
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
                  child: _isPreparing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : const Text('Prepare'),
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
