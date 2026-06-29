import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/weather_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isCelsius = settings.unit == TempUnit.celsius;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('PREFERENCES'),
          _card(child: SwitchListTile(
            value: isCelsius,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleUnit(),
            activeColor: AppColors.accent,
            title: const Text('Temperature Unit', style: TextStyle(color: AppColors.textWhite, fontSize: 15)),
            subtitle: Text(isCelsius ? 'Celsius (\u00b0C)' : 'Fahrenheit (\u00b0F)', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            secondary: const Icon(Icons.thermostat, color: AppColors.textGrey),
          )),
          const SizedBox(height: 20),
          _section('LEGAL'),
          _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy', const PrivacyPolicyScreen()),
          _tile(context, Icons.description_outlined, 'Terms of Service', const TermsScreen()),
          const SizedBox(height: 20),
          _section('ABOUT'),
          _tile(context, Icons.info_outline, 'About Aqistat', const AboutScreen()),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Text(t, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(16)),
    child: child,
  );

  Widget _tile(BuildContext context, IconData icon, String title, Widget page) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      leading: Icon(icon, color: AppColors.textGrey),
      title: Text(title, style: const TextStyle(color: AppColors.textWhite, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    ),
  );
}
