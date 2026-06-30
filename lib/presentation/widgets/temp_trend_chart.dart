import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../providers/weather_provider.dart';

/// A smooth gradient line chart of upcoming temperatures.
class TempTrendChart extends StatelessWidget {
  final List<HourlyData> hourly;
  final TempUnit unit;
  const TempTrendChart({super.key, required this.hourly, required this.unit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: double.infinity,
      child: CustomPaint(painter: _TrendPainter(hourly, unit)),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<HourlyData> data;
  final TempUnit unit;
  _TrendPainter(this.data, this.unit);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final temps = data.map((e) => e.temp).toList();
    final minT = temps.reduce(min);
    final maxT = temps.reduce(max);
    final range = (maxT - minT) < 1 ? 1.0 : (maxT - minT);
    const padX = 16.0;
    const padTop = 22.0;
    const padBottom = 14.0;
    final w = size.width;
    final h = size.height;

    Offset pointAt(int i) {
      final x = padX + (w - 2 * padX) * (i / (data.length - 1));
      final norm = (temps[i] - minT) / range;
      final y = padTop + (h - padTop - padBottom) * (1 - norm);
      return Offset(x, y);
    }

    final pts = List.generate(data.length, pointAt);


    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      line.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Soft fill under the curve
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.32),
            AppColors.primary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Gradient stroke
    canvas.drawPath(
      line,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.accent, AppColors.primary])
            .createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + temperature labels (every other point to reduce clutter)
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < pts.length; i++) {
      final isEdge = i == 0 || i == pts.length - 1;
      if (i % 2 == 0 || isEdge) {
        canvas.drawCircle(pts[i], 3, Paint()..color = AppColors.textWhite);
        tp.text = TextSpan(
          text: '${convertTemp(temps[i], unit).round()}°',
          style: const TextStyle(
              color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.w600),
        );
        tp.layout();
        tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => true;
}
