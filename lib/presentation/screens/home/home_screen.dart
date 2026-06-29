import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_helpers.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/aqi_gauge.dart';
import '../../widgets/temp_trend_chart.dart';
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
            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.cardDark,
              onRefresh: () async => ref.invalidate(weatherBundleProvider),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _Header(city: w.city)),
                  SliverToBoxAdapter(child: _HeroTemp(w: w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(child: _Hourly(hourly: bundle.hourly)),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _TrendCard(hourly: bundle.hourly)),
                  SliverToBoxAdapter(child: _AqiCard(aqi: w.aqi)),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: _Details(w: w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(child: _Daily(daily: bundle.daily)),
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
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: const InputDecoration(
            hintText: 'e.g. London, Tokyo, Mumbai',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
          onSubmitted: (v) => _apply(ctx, ref, v),
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
    if (v.isNotEmpty) ref.read(cityProvider.notifier).state = v;
    Navigator.pop(ctx);
  }
}

class _HeroTemp extends StatelessWidget {
  final CurrentWeather w;
  const _HeroTemp({required this.w});
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
                    Text('${w.temp.round()}',
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
                    'H:${w.tempMax.round()}°   L:${w.tempMin.round()}°   Feels ${w.feelsLike.round()}°',
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
            child: Text(WeatherHelpers.getWeatherEmoji(w.conditionCode),
                style: const TextStyle(fontSize: 78)),
          ),
        ],
      ),
    );
  }
}

class _AqiCard extends StatelessWidget {
  final int aqi;
  const _AqiCard({required this.aqi});
  @override
  Widget build(BuildContext context) {
    if (aqi <= 0) return const SizedBox.shrink();
    final color = AppColors.getAqiColor(aqi);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showDetailSheet(
        context,
        'Air Quality · AQI $aqi',
        '${WeatherHelpers.getAqiLevel(aqi)}\n\n${_aqiAdvice(aqi)}',
        accent: color,
      ),
      child: GlassCard(
        child: Row(
          children: [
            AqiGauge(aqi: aqi, size: 132),
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
                  Text(WeatherHelpers.getAqiLevel(aqi),
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_aqiAdvice(aqi),
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12, height: 1.4)),
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
  const _TrendCard({required this.hourly});
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
            TempTrendChart(hourly: hourly),
          ],
        ),
      );
}

class _Hourly extends StatelessWidget {
  final List<HourlyData> hourly;
  const _Hourly({required this.hourly});
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
                '${WeatherHelpers.getWeatherEmoji(h.conditionCode)}   ${h.temp.round()}°\n\nForecast temperature for this hour.',
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
                  Text(WeatherHelpers.getWeatherEmoji(h.conditionCode), style: const TextStyle(fontSize: 22)),
                  Text('${h.temp.round()}°',
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
  const _Daily({required this.daily});
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
                  '${WeatherHelpers.getWeatherEmoji(d.conditionCode)}\n\nHigh ${d.high.round()}°    ·    Low ${d.low.round()}°',
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
                    Text(WeatherHelpers.getWeatherEmoji(d.conditionCode), style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    Text('${d.low.round()}°', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                    Text('${d.high.round()}°', style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
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
