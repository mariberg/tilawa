// Authentication screen — username and password login.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _obscurePassword = true;

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 15, color: AppColors.textHint),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
      filled: false,
    );
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
              const SizedBox(height: 64),
              Text(
                'Welcome back',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your preparation',
                style: AppTextStyles.displayBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Username
              Text('USERNAME', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                cursorColor: AppColors.primary,
                decoration: _inputDecoration('Enter your username'),
              ),
              const SizedBox(height: 24),
              // Password
              Text('PASSWORD', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                cursorColor: AppColors.primary,
                decoration: _inputDecoration('Enter your password').copyWith(
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    elevation: 0,
                  ),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 16),
              // Sign up hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  GestureDetector(
                    onTap: () {}, // no-op for now
                    child: Text(
                      'Sign up',
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
