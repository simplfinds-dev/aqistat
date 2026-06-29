import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFFF4757);
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color cardDark = Color(0xFF1A1F38);
  static const Color textWhite = Color(0xFFF8F9FA);
  static const Color textGrey = Color(0xFF9BA4B5);
  static const Color textMuted = Color(0xFF5C6378);
  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color aqiGood = Color(0xFF00D4AA);
  static const Color aqiModerate = Color(0xFFFFD93D);
  static const Color aqiUnhealthy = Color(0xFFFF4757);
  static const Color aqiVeryUnhealthy = Color(0xFFA855F7);
  static const Color aqiHazardous = Color(0xFF7C0902);

  static const List<Color> nightSky = [Color(0xFF0A0E21), Color(0xFF111328), Color(0xFF1A1F38)];
  static const List<Color> daySky = [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)];
  static const List<Color> dawnSky = [Color(0xFF1A0533), Color(0xFF4A1942), Color(0xFFFF6B6B)];
  static const List<Color> sunsetSky = [Color(0xFF1A0533), Color(0xFFE94560), Color(0xFFFFC371)];

  static List<Color> getSkyGradient(int hour) {
    if (hour >= 5 && hour < 7) return dawnSky;
    if (hour >= 7 && hour < 17) return daySky;
    if (hour >= 17 && hour < 20) return sunsetSky;
    return nightSky;
  }

  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiModerate;
    if (aqi <= 200) return aqiUnhealthy;
    if (aqi <= 300) return aqiVeryUnhealthy;
    return aqiHazardous;
  }
}
