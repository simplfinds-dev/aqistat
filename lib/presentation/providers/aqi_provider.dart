import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/aqi_model.dart';
import '../../data/services/aqi_api_service.dart';
import '../../core/utils/aqi_utils.dart';
import 'weather_provider.dart';

/// AQI API service provider
final aqiApiServiceProvider = Provider<AqiApiService>((ref) {
  return AqiApiService();
});

/// Current AQI data
final currentAqiProvider = FutureProvider.autoDispose<AqiData?>((ref) async {
  final location = ref.watch(currentLocationProvider);
  final aqiService = ref.watch(aqiApiServiceProvider);

  return location.when(
    data: (loc) async {
      if (loc == null) return null;
      return await aqiService.getAqiByLocation(loc.lat, loc.lon);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// AQI scale for current country
final currentAqiScaleProvider = Provider<AqiScale>((ref) {
  final location = ref.watch(currentLocationProvider);
  return location.when(
    data: (loc) {
      if (loc == null) return AqiScale.waqi;
      return AqiUtils.getScaleForCountry(loc.countryCode);
    },
    loading: () => AqiScale.waqi,
    error: (_, __) => AqiScale.waqi,
  );
});

/// 7-day AQI history
final aqiHistoryProvider = FutureProvider.autoDispose<List<AqiHistoryEntry>>((ref) async {
  final aqiData = ref.watch(currentAqiProvider);

  return aqiData.when(
    data: (data) {
      if (data?.forecast == null) return _generateMockHistory(data?.aqi ?? 50);
      // Use forecast data for history
      return data!.forecast!.pm25
          .take(7)
          .map((entry) => AqiHistoryEntry(date: entry.date, aqiValue: entry.avg))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Generate placeholder history when real data isn't available
List<AqiHistoryEntry> _generateMockHistory(int currentAqi) {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final date = now.subtract(Duration(days: 6 - index));
    // Slight variation around current value
    final variation = ((index * 7) % 30) - 15;
    final value = (currentAqi + variation).clamp(0, 500);
    return AqiHistoryEntry(date: date, aqiValue: value);
  });
}
