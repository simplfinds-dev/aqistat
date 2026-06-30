import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_helpers.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/aqi_gauge.dart';
import '../../widgets/temp_trend_chart.dart';
import '../../widgets/weather_icon.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherBundleProvider);
    final city = ref.watch(cityProvider);

    return AnimatedBackground(
      conditionCode: async.valueOrNull?.current.conditionCode,
      windSpeed: async.valueOrNull?.current.windSpeed ?? 0,
      child: SafeArea(
        child: async.when(
          loading: () => Column(
            children: [
              _Header(city: city),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text('Reading the sky...', style: TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          error: (e, _) => Column(
            children: [
              _Header(city: city),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 56),
                        const SizedBox(height: 16),
                        const Text('Could not load weather',
                            style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Check your internet, API key in env.json, or try another city.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(weatherBundleProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (bundle) {
            final w = bundle.current;
            final unit = ref.watch(settingsProvider).unit;
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.cardDark,
              onRefresh: () async => ref.invalidate(weatherBundleProvider),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _Header(city: w.city)),
                  SliverToBoxAdapter(child: _HeroTemp(w: w, unit: unit)),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(child: _Hourly(hourly: bundle.hourly, unit: unit)),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _TrendCard(hourly: bundle.hourly, unit: unit)),
                  SliverToBoxAdapter(child: _PrecipCard(hourly: bundle.hourly)),
                  SliverToBoxAdapter(child: _AqiCard(w: w)),
                  SliverToBoxAdapter(child: _UvCard(uv: w.uv)),
                  SliverToBoxAdapter(child: _DayRating(w: w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: _Details(w: w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _Daily(daily: bundle.daily, unit: unit)),
                  SliverToBoxAdapter(child: _Outfit(w: w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String city;
  const _Header({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        child: Row(children: [
          const Icon(Icons.location_on, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(city,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.textGrey, size: 20),
            tooltip: 'Use my location',
            onPressed: () => _useMyLocation(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textGrey, size: 22),
            onPressed: () => _searchCity(context, ref),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder)),
            child: Text(DateFormat('EEE, d MMM').format(DateTime.now()),
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textGrey, size: 22),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ]),
      );

  void _searchCity(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Search City', style: TextStyle(color: AppColors.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: const InputDecoration(
                hintText: 'e.g. London, Tokyo, Mumbai',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              onSubmitted: (v) => _apply(ctx, ref, v),
            ),
            const SizedBox(height: 16),
            Consumer(builder: (context, ref2, _) {
              final recent =
                  ref2.watch(recentCitiesProvider).valueOrNull ?? const <String>[];
              if (recent.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECENT',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recent
                        .map((c) => ActionChip(
                              label: Text(c,
                                  style: const TextStyle(
                                      color: AppColors.textWhite, fontSize: 13)),
                              backgroundColor: AppColors.glassWhite,
                              side: const BorderSide(color: AppColors.glassBorder),
                              onPressed: () => _apply(ctx, ref, c),
                            ))
                        .toList(),
                  ),
                ],
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _apply(ctx, ref, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext ctx, WidgetRef ref, String value) {
    final v = value.trim();
    if (v.isNotEmpty) ref.read(cityProvider.notifier).setCity(v);
    Navigator.pop(ctx);
  }

  Future<void> _useMyLocation(BuildContext context, WidgetRef ref) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (context.mounted) {
          _msg(context, 'Location is off',
              'Please turn on location services on your device, then try again.');
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          _msg(context, 'Permission needed',
              'Location permission is required to use your current location. You can still search for a city.');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      ref.read(coordsProvider.notifier).state = (pos.latitude, pos.longitude);
    } catch (_) {
      if (context.mounted) {
        _msg(context, 'Could not locate you',
            'Something went wrong getting your location. Try again or search for a city.');
      }
    }
  }

  void _msg(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(title,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 17)),
        content: Text(body, style: const TextStyle(color: AppColors.textGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _HeroTemp extends StatelessWidget {
  final CurrentWeather w;
  final TempUnit unit;
  const _HeroTemp({required this.w, required this.unit});
  @override
  Widget build(BuildContext context) {
    final desc = w.description.isEmpty
        ? ''
        : w.description[0].toUpperCase() + w.description.substring(1);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E7BFF), Color(0xFF6C63FF), Color(0xFF4364F7)],
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${convertTemp(w.temp, unit).round()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                            letterSpacing: -2)),
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('°',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w300)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    'H:${tempLabel(w.tempMax, unit)}   L:${tempLabel(w.tempMin, unit)}   Feels ${tempLabel(w.feelsLike, unit)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.28), blurRadius: 34),
              ],
            ),
            child: WeatherIcon(conditionCode: w.conditionCode, size: 92),
          ),
        ],
      ),
    );
  }
}

class _AqiCard extends StatelessWidget {
  final CurrentWeather w;
  const _AqiCard({required this.w});
  @override
  Widget build(BuildContext context) {
    if (w.aqi <= 0) return const SizedBox.shrink();
    final color = AppColors.getAqiColor(w.aqi);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAqiSheet(context, w),
      child: GlassCard(
        child: Row(
          children: [
            AqiGauge(aqi: w.aqi, size: 132),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AIR QUALITY',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(WeatherHelpers.getAqiLevel(w.aqi),
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                      w.dominantPollutant.isNotEmpty
                          ? 'Main pollutant: ${WeatherHelpers.pollutantName(w.dominantPollutant)}'
                          : _aqiAdvice(w.aqi),
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 4),
                  const Text('Tap for pollutant details',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<HourlyData> hourly;
  final TempUnit unit;
  const _TrendCard({required this.hourly, required this.unit});
  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TEMPERATURE TREND',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 16),
            TempTrendChart(hourly: hourly, unit: unit),
          ],
        ),
      );
}

class _Hourly extends StatelessWidget {
  final List<HourlyData> hourly;
  final TempUnit unit;
  const _Hourly({required this.hourly, required this.unit});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: hourly.length,
          itemBuilder: (context, i) {
            final h = hourly[i];
            final isNow = i == 0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showDetailSheet(
                context,
                isNow ? 'Right now' : DateFormat('h a · EEE, d MMM').format(h.time),
                '${WeatherHelpers.getWeatherEmoji(h.conditionCode)}   ${tempLabel(h.temp, unit)}\n\nForecast temperature for this hour.',
              ),
              child: Container(
                width: 68,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isNow ? AppColors.primary.withOpacity(0.15) : AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isNow ? AppColors.primary.withOpacity(0.4) : AppColors.glassBorder),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(isNow ? 'Now' : DateFormat('ha').format(h.time),
                      style: TextStyle(fontSize: 11, color: isNow ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600)),
                  WeatherIcon(conditionCode: h.conditionCode, size: 30),
                  Text(tempLabel(h.temp, unit),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isNow ? AppColors.textWhite : AppColors.textGrey)),
                ]),
              ),
            );
          },
        ),
      );
}

