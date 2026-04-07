// Prep screen — keyword flashcards with flip interaction and dot navigation.
import 'package:flutter/material.dart';
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
  // Track action state per card: 0=none, 1=known, 2=notSure, 3=review
  late List<int> cardStates;

  final List<Map<String, dynamic>> keywords = [
    {
      'arabic': 'صَبْر',
      'translation': 'Patience / Steadfastness',
      'hint': 'Used when enduring hardship with faith',
      'type': 'focus',
    },
    {
      'arabic': 'تَقْوَى',
      'translation': 'God-consciousness / Piety',
      'hint': 'A state of inner awareness and reverence',
      'type': 'focus',
    },
    {
      'arabic': 'اِسْتِكْبَار',
      'translation': 'Arrogance / Pride',
      'hint': 'Rejecting truth out of self-importance',
      'type': 'advanced',
    },
    {
      'arabic': 'هِدَايَة',
      'translation': 'Guidance',
      'hint': 'Divine direction toward truth',
      'type': 'focus',
    },
  ];

  @override
  void initState() {
    super.initState();
    cardStates = List.filled(keywords.length, 0);
  }

  void _onCardTap() {
    if (!isFlipped) {
      setState(() => isFlipped = true);
    }
    // When flipped, tapping the card does nothing — user must pick an action button.
  }

  void _setCardState(int value) {
    setState(() {
      cardStates[currentIndex] = value;
    });
    final isLastCard = currentIndex == keywords.length - 1;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (isLastCard) {
        Navigator.pushReplacementNamed(context, '/recitation');
      } else {
        setState(() {
          currentIndex = currentIndex + 1;
          isFlipped = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav row
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
                      'Surah Al-Baqarah · Pages 50–54',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Overview
              Text(
                'This passage discusses trials faced by believers and the enduring consequences of turning away from guidance.',
                style: AppTextStyles.displayBody,
              ),
              const SizedBox(height: 20),
              // Keywords header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KEYWORDS', style: AppTextStyles.label),
                  Text(
                    '${currentIndex + 1} of ${keywords.length}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Keyword card
              Expanded(
                child: KeywordCard(
                  key: ValueKey('$currentIndex-$isFlipped'),
                  keyword: keywords[currentIndex],
                  isFlipped: isFlipped,
                  onTap: _onCardTap,
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons (shown when flipped)
              if (isFlipped)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _actionBtn('✓ Known', 1),
                      const SizedBox(width: 8),
                      _actionBtn('? Not sure', 2),
                      const SizedBox(width: 8),
                      _actionBtn('↻ Review', 3),
                    ],
                  ),
                ),
              // Dot indicator
              DotIndicator(count: keywords.length, activeIndex: currentIndex),
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
