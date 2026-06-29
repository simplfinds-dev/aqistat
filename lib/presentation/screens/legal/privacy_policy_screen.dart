import 'package:flutter/material.dart';
import 'legal_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Privacy Policy',
      lastUpdated: 'June 2026',
      sections: [
        LegalSection('Overview',
          'Aqistat ("we", "our", or "the app") respects your privacy. This policy explains what information the app accesses, how it is used, and your choices. We designed Aqistat to collect as little data as possible.'),
        LegalSection('Location Data',
          'With your permission, the app accesses your device location to show local weather and air quality. Your location is used only to fetch this data from our weather providers. It is never sold, shared with advertisers, or stored on our servers. You can deny location access and search for cities manually instead.'),
        LegalSection('Data We Store On Your Device',
          'To reduce network usage and protect API limits, the app caches recent weather and air-quality results locally on your device. This cache stays on your phone, is never uploaded, and is cleared when you uninstall the app.'),
        LegalSection('Third-Party Services',
          'Weather data is provided by OpenWeatherMap and air-quality data by the World Air Quality Index (WAQI) project. When the app requests data, your approximate coordinates are sent to these services so they can return local results. Please review their respective privacy policies.'),
        LegalSection('What We Do NOT Collect',
          'We do not collect your name, email, contacts, photos, or any personal identifiers. We do not use analytics or advertising trackers. We do not create user accounts.'),
        LegalSection('Data Security',
          'All network requests use encrypted HTTPS connections. The app blocks insecure (cleartext) traffic, disables cloud backup of its local data, and ships with code obfuscation in release builds to protect against tampering.'),
        LegalSection('Children\u2019s Privacy',
          'Aqistat is suitable for general audiences and does not knowingly collect personal information from children.'),
        LegalSection('Changes To This Policy',
          'We may update this policy from time to time. Material changes will be reflected by the "Last updated" date above.'),
        LegalSection('Contact',
          'Questions about this policy? Reach us at: support@aqistat.app'),
      ],
    );
  }
}
