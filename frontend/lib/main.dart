// App entry point — MaterialApp with routes and theme.
import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/prep_screen.dart';
import 'screens/recitation_screen.dart';
import 'screens/feedback_screen.dart';

void main() {
  runApp(const QuranPrepApp());
}

class QuranPrepApp extends StatelessWidget {
  const QuranPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Prep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthScreen(),
        '/home': (_) => const EntryScreen(),
        '/prep': (_) => const PrepScreen(),
        '/recitation': (_) => const RecitationScreen(),
        '/feedback': (_) => const FeedbackScreen(),
      },
    );
  }
}
