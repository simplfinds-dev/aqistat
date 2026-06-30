import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env_config.dart';

// ===== SETTINGS =====
enum TempUnit { celsius, fahrenheit }

class AppSettings {
  final TempUnit unit;
  final ThemeMode themeMode;
  const AppSettings({this.unit = TempUnit.celsius, this.themeMode = ThemeMode.dark});
  AppSettings copyWith({TempUnit? unit, ThemeMode? themeMode}) =>
      AppSettings(unit: unit ?? this.unit, themeMode: themeMode ?? this.themeMode);
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());
final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }
  static const _kUnit = 'pref_unit_fahrenheit';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kUnit) ?? false) {
      state = state.copyWith(unit: TempUnit.fahrenheit);
    }
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kUnit, state.unit == TempUnit.fahrenheit);
  }

  void toggleUnit() {
    state = state.copyWith(
        unit: state.unit == TempUnit.celsius ? TempUnit.fahrenheit : TempUnit.celsius);
    _persist();
  }

  void setTheme(ThemeMode m) => state = state.copyWith(themeMode: m);
}

/// Converts a Celsius value to the user's selected unit.
double convertTemp(double celsius, TempUnit unit) =>
    unit == TempUnit.fahrenheit ? celsius * 9 / 5 + 32 : celsius;

/// Rounded temperature string with a degree sign, in the selected unit.
String tempLabel(double celsius, TempUnit unit) =>
    '${convertTemp(celsius, unit).round()}°';

// ===== DATA MODELS =====
class CurrentWeather {
  final double temp, feelsLike, tempMin, tempMax, windSpeed, windDeg, rainProb, uv;
  final int humidity, conditionCode, aqi;
  final String condition, description, city;
  final String dominantPollutant;
  final Map<String, double> pollutants;
  const CurrentWeather({
    required this.temp, required this.feelsLike, required this.tempMin, required this.tempMax,
    required this.humidity, required this.windSpeed, required this.windDeg, required this.conditionCode,
    required this.condition, required this.description, required this.aqi, required this.city,
    required this.rainProb, required this.uv,
    this.dominantPollutant = '',
    this.pollutants = const {},
  });
}

class HourlyData {
  final DateTime time;
  final double temp, rainProb;
  final int conditionCode;
  const HourlyData({required this.time, required this.temp, required this.conditionCode, required this.rainProb});
}

class DailyData {
  final DateTime date;
  final double high, low, rainProb;
  final int conditionCode;
  const DailyData({required this.date, required this.high, required this.low, required this.conditionCode, required this.rainProb});
}

class WeatherBundle {
  final CurrentWeather current;
  final List<HourlyData> hourly;
  final List<DailyData> daily;
  const WeatherBundle({required this.current, required this.hourly, required this.daily});
}

// ===== SELECTED LOCATION =====
final coordsProvider = StateProvider<(double, double)?>((ref) => null);

final cityProvider =
    StateNotifierProvider<CityNotifier, String>((ref) => CityNotifier(ref));

class CityNotifier extends StateNotifier<String> {
  CityNotifier(this._ref) : super('New Delhi') {
    _load();
  }
  final Ref _ref;
  static const _kCity = 'pref_city';
  static const _kRecent = 'pref_recent_cities';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_kCity);
    if (c != null && c.trim().isNotEmpty) state = c;
  }

  /// Set the city from a search: clears any GPS coords, persists it as the
  /// last city, and records it in the recent list.
  Future<void> setCity(String city) async {
    final v = city.trim();
    if (v.isEmpty) return;
    _ref.read(coordsProvider.notifier).state = null;
    state = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCity, v);
    final recent = p.getStringList(_kRecent) ?? <String>[];
    recent.removeWhere((e) => e.toLowerCase() == v.toLowerCase());
    recent.insert(0, v);
    while (recent.length > 5) {
      recent.removeLast();
    }
    await p.setStringList(_kRecent, recent);
  }
}

final recentCitiesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(cityProvider); // re-read whenever the city changes
  final p = await SharedPreferences.getInstance();
  return p.getStringList('pref_recent_cities') ?? <String>[];
});

// ===== WEATHER SERVICE =====
final _dioProvider = Provider<Dio>((ref) => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    )));

