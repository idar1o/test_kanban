import 'package:flutter/material.dart';

import 'home_screen.dart';

class AppColors {
  static const scaffold = Color(0xFF0F0B1E);
  static const appBar = Color(0xFF1A1432);
  static const columnBg = Color(0xFF1C1830);
  static const cardBg = Color(0xFF2A2544);
  static const cardBorder = Color(0xFF3A3456);
  static const textPrimary = Color(0xFFEDEBF5);
  static const textSecondary = Color(0xFF9A94B8);
  static const textMuted = Color(0xFF5D5778);
  static const accentPurple = Color(0xFF7C3AED);
  static const accentRed = Color(0xFFE53935);
  static const dragRed = Color(0xFFE53935);
  static const dragRedBorder = Color(0xFFFF5A63);
  static const indicatorFill = Color(0x33E53935);
  static const indicatorBorder = Color(0xFFE53935);
  static const badgeBg = Color(0xFF3A3456);
  static const badgeText = Color(0xFFBFBAD9);
}

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanban',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffold,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentPurple,
          secondary: AppColors.accentRed,
          surface: AppColors.columnBg,
          onSurface: AppColors.textPrimary,
          error: AppColors.accentRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBar,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme().apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.cardBg,
          contentTextStyle: TextStyle(color: AppColors.textPrimary),
          actionTextColor: AppColors.accentRed,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
