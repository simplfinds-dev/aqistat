import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/weather_model.dart';
import '../../core/utils/weather_utils.dart';

/// Hourly forecast timeline — "River of Time" horizontal scroll
class HourlyTimeline extends StatelessWidget {
  final List<HourlyForecast> hours;
  final bool useFahrenheit;

  const HourlyTimeline({
    super.key,
    required this.hours,
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
            'Next 24 Hours',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hours.length > 24 ? 24 : hours.length,
            itemBuilder: (context, index) {
              return _HourlyCard(
                forecast: hours[index],
                useFahrenheit: useFahrenheit,
                isNow: index == 0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HourlyCard extends StatelessWidget {
  final HourlyForecast forecast;
  final bool useFahrenheit;
  final bool isNow;

  const _HourlyCard({
    required this.forecast,
    required this.useFahrenheit,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    final temp = useFahrenheit
        ? WeatherUtils.celsiusToFahrenheit(forecast.tempCelsius)
        : forecast.tempCelsius;
    final timeStr = isNow ? 'Now' : DateFormat('ha').format(forecast.dateTime);
    final emoji = WeatherUtils.getWeatherEmoji(forecast.conditionCode);

    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isNow
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: isNow
            ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
              color: Colors.white.withOpacity(isNow ? 1.0 : 0.7),
            ),
          ),
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          Text(
            '${temp.round()}°',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(isNow ? 1.0 : 0.9),
            ),
          ),
          if (forecast.rainProbability > 0.1)
            Text(
              '${(forecast.rainProbability * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.lightBlueAccent.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
