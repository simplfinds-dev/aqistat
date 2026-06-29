import '../config/env_config.dart';

class ApiConstants {
  ApiConstants._();

  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String openWeatherGeoUrl = 'https://api.openweathermap.org/geo/1.0';
  static const String waqiBaseUrl = 'https://api.waqi.info';

  // Keys are injected securely at build time, never hardcoded.
  static String get openWeatherApiKey => EnvConfig.openWeatherKey;
  static String get waqiApiKey => EnvConfig.waqiKey;

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const Duration weatherCacheDuration = Duration(minutes: 15);
  static const Duration aqiCacheDuration = Duration(minutes: 30);
  static const Duration forecastCacheDuration = Duration(hours: 1);
}
