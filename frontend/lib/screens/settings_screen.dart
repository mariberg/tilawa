// Settings screen — allows users to change their Arabic level.
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/level_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/level_option_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      _selectedLevel = _levelService!.currentLevel;
      _didExtractArgs = true;
    }
  }

  Future<void> _save() async {
    if (_selectedLevel == null) return;

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _levelService!.saveLevel(_selectedLevel!);
      if (!mounted) return;
      Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
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
                    'Arabic Level',
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
                          (_selectedLevel != null && !_isSaving) ? _save : null,
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
                      child: const Text('Save'),
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
