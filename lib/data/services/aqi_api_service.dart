import 'package:dio/dio.dart';
import '../models/aqi_model.dart';
import '../../core/constants/api_constants.dart';
import 'cache_service.dart';

/// Service for fetching Air Quality data from WAQI API
/// Includes automatic caching to avoid hitting rate limits:
///   - AQI data: cached 30 minutes
class AqiApiService {
  final Dio _dio;
  final CacheService _cache;

  AqiApiService({Dio? dio, CacheService? cache})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: ApiConstants.connectionTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
            )),
        _cache = cache ?? CacheService();

  /// Get AQI data by geographic coordinates
  /// Returns cached data if available and fresh (< 30 min old)
  Future<AqiData> getAqiByLocation(double lat, double lon) async {
    // 1. Check cache first
    final cached = await _cache.getCachedAqi(lat, lon);
    if (cached != null) {
      // Cache hit! Return stored data without API call
      return AqiData.fromWaqiJson(cached);
    }

    // 2. Cache miss or expired — call API
    try {
      final response = await _dio.get(
        '${ApiConstants.waqiBaseUrl}/feed/geo:$lat;$lon/',
        queryParameters: {
          'token': ApiConstants.waqiApiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'ok') {
        throw AqiApiException('API returned error: ${data['data']}');
      }

      // 3. Store in cache for next time
      await _cache.cacheAqi(lat, lon, data);

      return AqiData.fromWaqiJson(data);
    } on DioException catch (e) {
      throw AqiApiException(
        'Failed to fetch AQI data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get AQI data by city name — uses location cache if coordinates known
  Future<AqiData> getAqiByCity(String city) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.waqiBaseUrl}/feed/$city/',
        queryParameters: {
          'token': ApiConstants.waqiApiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'ok') {
        throw AqiApiException('API returned error: ${data['data']}');
      }

      return AqiData.fromWaqiJson(data);
    } on DioException catch (e) {
      throw AqiApiException(
        'Failed to fetch AQI data: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Search AQI stations — NOT cached (user-driven)
  Future<List<AqiSearchResult>> searchStations(String keyword) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.waqiBaseUrl}/search/',
        queryParameters: {
          'token': ApiConstants.waqiApiKey,
          'keyword': keyword,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'ok') return [];

      return (data['data'] as List)
          .map((e) => AqiSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AqiApiException(
        'Failed to search stations: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Force refresh — clear cache and fetch fresh
  Future<AqiData> forceRefresh(double lat, double lon) async {
    await _cache.invalidateLocation(lat, lon);
    return getAqiByLocation(lat, lon);
  }
}

/// AQI station search result
class AqiSearchResult {
  final int uid;
  final String name;
  final double lat;
  final double lon;
  final int aqi;

  AqiSearchResult({
    required this.uid,
    required this.name,
    required this.lat,
    required this.lon,
    required this.aqi,
  });

  factory AqiSearchResult.fromJson(Map<String, dynamic> json) {
    final geo = json['station']?['geo'] as List?;
    return AqiSearchResult(
      uid: json['uid'] as int? ?? 0,
      name: json['station']?['name'] as String? ?? 'Unknown',
      lat: geo != null && geo.isNotEmpty ? (geo[0] as num).toDouble() : 0.0,
      lon: geo != null && geo.length > 1 ? (geo[1] as num).toDouble() : 0.0,
      aqi: int.tryParse(json['aqi']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Custom exception for AQI API errors
class AqiApiException implements Exception {
  final String message;
  final int? statusCode;

  AqiApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AqiApiException: $message (status: $statusCode)';
}
