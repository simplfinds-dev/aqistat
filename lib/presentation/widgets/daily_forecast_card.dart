import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/weather_model.dart';
import '../../core/utils/weather_utils.dart';

/// 7-Day forecast display
class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> days;
  final bool useFahrenheit;

  const DailyForecastList({
    super.key,
    required this.days,
    this.useFahrenheit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '7-Day Forecast',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: List.generate(
              days.length > 7 ? 7 : days.length,
              (index) => _DailyRow(
                forecast: days[index],
                useFahrenheit: useFahrenheit,
                isToday: index == 0,
                showDivider: index < (days.length > 7 ? 6 : days.length - 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyForecast forecast;
  final bool useFahrenheit;
  final bool isToday;
  final bool showDivider;

  const _DailyRow({
    required this.forecast,
    required this.useFahrenheit,
    required this.isToday,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final high = useFahrenheit
        ? WeatherUtils.celsiusToFahrenheit(forecast.tempMax)
        : forecast.tempMax;
    final low = useFahrenheit
        ? WeatherUtils.celsiusToFahrenheit(forecast.tempMin)
        : forecast.tempMin;
    final dayName = isToday
        ? 'Today'
        : DateFormat('EEE').format(forecast.dateTime);
    final emoji = WeatherUtils.getWeatherEmoji(forecast.conditionCode);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Day name
              SizedBox(
                width: 50,
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white.withOpacity(isToday ? 1.0 : 0.8),
                  ),
                ),
              ),
              // Rain probability
              SizedBox(
                width: 40,
                child: forecast.rainProbability > 0.1
                    ? Text(
                        '${(forecast.rainProbability * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.lightBlueAccent.withOpacity(0.8),
                        ),
                      )
                    : const SizedBox(),
              ),
              // Weather emoji
              SizedBox(
                width: 40,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const Spacer(),
              // Low temp
              SizedBox(
                width: 35,
                child: Text(
                  '${low.round()}°',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              // Temperature bar
              SizedBox(
                width: 80,
                child: _TemperatureBar(
                  low: low,
                  high: high,
                  minTemp: -10,
                  maxTemp: 45,
                ),
              ),
              const SizedBox(width: 8),
              // High temp
              SizedBox(
                width: 35,
                child: Text(
                  '${high.round()}°',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),
      ],
    );
  }
}

/// Gradient temperature range bar
class _TemperatureBar extends StatelessWidget {
  final double low;
  final double high;
  final double minTemp;
  final double maxTemp;

  const _TemperatureBar({
    required this.low,
    required this.high,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  Widget build(BuildContext context) {
    final range = maxTemp - minTemp;
    final start = ((low - minTemp) / range).clamp(0.0, 1.0);
    final end = ((high - minTemp) / range).clamp(0.0, 1.0);

    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment(start * 2 - 1, 0),
        widthFactor: (end - start).clamp(0.1, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getTempColor(low),
                _getTempColor(high),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Color _getTempColor(double temp) {
    if (temp < 0) return const Color(0xFF4FC3F7); // Icy blue
    if (temp < 10) return const Color(0xFF81D4FA); // Cool blue
    if (temp < 20) return const Color(0xFF80CBC4); // Teal
    if (temp < 25) return const Color(0xFFA5D6A7); // Green
    if (temp < 30) return const Color(0xFFFFD54F); // Yellow
    if (temp < 35) return const Color(0xFFFF8A65); // Orange
    return const Color(0xFFE57373); // Red
  }
}
