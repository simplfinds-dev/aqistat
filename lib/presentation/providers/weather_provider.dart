import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

enum TempUnit { celsius, fahrenheit }
class AppSettings {
  final TempUnit unit; final ThemeMode themeMode;
  const AppSettings({this.unit = TempUnit.celsius, this.themeMode = ThemeMode.dark});
}
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());
final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());
  void toggleUnit() => state = AppSettings(
    unit: state.unit == TempUnit.celsius ? TempUnit.fahrenheit : TempUnit.celsius, themeMode: state.themeMode);
}

class CurrentWeather {
  final double temp, feelsLike, tempMin, tempMax, windSpeed, windDeg, rainProb, uv;
  final int humidity, conditionCode, aqi;
  final String condition, description, city;
  const CurrentWeather({required this.temp, required this.feelsLike, required this.tempMin, required this.tempMax,
    required this.humidity, required this.windSpeed, required this.windDeg, required this.conditionCode,
    required this.condition, required this.description, required this.aqi, required this.city,
    required this.rainProb, required this.uv});
}

class HourlyData {
  final DateTime time; final double temp, rainProb; final int conditionCode;
  const HourlyData({required this.time, required this.temp, required this.conditionCode, required this.rainProb});
}

class DailyData {
  final DateTime date; final double high, low, rainProb; final int conditionCode;
  const DailyData({required this.date, required this.high, required this.low, required this.conditionCode, required this.rainProb});
}

final currentWeatherProvider = Provider<CurrentWeather>((ref) => const CurrentWeather(
  temp: 24, feelsLike: 26, tempMin: 19, tempMax: 28, humidity: 62, windSpeed: 14, windDeg: 220,
  conditionCode: 801, condition: 'Clouds', description: 'few clouds', aqi: 72, city: 'New Delhi', rainProb: 0.2, uv: 7.3));

final hourlyForecastProvider = Provider<List<HourlyData>>((ref) {
  final now = DateTime.now();
  return List.generate(24, (i) => HourlyData(time: now.add(Duration(hours: i)),
    temp: 22 + (6 * (0.5 - (i - 12).abs() / 12.0)), conditionCode: i > 14 && i < 18 ? 500 : 800, rainProb: i > 14 && i < 18 ? 0.7 : 0.1));
});

final dailyForecastProvider = Provider<List<DailyData>>((ref) {
  final now = DateTime.now();
  return List.generate(7, (i) => DailyData(date: now.add(Duration(days: i)),
    high: 26 + (i % 3) * 2.0, low: 18 + (i % 2) * 1.5, conditionCode: [800, 801, 802, 500, 800, 801, 500][i], rainProb: [0.1, 0.2, 0.3, 0.8, 0.05, 0.15, 0.6][i]));
});