class _Details extends StatelessWidget {
  final CurrentWeather w;
  const _Details({required this.w});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(
              child: _Tile(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${w.humidity}%',
                  onTap: () => _showDetailSheet(context, 'Humidity · ${w.humidity}%',
                      'The amount of water vapour in the air. Higher humidity makes it feel warmer and stickier than the actual temperature.'))),
          const SizedBox(width: 12),
          Expanded(
              child: _Tile(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '${w.windSpeed.round()} km/h',
                  onTap: () => _showDetailSheet(context, 'Wind · ${w.windSpeed.round()} km/h',
                      'Current wind speed near the surface. A stronger breeze makes it feel cooler than the thermometer reads.'))),
          const SizedBox(width: 12),
          Expanded(
              child: _Tile(
                  icon: Icons.umbrella_outlined,
                  label: 'Rain',
                  value: '${(w.rainProb * 100).round()}%',
                  onTap: () => _showDetailSheet(context, 'Chance of rain · ${(w.rainProb * 100).round()}%',
                      'The probability of precipitation right now. Consider carrying an umbrella when this is above ~40%.'))),
        ]),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, required this.value, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [
            Icon(icon, color: AppColors.textGrey, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
      );
}

class _Daily extends StatelessWidget {
  final List<DailyData> daily;
  final TempUnit unit;
  const _Daily({required this.daily, required this.unit});
  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7-DAY FORECAST',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            ...daily.map((d) {
              final isToday = d.date.day == DateTime.now().day;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showDetailSheet(
                  context,
                  isToday ? 'Today' : DateFormat('EEEE, d MMM').format(d.date),
                  '${WeatherHelpers.getWeatherEmoji(d.conditionCode)}\n\nHigh ${tempLabel(d.high, unit)}    ·    Low ${tempLabel(d.low, unit)}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(
                        width: 42,
                        child: Text(isToday ? 'Today' : DateFormat('EEE').format(d.date),
                            style: TextStyle(
                                color: isToday ? AppColors.textWhite : AppColors.textGrey, fontSize: 14))),
                    const SizedBox(width: 8),
                    WeatherIcon(conditionCode: d.conditionCode, size: 28),
                    const Spacer(),
                    Text(tempLabel(d.low, unit), style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 60,
                        height: 4,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                                value: ((d.high - d.low) / 20).clamp(0.05, 1.0),
                                backgroundColor: AppColors.glassWhite,
                                valueColor: AlwaysStoppedAnimation(AppColors.primary.withOpacity(0.6))))),
                    const SizedBox(width: 8),
                    Text(tempLabel(d.high, unit), style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
          ],
        ),
      );
}

