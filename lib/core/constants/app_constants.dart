/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Aqistat';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Living Weather Intelligence';

  // AQI Scales by country
  static const Map<String, String> countryAqiScale = {
    'US': 'EPA',
    'IN': 'NAQI',
    'CN': 'MEE',
    'GB': 'DEFRA',
    'AU': 'AUS',
    'KR': 'CAI',
    'JP': 'MOE',
    'DE': 'EAQI',
    'FR': 'EAQI',
    'IT': 'EAQI',
    'ES': 'EAQI',
    'NL': 'EAQI',
    'BE': 'EAQI',
    'SE': 'EAQI',
    'NO': 'EAQI',
    'DK': 'EAQI',
    'FI': 'EAQI',
    'PL': 'EAQI',
    'PT': 'EAQI',
    'AT': 'EAQI',
  };

  // Default fallback scale
  static const String defaultAqiScale = 'WAQI';

  // Notification channels
  static const String severeWeatherChannel = 'severe_weather';
  static const String dailyForecastChannel = 'daily_forecast';
  static const String aqiAlertChannel = 'aqi_alert';
  static const String umbrellaReminderChannel = 'umbrella_reminder';
  static const String uvAlertChannel = 'uv_alert';

  // Cache durations
  static const Duration weatherCacheDuration = Duration(minutes: 15);
  static const Duration aqiCacheDuration = Duration(minutes: 30);
  static const Duration forecastCacheDuration = Duration(hours: 1);
}
