import 'package:flutter/material.dart';
import '../../core/utils/weather_helpers.dart';

/// Renders a 3D weather PNG from assets/icons/weather/ based on the
/// OpenWeatherMap condition code. If the asset is missing, it gracefully
/// falls back to the matching emoji so the build/UI never breaks.
class WeatherIcon extends StatelessWidget {
  final int conditionCode;
  final double size;
  const WeatherIcon({super.key, required this.conditionCode, required this.size});

  String get _name {
    final c = conditionCode;
    if (c >= 200 && c < 300) return 'thunderstorm';
    if (c >= 300 && c < 400) return 'rain'; // drizzle -> rain
    if (c >= 500 && c < 600) return 'rain';
    if (c >= 600 && c < 700) return 'snow';
    if (c >= 700 && c < 800) return 'mist';
    if (c == 800) return 'clear';
    if (c == 801 || c == 802) return 'partly_cloudy';
    return 'cloudy';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/weather/$_name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        WeatherHelpers.getWeatherEmoji(conditionCode),
        style: TextStyle(fontSize: size * 0.82),
      ),
    );
  }
}
