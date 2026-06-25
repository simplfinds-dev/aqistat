import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weather_provider.dart';
import '../../providers/aqi_provider.dart';
import '../../providers/smart_features_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/living_canvas.dart';
import '../../widgets/hourly_timeline.dart';
import '../../widgets/daily_forecast_card.dart';
import '../../widgets/aqi_badge.dart';
import '../../../core/utils/human_language.dart';
import '../../../core/utils/weather_utils.dart';

/// Main home screen — The "Glance" view
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final hourlyAsync = ref.watch(hourlyForecastProvider);
    final dailyAsync = ref.watch(dailyForecastProvider);
    final aqiAsync = ref.watch(currentAqiProvider);
    final aqiScale = ref.watch(currentAqiScaleProvider);
    final settings = ref.watch(settingsProvider);
    final useFahrenheit = settings.temperatureUnit == TemperatureUnit.fahrenheit;

    return weatherAsync.when(
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(error: error.toString()),
      data: (weather) {
        if (weather == null) return const _LoadingState();

        return LivingCanvas(
          condition: weather.condition,
          windSpeed: weather.windSpeedKmh,
          clouds: weather.clouds,
          humidity: weather.humidity,
          isDay: weather.isDay,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentWeatherProvider);
                ref.invalidate(hourlyForecastProvider);
                ref.invalidate(dailyForecastProvider);
                ref.invalidate(currentAqiProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: _LocationTitle(
                      cityName: weather.cityName,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => _openLocationSearch(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => _openSettings(context),
                      ),
                    ],
                  ),

                  // Main Content
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // === THE GLANCE: Temperature + Condition ===
                        _CurrentWeatherSection(
                          weather: weather,
                          useFahrenheit: useFahrenheit,
                        ),

                        const SizedBox(height: 16),

                        // === Human Language Summary ===
                        _HumanSummary(weather: weather),

                        const SizedBox(height: 16),

                        // === AQI Badge ===
                        aqiAsync.when(
                          data: (aqi) => aqi != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: AqiBadge(
                                    aqiValue: aqi.aqi,
                                    scale: aqiScale,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // === Day Rating ===
                        _DayRatingSection(),

                        const SizedBox(height: 24),

                        // === Hourly Timeline ===
                        hourlyAsync.when(
                          data: (hourly) => HourlyTimeline(
                            hours: hourly,
                            useFahrenheit: useFahrenheit,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // === 7-Day Forecast ===
                        dailyAsync.when(
                          data: (daily) => DailyForecastList(
                            days: daily,
                            useFahrenheit: useFahrenheit,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // === Quick Smart Features ===
                        _SmartFeaturesSection(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openLocationSearch(BuildContext context) {
    // Navigate to location search screen
    Navigator.of(context).pushNamed('/search');
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}

/// Location title in app bar
class _LocationTitle extends StatelessWidget {
  final String cityName;

  const _LocationTitle({required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        Text(
          cityName.isNotEmpty ? cityName : 'Loading...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Main current weather display
class _CurrentWeatherSection extends StatelessWidget {
  final dynamic weather;
  final bool useFahrenheit;

  const _CurrentWeatherSection({
    required this.weather,
    required this.useFahrenheit,
  });

  @override
  Widget build(BuildContext context) {
    final temp = useFahrenheit
        ? WeatherUtils.celsiusToFahrenheit(weather.tempCelsius)
        : weather.tempCelsius;
    final feelsLike = useFahrenheit
        ? WeatherUtils.celsiusToFahrenheit(weather.feelsLikeCelsius)
        : weather.feelsLikeCelsius;
    final emoji = WeatherUtils.getWeatherEmoji(weather.conditionCode);

    return Column(
      children: [
        // Giant temperature
        Text(
          '${temp.round()}°',
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w100,
            color: Colors.white,
            letterSpacing: -4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        // Condition with emoji
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              weather.conditionDescription.toString().capitalize(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Feels like
        Text(
          'Feels like ${feelsLike.round()}°',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Human-language weather summary
class _HumanSummary extends StatelessWidget {
  final dynamic weather;

  const _HumanSummary({required this.weather});

  @override
  Widget build(BuildContext context) {
    final summary = HumanLanguage.currentWeatherSummary(
      tempC: weather.tempCelsius,
      condition: weather.condition,
      feelsLike: weather.feelsLikeCelsius,
      humidity: weather.humidity,
      windKmh: weather.windSpeedKmh,
      rainProbability: weather.rain1h != null ? 0.8 : 0.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        summary,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white.withOpacity(0.75),
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Day Rating compact display
class _DayRatingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayRatingAsync = ref.watch(dayRatingProvider);

    return dayRatingAsync.when(
      data: (rating) {
        if (rating == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getDayRatingColor(rating.rating).withOpacity(0.2),
                  border: Border.all(
                    color: _getDayRatingColor(rating.rating),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    rating.label[0],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _getDayRatingColor(rating.rating),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rating.label} Day',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rating.explanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getDayRatingColor(DayRating rating) {
    switch (rating) {
      case DayRating.great:
        return const Color(0xFF66BB6A);
      case DayRating.good:
        return const Color(0xFF81C784);
      case DayRating.fair:
        return const Color(0xFFFFCA28);
      case DayRating.poor:
        return const Color(0xFFFF7043);
      case DayRating.bad:
        return const Color(0xFFEF5350);
    }
  }
}

/// Smart features quick access
class _SmartFeaturesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final umbrellaAsync = ref.watch(umbrellaReminderProvider);
    final whatToWearAsync = ref.watch(whatToWearProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Smart Tips',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 12),

        // What to Wear
        whatToWearAsync.when(
          data: (tip) => _SmartTipCard(
            icon: Icons.checkroom,
            title: 'What to Wear',
            message: tip,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Umbrella Reminder
        umbrellaAsync.when(
          data: (reminder) => reminder != null
              ? _SmartTipCard(
                  icon: Icons.umbrella,
                  title: 'Umbrella Reminder',
                  message: reminder,
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SmartTipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SmartTipCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state placeholder
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
            const Color(0xFF0f3460),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Reading the sky...',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Unable to fetch weather',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
