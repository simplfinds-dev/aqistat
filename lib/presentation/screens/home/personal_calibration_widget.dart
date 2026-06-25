import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Personal Calibration Dialog — "How does it feel?"
/// Appears periodically to learn user's temperature sensitivity
class PersonalCalibrationWidget extends StatefulWidget {
  final double currentTemp;
  final double officialFeelsLike;
  final VoidCallback onDismiss;

  const PersonalCalibrationWidget({
    super.key,
    required this.currentTemp,
    required this.officialFeelsLike,
    required this.onDismiss,
  });

  @override
  State<PersonalCalibrationWidget> createState() => _PersonalCalibrationWidgetState();
}

class _PersonalCalibrationWidgetState extends State<PersonalCalibrationWidget> {
  int _selectedFeeling = 2; // 0=Much Colder, 1=Colder, 2=About Right, 3=Warmer, 4=Much Warmer

  final _feelings = [
    ('🥶', 'Much Colder', -4.0),
    ('😬', 'Colder', -2.0),
    ('😊', 'About Right', 0.0),
    ('😅', 'Warmer', 2.0),
    ('🥵', 'Much Warmer', 4.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF4A90D9), size: 18),
              const SizedBox(width: 8),
              const Text(
                'How does it feel right now?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Official: ${widget.officialFeelsLike.round()}° — Help us calibrate for you',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          // Feeling selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isSelected = _selectedFeeling == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFeeling = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A90D9).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF4A90D9), width: 1.5)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(_feelings[index].$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        _feelings[index].$2,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.white : Colors.white54,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitCalibration(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCalibration() async {
    final offset = _feelings[_selectedFeeling].$3;

    // Save calibration data locally
    final prefs = await SharedPreferences.getInstance();
    final calibrations = prefs.getStringList('calibration_data') ?? [];
    final entry =
        '${widget.currentTemp}|${widget.officialFeelsLike}|$offset|${DateTime.now().toIso8601String()}';
    calibrations.add(entry);
    await prefs.setStringList('calibration_data', calibrations);

    // Calculate running average offset
    double totalOffset = 0;
    for (final c in calibrations) {
      final parts = c.split('|');
      if (parts.length >= 3) {
        totalOffset += double.tryParse(parts[2]) ?? 0;
      }
    }
    final avgOffset = totalOffset / calibrations.length;
    await prefs.setDouble('personal_temp_offset', avgOffset);

    // Record last calibration time
    await prefs.setString('last_calibration', DateTime.now().toIso8601String());

    widget.onDismiss();
  }
}

/// Check if calibration should be shown (not more than once per day)
Future<bool> shouldShowCalibration() async {
  final prefs = await SharedPreferences.getInstance();
  final lastStr = prefs.getString('last_calibration');
  if (lastStr == null) return true; // Never calibrated

  final last = DateTime.tryParse(lastStr);
  if (last == null) return true;

  return DateTime.now().difference(last).inHours > 24;
}

/// Get the user's personal temperature offset
Future<double> getPersonalTempOffset() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('personal_temp_offset') ?? 0.0;
}
