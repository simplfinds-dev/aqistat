import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AQI scale types
enum AqiScale { epa, naqi, mee, eaqi, defra, aus, cai, moe, waqi }

/// Utility class for Air Quality Index calculations and conversions
class AqiUtils {
  AqiUtils._();

  /// Get AQI scale from country code
  static AqiScale getScaleForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'US':
        return AqiScale.epa;
      case 'IN':
        return AqiScale.naqi;
      case 'CN':
        return AqiScale.mee;
      case 'GB':
        return AqiScale.defra;
      case 'AU':
        return AqiScale.aus;
      case 'KR':
        return AqiScale.cai;
      case 'JP':
        return AqiScale.moe;
      // EU countries
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
      case 'SE':
      case 'NO':
      case 'DK':
      case 'FI':
      case 'PL':
      case 'PT':
      case 'AT':
      case 'IE':
      case 'GR':
      case 'CZ':
      case 'RO':
      case 'HU':
        return AqiScale.eaqi;
      default:
        return AqiScale.waqi;
    }
  }

  /// Get scale display name
  static String getScaleName(AqiScale scale) {
    switch (scale) {
      case AqiScale.epa:
        return 'US AQI (EPA)';
      case AqiScale.naqi:
        return 'NAQI (CPCB)';
      case AqiScale.mee:
        return 'CN AQI (MEE)';
      case AqiScale.eaqi:
        return 'EAQI (EEA)';
      case AqiScale.defra:
        return 'DAQI (DEFRA)';
      case AqiScale.aus:
        return 'AUS AQI';
      case AqiScale.cai:
        return 'CAI (NIER)';
      case AqiScale.moe:
        return 'Soramame (MOE)';
      case AqiScale.waqi:
        return 'WAQI (Unified)';
    }
  }

  /// Get scale range
  static String getScaleRange(AqiScale scale) {
    switch (scale) {
      case AqiScale.defra:
        return '1–10';
      case AqiScale.eaqi:
        return '0–100';
      case AqiScale.moe:
        return '4 levels';
      default:
        return '0–500';
    }
  }

  /// Convert WAQI value to local scale
  static int convertToLocalScale(int waqiValue, AqiScale targetScale) {
    switch (targetScale) {
      case AqiScale.defra:
        // WAQI 0-500 → DEFRA 1-10
        return ((waqiValue / 50).clamp(1, 10)).round();
      case AqiScale.eaqi:
        // WAQI 0-500 → EAQI 0-100
        return ((waqiValue / 5).clamp(0, 100)).round();
      case AqiScale.moe:
        // WAQI 0-500 → MOE 1-4
        if (waqiValue <= 50) return 1;
        if (waqiValue <= 100) return 2;
        if (waqiValue <= 200) return 3;
        return 4;
      default:
        // EPA, NAQI, MEE, AUS, CAI, WAQI all use similar 0-500 range
        return waqiValue;
    }
  }

  /// Get AQI color based on WAQI/EPA value
  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return AppColors.aqiGood;
    if (aqi <= 100) return AppColors.aqiModerate;
    if (aqi <= 150) return AppColors.aqiUnhealthySensitive;
    if (aqi <= 200) return AppColors.aqiUnhealthy;
    if (aqi <= 300) return AppColors.aqiVeryUnhealthy;
    return AppColors.aqiHazardous;
  }

  /// Get plain-English AQI level name
  static String getAqiLevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  /// Get plain-English AQI message (human-friendly)
  static String getAqiMessage(int aqi) {
    if (aqi <= 50) {
      return 'Air quality is great today. Perfect for outdoor activities!';
    }
    if (aqi <= 100) {
      return 'Air is acceptable. Unusually sensitive people should limit prolonged outdoor exertion.';
    }
    if (aqi <= 150) {
      return 'Air is getting unhealthy for sensitive groups. Consider reducing intense outdoor activities.';
    }
    if (aqi <= 200) {
      return 'Air is unhealthy today. Avoid prolonged outdoor exercise. Keep windows closed.';
    }
    if (aqi <= 300) {
      return 'Air quality is very poor. Stay indoors if possible. Use an air purifier.';
    }
    return 'Hazardous air quality! Avoid all outdoor activity. Keep all windows and doors sealed.';
  }

  /// Get health recommendation based on AQI
  static String getHealthAdvice(int aqi) {
    if (aqi <= 50) {
      return 'Enjoy outdoor activities freely.';
    }
    if (aqi <= 100) {
      return 'Sensitive individuals should consider limiting prolonged outdoor exertion.';
    }
    if (aqi <= 150) {
      return 'People with respiratory or heart conditions should reduce outdoor exercise.';
    }
    if (aqi <= 200) {
      return 'Everyone should reduce prolonged outdoor exertion. Sensitive groups should avoid outdoor activity.';
    }
    if (aqi <= 300) {
      return 'Everyone should avoid prolonged outdoor exertion. Sensitive groups should remain indoors.';
    }
    return 'Everyone should avoid all outdoor physical activity. Emergency conditions.';
  }

  /// Get AQI emoji
  static String getAqiEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 150) return '😐';
    if (aqi <= 200) return '😷';
    if (aqi <= 300) return '🤢';
    return '☠️';
  }
}