final weatherBundleProvider = FutureProvider.autoDispose<WeatherBundle>((ref) async {
  final dio = ref.watch(_dioProvider);
  final city = ref.watch(cityProvider);
  final coords = ref.watch(coordsProvider);
  final owmKey = EnvConfig.openWeatherKey;
  final waqiKey = EnvConfig.waqiKey;

  if (owmKey.isEmpty) {
    throw Exception('Missing OpenWeatherMap API key. Add it to env.json.');
  }

  // Location params: GPS coordinates take priority over the city name.
  final Map<String, dynamic> locParams =
      coords != null ? {'lat': coords.$1, 'lon': coords.$2} : {'q': city};

  // 1) Current weather
  final cur = await dio.get(
    'https://api.openweathermap.org/data/2.5/weather',
    queryParameters: {...locParams, 'appid': owmKey, 'units': 'metric'},
  );
  final cd = cur.data as Map<String, dynamic>;
  final coord = cd['coord'] as Map<String, dynamic>;
  final lat = (coord['lat'] as num).toDouble();
  final lon = (coord['lon'] as num).toDouble();
  final weather0 = (cd['weather'] as List).first as Map<String, dynamic>;
  final main = cd['main'] as Map<String, dynamic>;
  final wind = cd['wind'] as Map<String, dynamic>? ?? {};

  // 2) AQI from WAQI (fallback to OWM air_pollution if needed)
  int aqi = 0;
  String dominantPollutant = '';
  final Map<String, double> pollutants = {};
  try {
    if (waqiKey.isNotEmpty) {
      final aq = await dio.get(
        'https://api.waqi.info/feed/geo:$lat;$lon/',
        queryParameters: {'token': waqiKey},
      );
      final ad = aq.data as Map<String, dynamic>;
      if (ad['status'] == 'ok') {
        final data = ad['data'] as Map<String, dynamic>;
        final v = data['aqi'];
        aqi = v is int ? v : int.tryParse('$v') ?? 0;
        dominantPollutant = (data['dominentpol'] as String?) ?? '';
        final iaqi = data['iaqi'];
        if (iaqi is Map) {
          for (final key in const ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co']) {
            final entry = iaqi[key];
            if (entry is Map && entry['v'] is num) {
              pollutants[key] = (entry['v'] as num).toDouble();
            }
          }
        }
      }
    }
  } catch (_) {
    aqi = 0;
  }

  // 3) Forecast (5 day / 3 hour)
  final fc = await dio.get(
    'https://api.openweathermap.org/data/2.5/forecast',
    queryParameters: {...locParams, 'appid': owmKey, 'units': 'metric'},
  );
  final fd = fc.data as Map<String, dynamic>;
  final list = (fd['list'] as List).cast<Map<String, dynamic>>();

  // hourly = next entries (3-hourly steps)
  final hourly = list.take(12).map((e) {
    final m = e['main'] as Map<String, dynamic>;
    final w = (e['weather'] as List).first as Map<String, dynamic>;
    return HourlyData(
      time: DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000),
      temp: (m['temp'] as num).toDouble(),
      conditionCode: w['id'] as int,
      rainProb: ((e['pop'] as num?)?.toDouble()) ?? 0,
    );
  }).toList();

  // daily = group by calendar day
  final Map<String, List<Map<String, dynamic>>> byDay = {};
  for (final e in list) {
    final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000);
    final key = '${dt.year}-${dt.month}-${dt.day}';
    byDay.putIfAbsent(key, () => []).add(e);
  }
  final daily = <DailyData>[];
  byDay.forEach((key, entries) {
    double hi = -100, lo = 100, pop = 0;
    int code = 800;
    for (final e in entries) {
      final m = e['main'] as Map<String, dynamic>;
      final t = (m['temp'] as num).toDouble();
      if (t > hi) hi = t;
      if (t < lo) lo = t;
      final p = ((e['pop'] as num?)?.toDouble()) ?? 0;
      if (p > pop) pop = p;
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000);
      if (dt.hour >= 11 && dt.hour <= 14) {
        code = (e['weather'] as List).first['id'] as int;
      }
    }
    final first = entries.first;
    daily.add(DailyData(
      date: DateTime.fromMillisecondsSinceEpoch((first['dt'] as int) * 1000),
      high: hi, low: lo, conditionCode: code, rainProb: pop,
    ));
  });

  final current = CurrentWeather(
    temp: (main['temp'] as num).toDouble(),
    feelsLike: (main['feels_like'] as num).toDouble(),
    tempMin: (main['temp_min'] as num).toDouble(),
    tempMax: (main['temp_max'] as num).toDouble(),
    humidity: (main['humidity'] as num).toInt(),
    windSpeed: ((wind['speed'] as num?)?.toDouble() ?? 0) * 3.6,
    windDeg: (wind['deg'] as num?)?.toDouble() ?? 0,
    conditionCode: weather0['id'] as int,
    condition: weather0['main'] as String,
    description: weather0['description'] as String,
    aqi: aqi,
    city: cd['name'] as String? ?? city,
    rainProb: hourly.isNotEmpty ? hourly.first.rainProb : 0,
    uv: 0,
    dominantPollutant: dominantPollutant,
    pollutants: pollutants,
  );

  return WeatherBundle(current: current, hourly: hourly, daily: daily.take(7).toList());
});
