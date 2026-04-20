// Authentication screen — OAuth2 login via Quran.Foundation.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/material.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../services/level_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The redirect URI registered with the OAuth2 provider.
/// Falls back to localhost for local development.
String get _kRedirectUri => AppConfig.redirectUri;

class AuthScreen extends StatefulWidget {
  /// OAuth2 callback parameters extracted from the browser URL on app init.
  final ({String code, String state})? oauthCallback;

  const AuthScreen({super.key, this.oauthCallback});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  // --- Mock auth UI code below is commented out (replaced by OAuth2 login flow) ---
  // bool _obscurePassword = true;
  // final TextEditingController _usernameController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  // String? _errorMessage;
  // bool _isButtonEnabled = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _usernameController.addListener(_onFieldChanged);
  //   _passwordController.addListener(_onFieldChanged);
  // }

  // void _onFieldChanged() {
  //   final enabled =
  //       _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  //   setState(() {
  //     _isButtonEnabled = enabled;
  //     _errorMessage = null;
  //   });
  // }

  // @override
  // void dispose() {
  //   _usernameController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }

  // InputDecoration _inputDecoration(String hint) {
  //   return InputDecoration(
  //     hintText: hint,
  //     hintStyle: const TextStyle(fontSize: 15, color: AppColors.textHint),
  //     enabledBorder: const UnderlineInputBorder(
  //       borderSide: BorderSide(color: AppColors.border),
  //     ),
  //     focusedBorder: const UnderlineInputBorder(
  //       borderSide: BorderSide(color: AppColors.primary),
  //     ),
  //     filled: false,
  //   );
  // }
  // --- End of commented-out mock auth UI code ---

  @override
  void initState() {
    super.initState();
    // If the app was loaded with an OAuth2 callback URL, handle it immediately.
    if (widget.oauthCallback != null) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleOAuthCallback(
          widget.oauthCallback!.code,
          widget.oauthCallback!.state,
        );
      });
    }
  }

  /// Initiates the OAuth2 login flow by navigating the browser to the
  /// authorization URL.
  void _startOAuthLogin() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final result = _authService.buildAuthorizationUrl(_kRedirectUri);
    // Use raw JS to force navigation — bypasses Flutter's service worker.
    js.context.callMethod('eval', ['window.location.replace("${result.url}")']);
  }

  /// Handles the OAuth2 callback by exchanging the authorization code for
  /// tokens and navigating to the home screen on success.
  Future<void> _handleOAuthCallback(String code, String state) async {
    try {
      await _authService.handleCallback(code, state, _kRedirectUri);
      if (!mounted) return;

      final levelService = LevelService(authService: _authService);
      await levelService.fetchLevel();
      if (!mounted) return;

      final args = {
        'authService': _authService,
        'levelService': levelService,
      };

      if (levelService.currentLevel == null) {
        Navigator.pushReplacementNamed(context, '/level', arguments: args);
      } else {
        Navigator.pushReplacementNamed(context, '/home', arguments: args);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
              const Spacer(),
              Text(
                'Tilawa',
                style: AppTextStyles.h1.copyWith(fontSize: 38),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Text(
                'Your recitation preparation starts here.',
                style: AppTextStyles.h1.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to begin your session.',
                style: AppTextStyles.displayBody.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              // --- Mock auth form elements below are commented out (replaced by OAuth2 login flow) ---
              // const SizedBox(height: 40),
              // // Username
              // Text('USERNAME', style: AppTextStyles.label),
              // const SizedBox(height: 8),
              // TextField(
              //   controller: _usernameController,
              //   style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              //   cursorColor: AppColors.primary,
              //   decoration: _inputDecoration('Enter your username'),
              // ),
              // const SizedBox(height: 24),
              // // Password
              // Text('PASSWORD', style: AppTextStyles.label),
              // const SizedBox(height: 8),
              // TextField(
              //   controller: _passwordController,
              //   obscureText: _obscurePassword,
              //   style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              //   cursorColor: AppColors.primary,
              //   decoration: _inputDecoration('Enter your password').copyWith(
              //     suffixIcon: GestureDetector(
              //       onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              //       child: Icon(
              //         _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              //         size: 20,
              //         color: AppColors.textHint,
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: Text(
              //     'Forgot password?',
              //     style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              //   ),
              // ),
              // if (_errorMessage != null) ...[
              //   const SizedBox(height: 12),
              //   Text(
              //     _errorMessage!,
              //     style: const TextStyle(fontSize: 13, color: Colors.red),
              //     textAlign: TextAlign.center,
              //   ),
              // ],
              // const Spacer(),
              // // Sign in button
              // SizedBox(
              //   width: double.infinity,
              //   height: 54,
              //   child: ElevatedButton(
              //     onPressed: _isButtonEnabled
              //         ? () {
              //             final username = _usernameController.text;
              //             final password = _passwordController.text;
              //             if (_authService.validate(username, password)) {
              //               _authService.setUser(username);
              //               Navigator.pushReplacementNamed(context, '/home', arguments: _authService);
              //             } else {
              //               setState(() {
              //                 _errorMessage = 'Invalid username or password';
              //               });
              //             }
              //           }
              //         : null,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.primary,
              //       foregroundColor: AppColors.primaryLight,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(14),
              //       ),
              //       textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              //       elevation: 0,
              //     ),
              //     child: const Text('Sign in'),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // // Sign up hint
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text(
              //       "Don't have an account? ",
              //       style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              //     ),
              //     GestureDetector(
              //       onTap: () {}, // no-op for now
              //       child: Text(
              //         'Sign up',
              //         style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 24),
              // --- End of commented-out mock auth form elements ---
              // OAuth2 login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startOAuthLogin,
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
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : const Text('Continue with Quran Foundation'),
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
