// Prep screen — keyword flashcards with flip interaction and dot navigation.
import 'package:flutter/material.dart';
import '../models/keyword_model.dart';
import '../models/session_result_payload.dart';
import '../services/keyword_display_manager.dart';
import '../services/selection_tracker.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/keyword_card.dart';
import '../widgets/dot_indicator.dart';

class PrepScreen extends StatefulWidget {
  const PrepScreen({super.key});

  @override
  State<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends State<PrepScreen> {
  int currentIndex = 0;
  bool isFlipped = false;
  late List<int> cardStates;

  List<String> _overviewItems = [];
  String? _pages;
  int? _surah;
  String? _surahName;
  // ignore: unused_field
  late String _sessionId;
  late KeywordDisplayManager _manager;
  late SelectionTracker _tracker;
  late SessionService _sessionService;
  bool _initialized = false;
  late Stopwatch _stopwatch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _initialized = true;
      final overviewList = args['overview'] as List<String>? ?? [];
      _overviewItems = overviewList;

      _pages = args['pages'] as String?;
      _surah = args['surah'] as int?;
      _surahName = args['surahName'] as String?;
      _sessionId = args['sessionId'] as String? ?? '';

      final authService = args['authService'] as AuthService;
      _sessionService = SessionService(authService: authService);
      _tracker = SelectionTracker();
      _stopwatch = Stopwatch()..start();

      final rawKeywords =
          (args['keywords'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final keywordModels =
          rawKeywords.map((k) => KeywordModel.fromJson(k)).toList();
      _manager = KeywordDisplayManager(keywordModels);

      cardStates = List.filled(_manager.totalVisible, 0);
    }
  }

  void _onCardTap() {
    if (!isFlipped) {
      setState(() => isFlipped = true);
    }
  }

  void _handleKnown() {
    final currentKeyword = _manager.visibleKeywords[currentIndex];
    _tracker.record(currentKeyword.arabic, currentKeyword.translation, 'known');

    final isLastCard = currentIndex == _manager.totalVisible - 1;
    _manager.replaceKnown(currentIndex);

    // If visible list shrank and we're past the end, treat as last card
    if (currentIndex >= _manager.totalVisible) {
      _completeSession();
      return;
    }

    if (isLastCard && _manager.totalVisible == currentIndex) {
      _completeSession();
      return;
    }

    setState(() {
      cardStates = List.filled(_manager.totalVisible, 0);
      isFlipped = false;
    });
  }

  void _handleNotKnown() {
    final currentKeyword = _manager.visibleKeywords[currentIndex];
    _tracker.record(currentKeyword.arabic, currentKeyword.translation, 'not_known');

    final isLastCard = currentIndex == _manager.totalVisible - 1;
    if (isLastCard) {
      _completeSession();
      return;
    }

    setState(() {
      currentIndex = currentIndex + 1;
      isFlipped = false;
    });
  }

  void _setCardState(int stateValue) {
    if (stateValue == 1) {
      _handleKnown();
    } else if (stateValue == 2) {
      _handleNotKnown();
    }
  }

  Future<void> _completeSession() async {
    _stopwatch.stop();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/recitation', arguments: {
      'pages': _pages,
      'surah': _surah,
      'surahName': _surahName,
      'durationSecs': _stopwatch.elapsed.inSeconds,
      'keywords': _tracker.getRecords(),
      'authService': _sessionService,
      'sessionId': _sessionId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKeywords = _initialized && _manager.totalVisible > 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back, size: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _surahName != null && _pages != null
                          ? 'Surah $_surahName · Pages $_pages'
                          : _surahName != null
                              ? 'Surah $_surahName'
                              : _pages != null
                                  ? 'Pages $_pages'
                                  : 'Session',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: SingleChildScrollView(
                    child: _overviewItems.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _overviewItems
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('•  ',
                                              style: AppTextStyles.displayBody),
                                          Expanded(
                                            child: Text(item,
                                                style: AppTextStyles
                                                    .displayBody),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          )
                        : Text('Preparing your session...',
                            style: AppTextStyles.displayBody),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (hasKeywords) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KEYWORDS', style: AppTextStyles.label),
                    Text(
                      '${currentIndex + 1} of ${_manager.totalVisible}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: KeywordCard(
                    key: ValueKey('$currentIndex-$isFlipped'),
                    keyword: _manager.visibleKeywords[currentIndex].toJson(),
                    isFlipped: isFlipped,
                    onTap: _onCardTap,
                  ),
                ),
                const SizedBox(height: 12),
                if (isFlipped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _actionBtn('✓ Known', 1),
                        const SizedBox(width: 8),
                        _actionBtn('✗ Not known', 2),
                      ],
                    ),
                  ),
                DotIndicator(count: _manager.totalVisible, activeIndex: currentIndex),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      'No keywords available.',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, int stateValue) {
    final isActive = cardStates[currentIndex] == stateValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setCardState(stateValue),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primaryLight : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
