// Post-recitation feedback screen — user rates how the session felt.
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selected = -1;
  bool _showComplete = false;
  double _completeOpacity = 0.0;
  String? _sessionId;
  SessionService? _sessionService;
  bool _didExtractArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didExtractArgs) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _didExtractArgs = true;
      _sessionId = args['sessionId'] as String?;
      _sessionService = args['sessionService'] as SessionService?;
    }
  }

  static const feelingMap = {0: 'smooth', 1: 'struggled', 2: 'revisit'};

  static const _options = [
    {'label': 'Smooth', 'icon': '✓'},
    {'label': 'Struggled a little', 'icon': '~'},
    {'label': 'Need to revisit', 'icon': '↻'},
  ];

  void _submit() {
    if (_sessionId != null && _sessionService != null) {
      _sessionService!
          .submitFeeling(
            sessionId: _sessionId!,
            feeling: feelingMap[_selected]!,
          )
          .catchError((e) {
        debugPrint('submitFeeling error: $e');
      });
    }
    setState(() => _showComplete = true);
    // Fade in
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => _completeOpacity = 1.0);
    });
    // Hold, then fade out and navigate
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _completeOpacity = 0.0);
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showComplete) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AnimatedOpacity(
            opacity: _completeOpacity,
            duration: const Duration(milliseconds: 500),
            child: Text(
              'Session complete.',
              style: AppTextStyles.h1,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                'How did it feel?',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This helps tailor your next preparation',
                style: AppTextStyles.displayBody.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ...List.generate(_options.length, (i) {
                final isSelected = _selected == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (_selected >= 0) return; // already selected
                      setState(() => _selected = i);
                      _submit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _options[i]['icon']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            _options[i]['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(flex: 3),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
