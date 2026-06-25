import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Temperature unit
enum TemperatureUnit { celsius, fahrenheit }

/// App settings state
class AppSettings {
  final TemperatureUnit temperatureUnit;
  final ThemeMode themeMode;
  final bool severeWeatherAlerts;
  final bool aqiAlerts;
  final bool umbrellaReminders;
  final bool uvAlerts;
  final bool dailyForecast;
  final int aqiAlertThreshold; // AQI value that triggers alert
  final double uvAlertThreshold; // UV index that triggers alert

  const AppSettings({
    this.temperatureUnit = TemperatureUnit.celsius,
    this.themeMode = ThemeMode.system,
    this.severeWeatherAlerts = true,
    this.aqiAlerts = true,
    this.umbrellaReminders = true,
    this.uvAlerts = true,
    this.dailyForecast = true,
    this.aqiAlertThreshold = 100,
    this.uvAlertThreshold = 6.0,
  });

  AppSettings copyWith({
    TemperatureUnit? temperatureUnit,
    ThemeMode? themeMode,
    bool? severeWeatherAlerts,
    bool? aqiAlerts,
    bool? umbrellaReminders,
    bool? uvAlerts,
    bool? dailyForecast,
    int? aqiAlertThreshold,
    double? uvAlertThreshold,
  }) {
    return AppSettings(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      themeMode: themeMode ?? this.themeMode,
      severeWeatherAlerts: severeWeatherAlerts ?? this.severeWeatherAlerts,
      aqiAlerts: aqiAlerts ?? this.aqiAlerts,
      umbrellaReminders: umbrellaReminders ?? this.umbrellaReminders,
      uvAlerts: uvAlerts ?? this.uvAlerts,
      dailyForecast: dailyForecast ?? this.dailyForecast,
      aqiAlertThreshold: aqiAlertThreshold ?? this.aqiAlertThreshold,
      uvAlertThreshold: uvAlertThreshold ?? this.uvAlertThreshold,
    );
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Theme mode provider derived from settings
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Temperature unit provider
final temperatureUnitProvider = Provider<TemperatureUnit>((ref) {
  return ref.watch(settingsProvider).temperatureUnit;
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final unitIndex = prefs.getInt('temp_unit') ?? 0;
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final severeAlerts = prefs.getBool('severe_alerts') ?? true;
    final aqiAlerts = prefs.getBool('aqi_alerts') ?? true;
    final umbrella = prefs.getBool('umbrella_reminders') ?? true;
    final uv = prefs.getBool('uv_alerts') ?? true;
    final daily = prefs.getBool('daily_forecast') ?? true;
    final aqiThreshold = prefs.getInt('aqi_threshold') ?? 100;
    final uvThreshold = prefs.getDouble('uv_threshold') ?? 6.0;

    state = AppSettings(
      temperatureUnit: TemperatureUnit.values[unitIndex],
      themeMode: ThemeMode.values[themeIndex],
      severeWeatherAlerts: severeAlerts,
      aqiAlerts: aqiAlerts,
      umbrellaReminders: umbrella,
      uvAlerts: uv,
      dailyForecast: daily,
      aqiAlertThreshold: aqiThreshold,
      uvAlertThreshold: uvThreshold,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temp_unit', state.temperatureUnit.index);
    await prefs.setInt('theme_mode', state.themeMode.index);
    await prefs.setBool('severe_alerts', state.severeWeatherAlerts);
    await prefs.setBool('aqi_alerts', state.aqiAlerts);
    await prefs.setBool('umbrella_reminders', state.umbrellaReminders);
    await prefs.setBool('uv_alerts', state.uvAlerts);
    await prefs.setBool('daily_forecast', state.dailyForecast);
    await prefs.setInt('aqi_threshold', state.aqiAlertThreshold);
    await prefs.setDouble('uv_threshold', state.uvAlertThreshold);
  }

  void setTemperatureUnit(TemperatureUnit unit) {
    state = state.copyWith(temperatureUnit: unit);
    _saveSettings();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void toggleSevereWeatherAlerts(bool value) {
    state = state.copyWith(severeWeatherAlerts: value);
    _saveSettings();
  }

  void toggleAqiAlerts(bool value) {
    state = state.copyWith(aqiAlerts: value);
    _saveSettings();
  }

  void toggleUmbrellaReminders(bool value) {
    state = state.copyWith(umbrellaReminders: value);
    _saveSettings();
  }

  void toggleUvAlerts(bool value) {
    state = state.copyWith(uvAlerts: value);
    _saveSettings();
  }

  void toggleDailyForecast(bool value) {
    state = state.copyWith(dailyForecast: value);
    _saveSettings();
  }

  void setAqiAlertThreshold(int value) {
    state = state.copyWith(aqiAlertThreshold: value);
    _saveSettings();
  }

  void setUvAlertThreshold(double value) {
    state = state.copyWith(uvAlertThreshold: value);
    _saveSettings();
  }
}
