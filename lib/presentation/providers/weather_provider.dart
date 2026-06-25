import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/weather_model.dart';
import '../../data/models/location_model.dart';
import '../../data/services/weather_api_service.dart';
import '../../data/services/location_service.dart';

/// Weather API service provider
final weatherApiServiceProvider = Provider<WeatherApiService>((ref) {
  return WeatherApiService();
});

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Current selected location
final currentLocationProvider = StateNotifierProvider<CurrentLocationNotifier, AsyncValue<SavedLocation?>>((ref) {
  return CurrentLocationNotifier(ref.watch(locationServiceProvider));
});

/// Current weather data
final currentWeatherProvider = FutureProvider.autoDispose<WeatherData?>((ref) async {
  final location = ref.watch(currentLocationProvider);
  final weatherService = ref.watch(weatherApiServiceProvider);

  return location.when(
    data: (loc) async {
      if (loc == null) return null;
      return await weatherService.getCurrentWeather(loc.lat, loc.lon);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Hourly forecast (48 hours)
final hourlyForecastProvider = FutureProvider.autoDispose<List<HourlyForecast>>((ref) async {
  final location = ref.watch(currentLocationProvider);
  final weatherService = ref.watch(weatherApiServiceProvider);

  return location.when(
    data: (loc) async {
      if (loc == null) return [];
      final oneCall = await weatherService.getOneCallData(loc.lat, loc.lon);
      return oneCall.hourly;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Daily forecast (7 days)
final dailyForecastProvider = FutureProvider.autoDispose<List<DailyForecast>>((ref) async {
  final location = ref.watch(currentLocationProvider);
  final weatherService = ref.watch(weatherApiServiceProvider);

  return location.when(
    data: (loc) async {
      if (loc == null) return [];
      final oneCall = await weatherService.getOneCallData(loc.lat, loc.lon);
      return oneCall.daily;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Saved locations list
final savedLocationsProvider = FutureProvider<List<SavedLocation>>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getSavedLocations();
});

/// City search results
final citySearchProvider = FutureProvider.family<List<GeoLocation>, String>((ref, query) async {
  if (query.length < 2) return [];
  final weatherService = ref.watch(weatherApiServiceProvider);
  return await weatherService.searchCity(query);
});

/// Current location state notifier
class CurrentLocationNotifier extends StateNotifier<AsyncValue<SavedLocation?>> {
  final LocationService _locationService;

  CurrentLocationNotifier(this._locationService) : super(const AsyncValue.loading()) {
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final saved = await _locationService.getCurrentLocation();
      if (saved != null) {
        state = AsyncValue.data(saved);
      } else {
        await detectCurrentLocation();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Detect current location via GPS
  Future<void> detectCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final location = SavedLocation(
          id: LocationService.generateLocationId(position.latitude, position.longitude),
          name: 'Current Location',
          country: '',
          countryCode: '',
          lat: position.latitude,
          lon: position.longitude,
          isCurrent: true,
        );
        await _locationService.setCurrentLocation(location);
        state = AsyncValue.data(location);
      } else {
        // Default to a known location if GPS unavailable
        state = AsyncValue.data(SavedLocation(
          id: 'default',
          name: 'London',
          country: 'United Kingdom',
          countryCode: 'GB',
          lat: 51.5074,
          lon: -0.1278,
          isCurrent: false,
        ));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Set location manually
  Future<void> setLocation(SavedLocation location) async {
    await _locationService.setCurrentLocation(location);
    state = AsyncValue.data(location);
  }
}
