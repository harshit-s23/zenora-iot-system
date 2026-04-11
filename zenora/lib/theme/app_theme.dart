import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color background = Color(0xFF080D1A);
  static const Color cardBg = Color(0xFF0F1828);
  static const Color cardBg2 = Color(0xFF141E30);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentRed = Color(0xFFFF4757);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF7A8499);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color borderColor = Color(0xFF1E2D40);
  static const Color liveGreen = Color(0xFF00FF88);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentGreen,
        surface: cardBg,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: accentCyan,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textMuted),
      ),
    );
  }

  // Stress level colors
  static Color stressColor(double index) {
    if (index <= 30) return accentGreen;
    if (index <= 50) return accentCyan;
    if (index <= 70) return accentYellow;
    if (index <= 85) return accentOrange;
    return accentRed;
  }

  static String stressLabel(double index) {
    if (index <= 30) return 'Calm';
    if (index <= 50) return 'Relaxed';
    if (index <= 70) return 'Moderate';
    if (index <= 85) return 'High';
    return 'Very High';
  }

  static List<String> stressRecommendations(double index) {
    if (index <= 30) {
      return [
        '🧘 You\'re doing great! Keep up this calm state.',
        '🚶 Take a mindful walk to maintain your peace.',
        '🎵 Listen to your favorite music and enjoy the moment.',
        '📖 Great time to read or pursue a hobby.',
      ];
    } else if (index <= 50) {
      return [
        '🌬️ Try 5 minutes of deep breathing exercises.',
        '🚶 A short walk outside will help keep stress low.',
        '💧 Stay hydrated - drink a glass of water now.',
        '🎵 Put on some calming instrumental music.',
      ];
    } else if (index <= 70) {
      return [
        '🌬️ Practice box breathing: 4 counts in, hold, out, hold.',
        '🧘 Take a 10-minute mindfulness break right now.',
        '🚶 Step away from your desk - go for a walk.',
        '📵 Put your phone down for 15 minutes.',
      ];
    } else if (index <= 85) {
      return [
        '⚠️ High stress detected! Try 4-7-8 breathing immediately.',
        '🧘 Practice progressive muscle relaxation for 10 mins.',
        '🚿 Splash cold water on your face to reset.',
        '📞 Reach out to a friend or talk to someone.',
      ];
    } else {
      return [
        '🆘 Very high stress! Stop and take slow deep breaths now.',
        '🧘 Try guided meditation - open the Exercises tab.',
        '🚶 Take an immediate break from what you\'re doing.',
        '😴 Consider a short 20-minute nap if possible.',
      ];
    }
  }

  // Card decoration
  static BoxDecoration cardDecoration({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  static BoxDecoration glowDecoration(Color glowColor, {double radius = 16}) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glowColor.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.08),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
