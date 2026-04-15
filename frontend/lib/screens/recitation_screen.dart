// Recitation session screen — waveform visualization and tap-to-finish.
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/keyword_selection_record.dart';
import '../models/session_result_payload.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSubmitting = false;

  String? _pages;
  int? _surah;
  String? _surahName;
  int _durationSecs = 0;
  List<KeywordSelectionRecord> _keywords = [];
  SessionService? _sessionService;
  String? _sessionId;
  bool _didExtractArgs = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didExtractArgs) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _didExtractArgs = true;
      _pages = args['pages'] as String?;
      _surah = args['surah'] as int?;
      _surahName = args['surahName'] as String?;
      _durationSecs = args['durationSecs'] as int? ?? 0;
      _keywords =
          args['keywords'] as List<KeywordSelectionRecord>? ?? [];
      _sessionService = args['authService'] as SessionService?;
      _sessionId = args['sessionId'] as String?;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDone() async {
    String? createdSessionId;
    if (_sessionService != null && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      try {
        createdSessionId = await _sessionService!.submitResults(
          payload: SessionResultPayload(
            pages: _pages,
            surah: _surah,
            durationSecs: _durationSecs,
            keywords: _keywords,
          ),
        );
        debugPrint('[RecitationScreen] submitResults returned sessionId: $createdSessionId');
      } catch (e) {
        debugPrint('[RecitationScreen] submitResults error: $e');
      }
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/feedback',
      arguments: {
        'sessionId': createdSessionId ?? _sessionId,
        'sessionService': _sessionService,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
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
              const Spacer(),
              // Title
              Text(
                'Begin when you\'re ready',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap below when you finish',
                style: AppTextStyles.displayBody.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Waveform
              SizedBox(
                height: 120,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WaveformPainter(
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              // Done button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;

  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 40;
    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height * 0.8;
    final centerY = size.height / 2;
    final rng = Random(42);

    for (int i = 0; i < barCount; i++) {
      final x = (i * 2 + 0.5) * barWidth;
      final baseRatio = 0.15 + rng.nextDouble() * 0.85;
      final phase = (progress * 2 * pi) + (i / barCount * 2 * pi);
      final heightRatio = baseRatio * (0.4 + 0.6 * ((sin(phase) + 1) / 2));
      final barHeight = maxHeight * heightRatio;

      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5 + 0.5 * heightRatio);
      paint.strokeCap = StrokeCap.round;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth * 0.7,
          height: barHeight.clamp(2.0, maxHeight),
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
