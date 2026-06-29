import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/weather_helpers.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(currentWeatherProvider);
    final hourly = ref.watch(hourlyForecastProvider);
    final daily = ref.watch(dailyForecastProvider);
    return AnimatedBackground(
      conditionCode: w.conditionCode, windSpeed: w.windSpeed,
      child: SafeArea(child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(city: w.city)),
          SliverToBoxAdapter(child: _HeroTemp(w: w)),
          SliverToBoxAdapter(child: _AqiPill(aqi: w.aqi)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _Hourly(hourly: hourly)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _Details(w: w)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _Daily(daily: daily)),
          SliverToBoxAdapter(child: _Outfit(w: w)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      )),
    );
  }
}

class _Header extends StatelessWidget {
  final String city;
  const _Header({required this.city});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Row(children: [
      const Icon(Icons.location_on, color: AppColors.accent, size: 18),
      const SizedBox(width: 6),
      Text(city, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w600)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
        child: Text(DateFormat('EEE, d MMM').format(DateTime.now()), style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
      ),
    ]),
  );
}

class _HeroTemp extends StatelessWidget {
  final CurrentWeather w;
  const _HeroTemp({required this.w});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(children: [
      Text(WeatherHelpers.getWeatherEmoji(w.conditionCode), style: const TextStyle(fontSize: 56)),
      const SizedBox(height: 8),
      Text('${w.temp.round()}°', style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w100, color: AppColors.textWhite, height: 1.0, letterSpacing: -4)),
      const SizedBox(height: 4),
      Text(w.description[0].toUpperCase() + w.description.substring(1), style: const TextStyle(fontSize: 18, color: AppColors.textGrey)),
      const SizedBox(height: 8),
      Text('H:${w.tempMax.round()}°  L:${w.tempMin.round()}°  Feels ${w.feelsLike.round()}°', style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
    ]),
  );
}

class _AqiPill extends StatelessWidget {
  final int aqi;
  const _AqiPill({required this.aqi});
  @override
  Widget build(BuildContext context) {
    final color = AppColors.getAqiColor(aqi);
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('AQI $aqi', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(width: 6),
        Text('• ${WeatherHelpers.getAqiLevel(aqi)}', style: TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
      ]),
    ));
  }
}

class _Hourly extends StatelessWidget {
  final List<HourlyData> hourly;
  const _Hourly({required this.hourly});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hourly.length > 24 ? 24 : hourly.length,
      itemBuilder: (context, i) {
        final h = hourly[i]; final isNow = i == 0;
        return Container(
          width: 68, margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isNow ? AppColors.primary.withOpacity(0.15) : AppColors.glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isNow ? AppColors.primary.withOpacity(0.4) : AppColors.glassBorder),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isNow ? 'Now' : DateFormat('ha').format(h.time), style: TextStyle(fontSize: 11, color: isNow ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600)),
            Text(WeatherHelpers.getWeatherEmoji(h.conditionCode), style: const TextStyle(fontSize: 22)),
            Text('${h.temp.round()}°', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isNow ? AppColors.textWhite : AppColors.textGrey)),
          ]),
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
      Expanded(child: _Tile(icon: Icons.water_drop_outlined, label: 'Humidity', value: '${w.humidity}%')),
      const SizedBox(width: 12),
      Expanded(child: _Tile(icon: Icons.air, label: 'Wind', value: '${w.windSpeed.round()} km/h')),
      const SizedBox(width: 12),
      Expanded(child: _Tile(icon: Icons.wb_sunny_outlined, label: 'UV', value: w.uv.toStringAsFixed(1))),
    ]),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _Tile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.glassBorder)),
    child: Column(children: [
      Icon(icon, color: AppColors.textGrey, size: 20),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );
}

class _Daily extends StatelessWidget {
  final List<DailyData> daily;
  const _Daily({required this.daily});
  @override
  Widget build(BuildContext context) => GlassCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('7-DAY FORECAST', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 14),
      ...daily.map((d) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 42, child: Text(d.date.day == DateTime.now().day ? 'Today' : DateFormat('EEE').format(d.date), style: TextStyle(color: d.date.day == DateTime.now().day ? AppColors.textWhite : AppColors.textGrey, fontSize: 14))),
          const SizedBox(width: 8),
          Text(WeatherHelpers.getWeatherEmoji(d.conditionCode), style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text('${d.low.round()}°', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(width: 60, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: (d.high - d.low) / 20, backgroundColor: AppColors.glassWhite, valueColor: AlwaysStoppedAnimation(AppColors.primary.withOpacity(0.6))))),
          const SizedBox(width: 8),
          Text('${d.high.round()}°', style: const TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      )),
    ],
  ));
}

class _Outfit extends StatelessWidget {
  final CurrentWeather w;
  const _Outfit({required this.w});
  @override
  Widget build(BuildContext context) => GlassCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [Icon(Icons.checkroom, color: AppColors.accent, size: 18), SizedBox(width: 8), Text('WHAT TO WEAR', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5))]),
      const SizedBox(height: 12),
      Text(WeatherHelpers.getOutfitSuggestion(w.temp, w.rainProb, w.uv), style: const TextStyle(color: AppColors.textWhite, fontSize: 15, height: 1.6)),
    ],
  ));
}
