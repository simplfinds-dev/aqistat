import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final int? conditionCode;
  final double windSpeed;
  const AnimatedBackground({super.key, required this.child, this.conditionCode, this.windSpeed = 0});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.getSkyGradient(DateTime.now().hour);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.4, -1), end: Alignment(1 - t * 0.3, 1),
              colors: colors, stops: [0.0, 0.5 + t * 0.1, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
