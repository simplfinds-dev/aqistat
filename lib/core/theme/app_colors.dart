import 'package:flutter/material.dart';

/// Dynamic color system that shifts with time of day and weather conditions
class AppColors {
  AppColors._();

  // === BRAND COLORS ===
  static const Color primary = Color(0xFF4A90D9);
  static const Color secondary = Color(0xFF7B61FF);
  static const Color accent = Color(0xFFFF6B6B);

  // === TIME-OF-DAY PALETTES ===
  // Dawn (5AM - 7AM)
  static const List<Color> dawnGradient = [
    Color(0xFFFF9A9E),
    Color(0xFFFECFEF),
    Color(0xFFFAD0C4),
  ];

  // Morning (7AM - 11AM)
  static const List<Color> morningGradient = [
    Color(0xFF89CFF0),
    Color(0xFFA0E7E5),
    Color(0xFFFFF5BA),
  ];

  // Midday (11AM - 3PM)
  static const List<Color> middayGradient = [
    Color(0xFF56CCF2),
    Color(0xFF2F80ED),
    Color(0xFF6DD5FA),
  ];

  // Afternoon (3PM - 6PM)
  static const List<Color> afternoonGradient = [
    Color(0xFFFFC371),
    Color(0xFFFF5F6D),
    Color(0xFFFFE259),
  ];

  // Dusk (6PM - 8PM)
  static const List<Color> duskGradient = [
    Color(0xFFE96443),
    Color(0xFF904E95),
    Color(0xFFB721FF),
  ];

  // Night (8PM - 5AM)
  static const List<Color> nightGradient = [
    Color(0xFF0F2027),
    Color(0xFF203A43),
    Color(0xFF2C5364),
  ];

  // === WEATHER CONDITION OVERLAYS ===
  static const Color rainyOverlay = Color(0x40607D8B);
  static const Color cloudyOverlay = Color(0x30B0BEC5);
  static const Color snowOverlay = Color(0x20E8EAF6);
  static const Color fogOverlay = Color(0x50CFD8DC);
  static const Color stormOverlay = Color(0x60263238);

  // === AQI COLORS (Traffic Light System) ===
  static const Color aqiGood = Color(0xFF4CAF50); // 0-50
  static const Color aqiModerate = Color(0xFFFFEB3B); // 51-100
  static const Color aqiUnhealthySensitive = Color(0xFFFF9800); // 101-150
  static const Color aqiUnhealthy = Color(0xFFF44336); // 151-200
  static const Color aqiVeryUnhealthy = Color(0xFF9C27B0); // 201-300
  static const Color aqiHazardous = Color(0xFF880E4F); // 301-500

  // === UV INDEX COLORS ===
  static const Color uvLow = Color(0xFF4CAF50); // 0-2
  static const Color uvModerate = Color(0xFFFFEB3B); // 3-5
  static const Color uvHigh = Color(0xFFFF9800); // 6-7
  static const Color uvVeryHigh = Color(0xFFF44336); // 8-10
  static const Color uvExtreme = Color(0xFF9C27B0); // 11+

  // === DAY RATING COLORS ===
  static const Color dayGreat = Color(0xFF66BB6A);
  static const Color dayGood = Color(0xFF81C784);
  static const Color dayFair = Color(0xFFFFCA28);
  static const Color dayPoor = Color(0xFFFF7043);
  static const Color dayBad = Color(0xFFEF5350);

  // === NEUTRAL PALETTE ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A6A);
  static const Color textTertiary = Color(0xFF8A8AA0);
  static const Color surface = Color(0xFFF8F9FE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E2E);
  static const Color divider = Color(0xFFE8E8F0);

  // === DARK MODE ===
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  /// Get gradient based on current hour
  static List<Color> getTimeGradient(int hour) {
    if (hour >= 5 && hour < 7) return dawnGradient;
    if (hour >= 7 && hour < 11) return morningGradient;
    if (hour >= 11 && hour < 15) return middayGradient;
    if (hour >= 15 && hour < 18) return afternoonGradient;
    if (hour >= 18 && hour < 20) return duskGradient;
    return nightGradient;
  }

  /// Get AQI color based on value (US EPA scale)
  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiModerate;
    if (aqi <= 150) return aqiUnhealthySensitive;
    if (aqi <= 200) return aqiUnhealthy;
    if (aqi <= 300) return aqiVeryUnhealthy;
    return aqiHazardous;
  }

  /// Get UV color based on index
  static Color getUvColor(double uv) {
    if (uv <= 2) return uvLow;
    if (uv <= 5) return uvModerate;
    if (uv <= 7) return uvHigh;
    if (uv <= 10) return uvVeryHigh;
    return uvExtreme;
  }
}
