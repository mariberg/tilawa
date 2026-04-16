// Level selection screen — shown on first login when no Arabic level is stored.
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/level_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/level_option_picker.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  AuthService? _authService;
  LevelService? _levelService;
  bool _didExtractArgs = false;

  String? _selectedLevel;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didExtractArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null ||
          args is! Map<String, dynamic> ||
          args['authService'] is! AuthService ||
          args['levelService'] is! LevelService) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
        return;
      }
      _authService = args['authService'] as AuthService;
      _levelService = args['levelService'] as LevelService;
      _didExtractArgs = true;
    }
  }

  Future<void> _confirm() async {
    if (_selectedLevel == null) return;

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _levelService!.saveLevel(_selectedLevel!);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: {
        'authService': _authService!,
        'levelService': _levelService!,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not save your Arabic level. Please try again.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    "What's your Arabic level?",
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  LevelOptionPicker(
                    selectedLevel: _selectedLevel,
                    onSelected: (level) {
                      setState(() {
                        _selectedLevel = level;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedLevel != null && !_isSaving) ? _confirm : null,
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
                      child: const Text('Continue'),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
