import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/weather_helpers.dart';

/// A circular AQI gauge with a green→hazardous gradient arc and a marker dot
/// at the current value, with the number and level in the centre.
class AqiGauge extends StatelessWidget {
  final int aqi;
  final double size;
  const AqiGauge({super.key, required this.aqi, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getAqiColor(aqi);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(aqi),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AQI',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              Text('$aqi',
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.0)),
              Text(WeatherHelpers.getAqiLevel(aqi),
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int aqi;
  _GaugePainter(this.aqi);

  static const double _start = 0.75 * pi; // 135°, opens at the bottom
  static const double _sweep = 1.5 * pi; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 11.0;

    // Faint background track
    canvas.drawArc(
      rect, _start, _sweep, false,
      Paint()
        ..color = AppColors.glassWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Gradient scale arc
    final shader = const SweepGradient(
      startAngle: _start,
      endAngle: _start + _sweep,
      colors: [
        AppColors.aqiGood,
        AppColors.aqiModerate,
        AppColors.warning,
        AppColors.aqiUnhealthy,
        AppColors.aqiVeryUnhealthy,
        AppColors.aqiHazardous,
      ],
      stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    ).createShader(rect);
    canvas.drawArc(
      rect, _start, _sweep, false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Marker dot at the current AQI position
    final frac = (aqi / 500).clamp(0.0, 1.0);
    final angle = _start + _sweep * frac;
    final pos =
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
    canvas.drawCircle(pos, stroke / 2 + 4, Paint()..color = AppColors.cardDark);
    canvas.drawCircle(pos, stroke / 2 + 1, Paint()..color = Colors.white);
    canvas.drawCircle(pos, stroke / 2 - 2, Paint()..color = AppColors.getAqiColor(aqi));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.aqi != aqi;
}
