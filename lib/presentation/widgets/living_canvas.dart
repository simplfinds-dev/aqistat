import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Living Canvas — The animated, generative background that IS the weather
/// Shifts with time of day, weather conditions, and wind speed
class LivingCanvas extends StatefulWidget {
  final String condition;
  final double windSpeed; // km/h
  final int clouds; // 0-100
  final int humidity;
  final bool isDay;
  final Widget child;

  const LivingCanvas({
    super.key,
    required this.condition,
    required this.windSpeed,
    required this.clouds,
    required this.humidity,
    required this.isDay,
    required this.child,
  });

  @override
  State<LivingCanvas> createState() => _LivingCanvasState();
}

class _LivingCanvasState extends State<LivingCanvas>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    // Gradient animation speed based on wind
    final windFactor = (widget.windSpeed / 50).clamp(0.3, 2.0);
    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: (10 / windFactor).round()),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: _buildGradient(),
          ),
          child: Stack(
            children: [
              // Weather overlay (rain drops, snow, etc.)
              if (_shouldShowParticles())
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => CustomPaint(
                    painter: WeatherParticlePainter(
                      condition: widget.condition,
                      progress: _particleController.value,
                      windSpeed: widget.windSpeed,
                    ),
                    size: Size.infinite,
                  ),
                ),
              // Fog overlay
              if (widget.condition.toLowerCase().contains('fog') ||
                  widget.condition.toLowerCase().contains('mist'))
                Container(
                  color: AppColors.fogOverlay,
                ),
              // Content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  LinearGradient _buildGradient() {
    final hour = DateTime.now().hour;
    final baseColors = AppColors.getTimeGradient(hour);
    final progress = _gradientController.value;

    // Apply weather condition overlay
    Color overlay = Colors.transparent;
    if (widget.condition.toLowerCase().contains('rain')) {
      overlay = AppColors.rainyOverlay;
    } else if (widget.clouds > 70) {
      overlay = AppColors.cloudyOverlay;
    } else if (widget.condition.toLowerCase().contains('snow')) {
      overlay = AppColors.snowOverlay;
    } else if (widget.condition.toLowerCase().contains('thunder')) {
      overlay = AppColors.stormOverlay;
    }

    // Animated gradient shift
    final begin = Alignment(
      -1.0 + progress * 0.5,
      -1.0 + progress * 0.3,
    );
    final end = Alignment(
      1.0 - progress * 0.3,
      1.0 - progress * 0.5,
    );

    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        Color.lerp(baseColors[0], overlay, 0.2) ?? baseColors[0],
        Color.lerp(baseColors[1], overlay, 0.15) ?? baseColors[1],
        if (baseColors.length > 2)
          Color.lerp(baseColors[2], overlay, 0.1) ?? baseColors[2],
      ],
    );
  }

  bool _shouldShowParticles() {
    final condition = widget.condition.toLowerCase();
    return condition.contains('rain') ||
        condition.contains('snow') ||
        condition.contains('drizzle');
  }
}

/// Custom painter for weather particles (rain drops, snowflakes)
class WeatherParticlePainter extends CustomPainter {
  final String condition;
  final double progress;
  final double windSpeed;
  final Random _random = Random(42); // Fixed seed for consistent particles

  WeatherParticlePainter({
    required this.condition,
    required this.progress,
    required this.windSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isRain = condition.toLowerCase().contains('rain') ||
        condition.toLowerCase().contains('drizzle');
    final isSnow = condition.toLowerCase().contains('snow');

    if (isRain) {
      _paintRain(canvas, size);
    } else if (isSnow) {
      _paintSnow(canvas, size);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final windOffset = windSpeed / 30; // Tilt rain with wind
    final particleCount = 80;

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = (_random.nextDouble() + progress) % 1.0;
      final y = baseY * size.height;
      final length = 15 + _random.nextDouble() * 15;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + windOffset * length, y + length),
        paint,
      );
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.fill;

    final particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      final x = (_random.nextDouble() * size.width +
              sin(progress * 2 * pi + i) * 20) %
          size.width;
      final baseY = (_random.nextDouble() + progress * 0.5) % 1.0;
      final y = baseY * size.height;
      final radius = 2 + _random.nextDouble() * 3;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WeatherParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
