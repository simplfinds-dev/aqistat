import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Cache service — stores API responses locally to avoid hitting rate limits
/// 
/// Cache durations:
/// - Current weather: 15 minutes
/// - Hourly/Daily forecast: 1 hour
/// - AQI data: 30 minutes
/// 
/// This means with normal usage:
/// - OpenWeatherMap: ~4 calls/hour instead of potentially 60+
/// - WAQI: ~2 calls/hour instead of potentially 60+
/// - A user opening the app 20 times/hour only makes 4 API calls total
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  // Cache keys
  static const String _currentWeatherPrefix = 'cache_weather_current_';
  static const String _hourlyForecastPrefix = 'cache_weather_hourly_';
  static const String _dailyForecastPrefix = 'cache_weather_daily_';
  static const String _aqiPrefix = 'cache_aqi_';
  static const String _timestampSuffix = '_timestamp';

  /// Get cached data if it's still valid (not expired)
  /// Returns null if cache is expired or doesn't exist
  Future<Map<String, dynamic>?> getCachedWeather(double lat, double lon) async {
    return _getCached(
      key: '$_currentWeatherPrefix${_locationKey(lat, lon)}',
      maxAge: AppConstants.weatherCacheDuration,
    );
  }

  /// Cache current weather response
  Future<void> cacheWeather(double lat, double lon, Map<String, dynamic> data) async {
    await _setCache(
      key: '$_currentWeatherPrefix${_locationKey(lat, lon)}',
      data: data,
    );
  }

  /// Get cached hourly forecast
  Future<Map<String, dynamic>?> getCachedHourlyForecast(double lat, double lon) async {
    return _getCached(
      key: '$_hourlyForecastPrefix${_locationKey(lat, lon)}',
      maxAge: AppConstants.forecastCacheDuration,
    );
  }

  /// Cache hourly forecast response
  Future<void> cacheHourlyForecast(double lat, double lon, Map<String, dynamic> data) async {
    await _setCache(
      key: '$_hourlyForecastPrefix${_locationKey(lat, lon)}',
      data: data,
    );
  }

  /// Get cached daily forecast
  Future<Map<String, dynamic>?> getCachedDailyForecast(double lat, double lon) async {
    return _getCached(
      key: '$_dailyForecastPrefix${_locationKey(lat, lon)}',
      maxAge: AppConstants.forecastCacheDuration,
    );
  }

  /// Cache daily forecast response
  Future<void> cacheDailyForecast(double lat, double lon, Map<String, dynamic> data) async {
    await _setCache(
      key: '$_dailyForecastPrefix${_locationKey(lat, lon)}',
      data: data,
    );
  }

  /// Get cached AQI data
  Future<Map<String, dynamic>?> getCachedAqi(double lat, double lon) async {
    return _getCached(
      key: '$_aqiPrefix${_locationKey(lat, lon)}',
      maxAge: AppConstants.aqiCacheDuration,
    );
  }

  /// Cache AQI response
  Future<void> cacheAqi(double lat, double lon, Map<String, dynamic> data) async {
    await _setCache(
      key: '$_aqiPrefix${_locationKey(lat, lon)}',
      data: data,
    );
  }

  /// Force refresh — clear all cache for a location
  Future<void> invalidateLocation(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final locKey = _locationKey(lat, lon);
    
    await prefs.remove('$_currentWeatherPrefix$locKey');
    await prefs.remove('$_currentWeatherPrefix$locKey$_timestampSuffix');
    await prefs.remove('$_hourlyForecastPrefix$locKey');
    await prefs.remove('$_hourlyForecastPrefix$locKey$_timestampSuffix');
    await prefs.remove('$_dailyForecastPrefix$locKey');
    await prefs.remove('$_dailyForecastPrefix$locKey$_timestampSuffix');
    await prefs.remove('$_aqiPrefix$locKey');
    await prefs.remove('$_aqiPrefix$locKey$_timestampSuffix');
  }

  /// Clear ALL cache
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get cache age for display ("Updated 5 min ago")
  Future<Duration?> getCacheAge(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString('$key$_timestampSuffix');
    if (timestampStr == null) return null;
    
    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return null;
    
    return DateTime.now().difference(timestamp);
  }

  /// Get "last updated" time for current weather
  Future<DateTime?> getWeatherLastUpdated(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_currentWeatherPrefix${_locationKey(lat, lon)}$_timestampSuffix';
    final timestampStr = prefs.getString(key);
    if (timestampStr == null) return null;
    return DateTime.tryParse(timestampStr);
  }

  /// Check if cache is stale (expired but data exists — for offline mode)
  Future<bool> hasStaleData(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_currentWeatherPrefix${_locationKey(lat, lon)}';
    return prefs.containsKey(key);
  }

  /// Get stale weather data (for offline/error fallback)
  Future<Map<String, dynamic>?> getStaleWeather(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_currentWeatherPrefix${_locationKey(lat, lon)}';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  // === PRIVATE METHODS ===

  /// Generate a location key from lat/lon (rounded to 2 decimal places for cache hits)
  String _locationKey(double lat, double lon) {
    return '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
  }

  /// Get cached data if not expired
  Future<Map<String, dynamic>?> _getCached({
    required String key,
    required Duration maxAge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    final timestampStr = prefs.getString('$key$_timestampSuffix');

    if (jsonStr == null || timestampStr == null) return null;

    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return null;

    // Check if cache has expired
    final age = DateTime.now().difference(timestamp);
    if (age > maxAge) return null; // Expired — return null to trigger API call

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Store data in cache with timestamp
  Future<void> _setCache({
    required String key,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setString('$key$_timestampSuffix', DateTime.now().toIso8601String());
  }
}
