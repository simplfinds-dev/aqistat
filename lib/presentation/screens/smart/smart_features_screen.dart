import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/smart_features_provider.dart';
import '../../../core/utils/aqi_utils.dart';
import '../../../core/theme/app_colors.dart';

/// Smart Features Hub — What to Wear, UV, Pollen, Day Rating
class SmartFeaturesScreen extends ConsumerWidget {
  const SmartFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Smart Tips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Day Rating
            _DayRatingCard(),
            const SizedBox(height: 16),

            // What to Wear
            _WhatToWearCard(),
            const SizedBox(height: 16),

            // UV Safety
            _UvSafetyCard(),
            const SizedBox(height: 16),

            // Health & Pollen
            _HealthPollenCard(),
            const SizedBox(height: 16),

            // Umbrella Reminder
            _UmbrellaCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Day Rating Card
class _DayRatingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(dayRatingProvider);

    return ratingAsync.when(
      data: (rating) {
        if (rating == null) return const SizedBox.shrink();
        final color = _getDayRatingColor(rating.rating);

        return _FeatureCard(
          icon: Icons.today,
          iconColor: color,
          title: 'Day Rating: ${rating.label}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rating.score / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rating.explanation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${rating.score.round()}/100',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getDayRatingColor(DayRating rating) {
    switch (rating) {
      case DayRating.great: return AppColors.dayGreat;
      case DayRating.good: return AppColors.dayGood;
      case DayRating.fair: return AppColors.dayFair;
      case DayRating.poor: return AppColors.dayPoor;
      case DayRating.bad: return AppColors.dayBad;
    }
  }
}

/// What to Wear Card
class _WhatToWearCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearAsync = ref.watch(whatToWearProvider);

    return wearAsync.when(
      data: (suggestion) => _FeatureCard(
        icon: Icons.checkroom,
        iconColor: const Color(0xFF7B61FF),
        title: 'What to Wear',
        child: Text(
          suggestion,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
      loading: () => const _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// UV Safety Card
class _UvSafetyCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uvAsync = ref.watch(uvSafetyProvider);

    return uvAsync.when(
      data: (uv) {
        if (uv == null) return const SizedBox.shrink();
        final color = AppColors.getUvColor(uv.uvIndex);

        return _FeatureCard(
          icon: Icons.wb_sunny,
          iconColor: color,
          title: 'UV Index: ${uv.uvIndex.toStringAsFixed(1)} — ${uv.level}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uv.recommendation,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Sunburn time', value: '~${uv.sunburnMinutes} min unprotected'),
              _InfoRow(label: 'SPF recommendation', value: uv.spfRecommendation),
            ],
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Health & Pollen Tips Card
class _HealthPollenCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthTipsProvider);

    return healthAsync.when(
      data: (health) {
        if (health == null) return const SizedBox.shrink();

        return _FeatureCard(
          icon: Icons.local_florist,
          iconColor: const Color(0xFF66BB6A),
          title: 'Health & Pollen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Pollen', value: health.pollenLevel),
              _InfoRow(label: 'Humidity', value: health.humidityComfort),
              _InfoRow(label: 'Breathing', value: health.breathingAdvisory),
              if (health.tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...health.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Umbrella Reminder Card
class _UmbrellaCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final umbrellaAsync = ref.watch(umbrellaReminderProvider);

    return umbrellaAsync.when(
      data: (reminder) {
        if (reminder == null) {
          return _FeatureCard(
            icon: Icons.umbrella,
            iconColor: const Color(0xFF4FC3F7),
            title: 'Umbrella',
            child: Text(
              'No rain expected today — leave the umbrella at home!',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
            ),
          );
        }
        return _FeatureCard(
          icon: Icons.umbrella,
          iconColor: const Color(0xFF4FC3F7),
          title: 'Umbrella Reminder',
          child: Text(
            reminder,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Reusable feature card
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Info row helper
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder card
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}
