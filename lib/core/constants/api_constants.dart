/// API Constants for all weather and AQI data sources
class ApiConstants {
  ApiConstants._();

  // OpenWeatherMap API
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/3.0';
  static const String openWeatherGeoUrl = 'https://api.openweathermap.org/geo/1.0';
  // Replace with your API key from https://openweathermap.org/api
  static const String openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';

  // WAQI (World Air Quality Index) API
  static const String waqiBaseUrl = 'https://api.waqi.info';
  // Replace with your API key from https://aqicn.org/data-platform/token/
  static const String waqiApiKey = 'YOUR_WAQI_API_KEY';

  // OpenUV API
  static const String openUvBaseUrl = 'https://api.openuv.io/api/v1';
  // Replace with your API key from https://www.openuv.io/
  static const String openUvApiKey = 'YOUR_OPENUV_API_KEY';

  // RainViewer (Free, no API key needed)
  static const String rainViewerBaseUrl = 'https://tilecache.rainviewer.com';
  static const String rainViewerApiUrl = 'https://api.rainviewer.com/public/weather-maps.json';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
