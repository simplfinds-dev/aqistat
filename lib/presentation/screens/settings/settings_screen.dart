import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

/// Settings screen with all user preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === UNITS ===
          _SectionHeader(title: 'Units'),
          _SettingsTile(
            icon: Icons.thermostat,
            title: 'Temperature',
            trailing: SegmentedButton<TemperatureUnit>(
              segments: const [
                ButtonSegment(value: TemperatureUnit.celsius, label: Text('°C')),
                ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('°F')),
              ],
              selected: {settings.temperatureUnit},
              onSelectionChanged: (set) {
                notifier.setTemperatureUnit(set.first);
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return Colors.white54;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return const Color(0xFF4A90D9);
                  return Colors.transparent;
                }),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === APPEARANCE ===
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              dropdownColor: const Color(0xFF21262D),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) notifier.setThemeMode(mode);
              },
            ),
          ),

          const SizedBox(height: 24),

          // === NOTIFICATIONS ===
          _SectionHeader(title: 'Notifications'),
          _ToggleTile(
            icon: Icons.warning_amber,
            title: 'Severe Weather Alerts',
            subtitle: 'Critical weather warnings',
            value: settings.severeWeatherAlerts,
            onChanged: notifier.toggleSevereWeatherAlerts,
          ),
          _ToggleTile(
            icon: Icons.air,
            title: 'Air Quality Alerts',
            subtitle: 'When AQI exceeds ${settings.aqiAlertThreshold}',
            value: settings.aqiAlerts,
            onChanged: notifier.toggleAqiAlerts,
          ),
          _ToggleTile(
            icon: Icons.umbrella,
            title: 'Umbrella Reminders',
            subtitle: 'Morning alert when rain is expected',
            value: settings.umbrellaReminders,
            onChanged: notifier.toggleUmbrellaReminders,
          ),
          _ToggleTile(
            icon: Icons.wb_sunny,
            title: 'UV Alerts',
            subtitle: 'When UV index exceeds ${settings.uvAlertThreshold.toInt()}',
            value: settings.uvAlerts,
            onChanged: notifier.toggleUvAlerts,
          ),
          _ToggleTile(
            icon: Icons.today,
            title: 'Daily Forecast',
            subtitle: 'Morning weather summary',
            value: settings.dailyForecast,
            onChanged: notifier.toggleDailyForecast,
          ),

          const SizedBox(height: 24),

          // === PERSONAL CALIBRATION ===
          _SectionHeader(title: 'Personal Calibration'),
          _SettingsTile(
            icon: Icons.tune,
            title: 'Temperature Sensitivity',
            subtitle: 'Help us learn how weather feels to you',
            onTap: () => _showCalibrationDialog(context),
          ),

          const SizedBox(height: 24),

          // === ABOUT ===
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Aqistat v1.0.0',
            subtitle: 'Living Weather Intelligence',
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showCalibrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        title: const Text(
          'Personal Calibration',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'We\'ll ask you "How does it feel?" periodically to build your personal weather profile. '
          'Over time, Aqistat will learn your temperature sensitivity and adjust "Feels Like" '
          'readings just for you.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.white54, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))
            : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white.withOpacity(0.04),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4A90D9),
      ),
    );
  }
}