class _Outfit extends StatelessWidget {
  final CurrentWeather w;
  const _Outfit({required this.w});
  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.checkroom, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text('WHAT TO WEAR',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5))
            ]),
            const SizedBox(height: 12),
            Text(WeatherHelpers.getOutfitSuggestion(w.temp, w.rainProb, w.uv),
                style: const TextStyle(color: AppColors.textWhite, fontSize: 15, height: 1.6)),
          ],
        ),
      );
}


/// Health guidance text for a given US AQI value.
String _aqiAdvice(int aqi) {
  if (aqi <= 50) return 'Air quality is great — perfect for outdoor activities.';
  if (aqi <= 100) return 'Acceptable. Unusually sensitive people should limit long periods of outdoor exertion.';
  if (aqi <= 150) return 'Sensitive groups (children, the elderly, and people with asthma) should cut back on prolonged outdoor exertion.';
  if (aqi <= 200) return 'Everyone may begin to feel effects. Limit time outdoors and wear a mask if you are sensitive.';
  if (aqi <= 300) return 'Health alert — avoid outdoor exertion and keep windows closed.';
  return 'Hazardous. Stay indoors and use air purification if possible.';
}

/// Shared bottom sheet used by the tappable cards on the home screen.
void _showDetailSheet(BuildContext context, String title, String body, {Color? accent}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardDark,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(title,
                style: TextStyle(
                    color: accent ?? AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(body,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    ),
  );
}


/// A computed "day rating" from temperature comfort, rain, air quality
/// and wind — gives the user a quick at-a-glance verdict.
class _DayRating extends StatelessWidget {
  final CurrentWeather w;
  const _DayRating({required this.w});

  @override
  Widget build(BuildContext context) {
    double score = 100;
    final t = w.temp; // comfort logic stays in Celsius
    if (t < 0 || t > 38) {
      score -= 45;
    } else if (t < 8 || t > 32) {
      score -= 25;
    } else if (t < 14 || t > 28) {
      score -= 10;
    }
    score -= w.rainProb.clamp(0, 1) * 35;
    final a = w.aqi;
    if (a > 200) {
      score -= 40;
    } else if (a > 150) {
      score -= 28;
    } else if (a > 100) {
      score -= 16;
    } else if (a > 50) {
      score -= 6;
    }
    if (w.windSpeed > 40) {
      score -= 15;
    } else if (w.windSpeed > 25) {
      score -= 7;
    }
    final s = score.clamp(0, 100).round();
    final label = s >= 80
        ? 'Great day'
        : s >= 60
            ? 'Good day'
            : s >= 40
                ? 'Fair day'
                : 'Tough day';
    final color = s >= 80
        ? AppColors.aqiGood
        : s >= 60
            ? AppColors.aqiModerate
            : s >= 40
                ? AppColors.warning
                : AppColors.aqiUnhealthy;

    final reasons = <String>[];
    if (w.rainProb > 0.4) reasons.add('rain likely');
    if (a > 100) reasons.add('poor air quality');
    if (t > 32) {
      reasons.add('it\'s hot');
    } else if (t < 8) {
      reasons.add('it\'s cold');
    }
    if (w.windSpeed > 25) reasons.add('quite windy');
    final reason = reasons.isEmpty
        ? 'Pleasant conditions all round.'
        : 'Heads up: ${reasons.join(', ')}.';

    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: s / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.glassWhite,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text('$s',
                    style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DAY RATING',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        color: color, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(reason,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Rich AQI bottom sheet: level, advice, dominant pollutant and a breakdown
/// of individual pollutant sub-indices.
void _showAqiSheet(BuildContext context, CurrentWeather w) {
  final color = AppColors.getAqiColor(w.aqi);
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Text('AQI ${w.aqi}',
                    style: TextStyle(
                        color: color, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(WeatherHelpers.getAqiLevel(w.aqi),
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_aqiAdvice(w.aqi),
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 14, height: 1.6)),
            if (w.dominantPollutant.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Main pollutant: ${WeatherHelpers.pollutantName(w.dominantPollutant)}',
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
            if (w.pollutants.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('POLLUTANTS',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...w.pollutants.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 140,
                            child: Text(WeatherHelpers.pollutantName(e.key),
                                style: const TextStyle(
                                    color: AppColors.textGrey, fontSize: 13))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (e.value / 300).clamp(0.02, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.glassWhite,
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.getAqiColor(e.value.round())),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 34,
                          child: Text(e.value.round().toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Hourly precipitation probability as a small bar chart.
class _PrecipCard extends StatelessWidget {
  final List<HourlyData> hourly;
  const _PrecipCard({required this.hourly});
  @override
  Widget build(BuildContext context) {
    final items = hourly.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final hasRain = items.any((h) => h.rainProb > 0.05);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('PRECIPITATION',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const Spacer(),
              if (!hasRain)
                const Text('No rain expected',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((h) {
                final p = h.rainProb.clamp(0.0, 1.0);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${(p * 100).round()}%',
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 9)),
                      const SizedBox(height: 4),
                      Container(
                        height: 6 + 52 * p,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(DateFormat('ha').format(h.time),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 9)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


/// UV index card with level + sun-protection advice (live data from Open-Meteo).
class _UvCard extends StatelessWidget {
  final double uv;
  const _UvCard({required this.uv});
  @override
  Widget build(BuildContext context) {
    final v = uv;
    final level = v < 3
        ? 'Low'
        : v < 6
            ? 'Moderate'
            : v < 8
                ? 'High'
                : v < 11
                    ? 'Very High'
                    : 'Extreme';
    final color = v < 3
        ? AppColors.aqiGood
        : v < 6
            ? AppColors.aqiModerate
            : v < 8
                ? AppColors.warning
                : v < 11
                    ? AppColors.aqiUnhealthy
                    : AppColors.aqiVeryUnhealthy;
    final advice = v < 3
        ? 'Minimal protection needed — enjoy the outdoors.'
        : v < 6
            ? 'Wear sunglasses; use SPF 30 if out for a while.'
            : v < 8
                ? 'Seek shade around midday — sunscreen + hat.'
                : v < 11
                    ? 'Extra protection essential; avoid sun 10am–4pm.'
                    : 'Take all precautions — unprotected skin burns fast.';

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Text(v.toStringAsFixed(v >= 10 ? 0 : 1),
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UV INDEX',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text(level,
                    style: TextStyle(
                        color: color, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(advice,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
