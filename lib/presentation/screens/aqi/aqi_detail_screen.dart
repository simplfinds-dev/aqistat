import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/aqi_provider.dart';
import '../../../core/utils/aqi_utils.dart';
import '../../../data/models/aqi_model.dart';

/// AQI Detail Screen — Full air quality information with history chart
class AqiDetailScreen extends ConsumerWidget {
  const AqiDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final aqiScale = ref.watch(currentAqiScaleProvider);
    final historyAsync = ref.watch(aqiHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Air Quality',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: aqiAsync.when(
        data: (aqi) {
          if (aqi == null) {
            return const Center(
              child: Text(
                'No air quality data available for this location.',
                style: TextStyle(color: Colors.white60),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Main AQI Display ===
                _AqiMainDisplay(aqi: aqi, scale: aqiScale),

                const SizedBox(height: 24),

                // === Plain English Message ===
                _PlainEnglishCard(aqi: aqi.aqi),

                const SizedBox(height: 24),

                // === 7-Day History Chart ===
                historyAsync.when(
                  data: (history) => _AqiHistoryChart(history: history),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // === Pollutant Breakdown ===
                if (aqi.pollutants != null) _PollutantBreakdown(pollutants: aqi.pollutants!),

                const SizedBox(height: 24),

                // === Health Advice ===
                _HealthAdviceCard(aqi: aqi.aqi),

                const SizedBox(height: 24),

                // === Scale Information ===
                _ScaleInfoCard(scale: aqiScale),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}

/// Main AQI gauge display
class _AqiMainDisplay extends StatelessWidget {
  final AqiData aqi;
  final AqiScale scale;

  const _AqiMainDisplay({required this.aqi, required this.scale});

  @override
  Widget build(BuildContext context) {
    final color = AqiUtils.getAqiColor(aqi.aqi);
    final level = AqiUtils.getAqiLevel(aqi.aqi);
    final localValue = AqiUtils.convertToLocalScale(aqi.aqi, scale);
    final scaleName = AqiUtils.getScaleName(scale);
    final emoji = AqiUtils.getAqiEmoji(aqi.aqi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '$localValue',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scaleName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          // Color scale bar
          _AqiColorBar(currentValue: aqi.aqi),
          const SizedBox(height: 12),
          Text(
            'Station: ${aqi.stationName}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Horizontal AQI color scale bar
class _AqiColorBar extends StatelessWidget {
  final int currentValue;

  const _AqiColorBar({required this.currentValue});

  @override
  Widget build(BuildContext context) {
    final position = (currentValue / 500).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                _segment(const Color(0xFF4CAF50), 50 / 500),
                _segment(const Color(0xFFFFEB3B), 50 / 500),
                _segment(const Color(0xFFFF9800), 50 / 500),
                _segment(const Color(0xFFF44336), 50 / 500),
                _segment(const Color(0xFF9C27B0), 100 / 500),
                _segment(const Color(0xFF880E4F), 200 / 500),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment(-1 + position * 2, 0),
          child: Container(
            width: 2,
            height: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _segment(Color color, double fraction) {
    return Expanded(
      flex: (fraction * 100).round(),
      child: Container(color: color),
    );
  }
}

/// Plain English AQI message card
class _PlainEnglishCard extends StatelessWidget {
  final int aqi;

  const _PlainEnglishCard({required this.aqi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What this means',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AqiUtils.getAqiMessage(aqi),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 7-Day AQI History Chart
class _AqiHistoryChart extends StatelessWidget {
  final List<AqiHistoryEntry> history;

  const _AqiHistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day AQI Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 50,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) return const SizedBox();
                        return Text(
                          DateFormat('E').format(history[index].date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      history.length,
                      (i) => FlSpot(i.toDouble(), history[i].aqiValue.toDouble()),
                    ),
                    isCurved: true,
                    color: AqiUtils.getAqiColor(history.last.aqiValue),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AqiUtils.getAqiColor(spot.y.toInt()),
                        strokeWidth: 2,
                        strokeColor: Colors.white24,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AqiUtils.getAqiColor(history.last.aqiValue).withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: (history.map((e) => e.aqiValue).reduce((a, b) => a > b ? a : b) + 30).toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pollutant breakdown
class _PollutantBreakdown extends StatelessWidget {
  final AqiPollutants pollutants;

  const _PollutantBreakdown({required this.pollutants});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pollutant Levels',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          if (pollutants.pm25 != null) _PollutantRow('PM2.5', pollutants.pm25!),
          if (pollutants.pm10 != null) _PollutantRow('PM10', pollutants.pm10!),
          if (pollutants.o3 != null) _PollutantRow('O₃ (Ozone)', pollutants.o3!),
          if (pollutants.no2 != null) _PollutantRow('NO₂', pollutants.no2!),
          if (pollutants.so2 != null) _PollutantRow('SO₂', pollutants.so2!),
          if (pollutants.co != null) _PollutantRow('CO', pollutants.co!),
        ],
      ),
    );
  }
}

class _PollutantRow extends StatelessWidget {
  final String name;
  final double value;

  const _PollutantRow(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AqiUtils.getAqiColor(value.round()).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.round().toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AqiUtils.getAqiColor(value.round()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Health advice card
class _HealthAdviceCard extends StatelessWidget {
  final int aqi;

  const _HealthAdviceCard({required this.aqi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Health Advice',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AqiUtils.getHealthAdvice(aqi),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scale information card
class _ScaleInfoCard extends StatelessWidget {
  final AqiScale scale;

  const _ScaleInfoCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing ${AqiUtils.getScaleName(scale)} (range: ${AqiUtils.getScaleRange(scale)}) — auto-detected from your country.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
