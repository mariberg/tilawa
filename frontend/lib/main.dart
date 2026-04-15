// App entry point — MaterialApp with routes and theme.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/prep_screen.dart';
import 'screens/recitation_screen.dart';
import 'screens/feedback_screen.dart';

/// Global route observer so screens can react when they become visible again.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Checks if the current browser URL is an OAuth2 callback and extracts
/// the `code` and `state` query parameters if present.
({String code, String state})? _extractOAuthCallback() {
  final uri = Uri.base;
  if (uri.path == '/auth/callback' &&
      uri.queryParameters.containsKey('code') &&
      uri.queryParameters.containsKey('state')) {
    return (
      code: uri.queryParameters['code']!,
      state: uri.queryParameters['state']!,
    );
  }
  return null;
}

Future<void> main() async {
  await dotenv.load();
  final oauthCallback = _extractOAuthCallback();
  runApp(QuranPrepApp(oauthCallback: oauthCallback));
}

class QuranPrepApp extends StatelessWidget {
  final ({String code, String state})? oauthCallback;

  const QuranPrepApp({super.key, this.oauthCallback});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Prep',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => AuthScreen(oauthCallback: oauthCallback),
        '/home': (_) => const EntryScreen(),
        '/prep': (_) => const PrepScreen(),
        '/recitation': (_) => const RecitationScreen(),
        '/feedback': (_) => const FeedbackScreen(),
      },
    );
  }
}
