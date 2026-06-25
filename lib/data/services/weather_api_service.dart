import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../../core/constants/api_constants.dart';
import 'cache_service.dart';

/// Service for fetching weather data from OpenWeatherMap API
/// Includes automatic caching to avoid hitting rate limits:
///   - Current weather: cached 15 min
///   - Forecast (hourly + daily): cached 1 hour
///   - City search: not cached (user-triggered)
class WeatherApiService {
  final Dio _dio;
  final CacheService _cache;

  WeatherApiService({Dio? dio, CacheService? cache})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: ApiConstants.connectionTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
            )),
        _cache = cache ?? CacheService();

  /// Get current weather for a location
  /// Returns cached data if available and fresh (< 15 min old)
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    // 1. Check cache first
    final cached = await _cache.getCachedWeather(lat, lon);
    if (cached != null) {
      // Cache hit! Return stored data without API call
      return WeatherData.fromOpenWeatherJson(cached);
    }

    // 2. Cache miss or expired — call API
    try {
      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': ApiConstants.openWeatherApiKey,
        },
      );

      // 3. Store in cache for next time
      await _cache.cacheWeather(lat, lon, response.data as Map<String, dynamic>);

      return WeatherData.fromOpenWeatherJson(response.data);
    } on DioException catch (e) {
      // 4. If API fails, try returning stale cache (offline mode)
      final stale = await _cache.getStaleWeather(lat, lon);
      if (stale != null) {
        return WeatherData.fromOpenWeatherJson(stale);
      }
      throw WeatherApiException(
        'Failed to fetch current weather: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get One Call API data (current + hourly + daily)
  /// Returns cached data if available and fresh (< 1 hour old)
  Future<OneCallResponse> getOneCallData(double lat, double lon) async {
    // 1. Check cache first
    final cached = await _cache.getCachedHourlyForecast(lat, lon);
    if (cached != null) {
      // Cache hit!
      return OneCallResponse.fromJson(cached);
    }

    // 2. Cache miss — call API
    try {
      final response = await _dio.get(
        '${ApiConstants.openWeatherBaseUrl}/onecall',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': ApiConstants.openWeatherApiKey,
          'exclude': 'minutely,alerts',
        },
      );

      // 3. Store in cache
      await _cache.cacheHourlyForecast(lat, lon, response.data as Map<String, dynamic>);

      return OneCallResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw WeatherApiException(
        'Failed to fetch forecast data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Search for cities by name — NOT cached (user-driven, low frequency)
  Future<List<GeoLocation>> searchCity(String query) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.openWeatherGeoUrl}/direct',
        queryParameters: {
          'q': query,
          'limit': 5,
          'appid': ApiConstants.openWeatherApiKey,
        },
      );
      return (response.data as List)
          .map((e) => GeoLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw WeatherApiException(
        'Failed to search cities: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Reverse geocode (lat/lon to city name) — NOT cached
  Future<GeoLocation?> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.openWeatherGeoUrl}/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'limit': 1,
          'appid': ApiConstants.openWeatherApiKey,
        },
      );
      final list = response.data as List;
      if (list.isEmpty) return null;
      return GeoLocation.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw WeatherApiException(
        'Failed to reverse geocode: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Force refresh — clear cache and fetch fresh data
  Future<WeatherData> forceRefresh(double lat, double lon) async {
    await _cache.invalidateLocation(lat, lon);
    return getCurrentWeather(lat, lon);
  }

  /// Get when data was last fetched (for "Updated X min ago" display)
  Future<DateTime?> getLastUpdated(double lat, double lon) async {
    return await _cache.getWeatherLastUpdated(lat, lon);
  }
}

/// One Call API response containing all weather data
class OneCallResponse {
  final double lat;
  final double lon;
  final String timezone;
  final WeatherData? current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  OneCallResponse({
    required this.lat,
    required this.lon,
    required this.timezone,
    this.current,
    required this.hourly,
    required this.daily,
  });

  factory OneCallResponse.fromJson(Map<String, dynamic> json) {
    return OneCallResponse(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      hourly: (json['hourly'] as List?)
              ?.map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      daily: (json['daily'] as List?)
              ?.map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Geocoding result
class GeoLocation {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  GeoLocation({
    required this.name,
    this.state,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  String get displayName {
    if (state != null && state!.isNotEmpty) {
      return '$name, $state, $country';
    }
    return '$name, $country';
  }
}

/// Custom exception for weather API errors
class WeatherApiException implements Exception {
  final String message;
  final int? statusCode;

  WeatherApiException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherApiException: $message (status: $statusCode)';
}
