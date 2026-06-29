import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text('About', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.air, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Aqistat', style: TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Version 2.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            const Text(
              'Living Weather Intelligence with global air-quality awareness. Built for everyone, everywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            _credit('Weather data', 'OpenWeatherMap'),
            _credit('Air quality data', 'World Air Quality Index (WAQI)'),
            const Spacer(),
            const Text('Made with Flutter', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _credit(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
