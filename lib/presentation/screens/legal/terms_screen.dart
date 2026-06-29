import 'package:flutter/material.dart';
import 'legal_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Terms of Service',
      lastUpdated: 'June 2026',
      sections: [
        LegalSection('Acceptance of Terms',
          'By downloading or using Aqistat, you agree to these Terms of Service. If you do not agree, please do not use the app.'),
        LegalSection('Weather Data Disclaimer',
          'Aqistat provides weather and air-quality information for general informational purposes only. Forecasts and readings are sourced from third parties and may be inaccurate, delayed, or unavailable. Do not rely on the app as your sole source for decisions involving safety, health, travel, or property. Always consult official local authorities during severe weather.'),
        LegalSection('No Professional Advice',
          'Air-quality and health-related tips in the app are general guidance, not medical advice. Consult a qualified professional for medical concerns.'),
        LegalSection('Acceptable Use',
          'You agree not to misuse the app, attempt to reverse engineer it, overload the underlying data providers, or use it for any unlawful purpose.'),
        LegalSection('Limitation of Liability',
          'The app is provided "as is" without warranties of any kind. To the maximum extent permitted by law, we are not liable for any damages arising from your use of, or inability to use, the app or its data.'),
        LegalSection('Service Availability',
          'We do not guarantee uninterrupted access. Features depend on third-party APIs that may change or become unavailable.'),
        LegalSection('Changes To These Terms',
          'We may revise these terms at any time. Continued use after changes constitutes acceptance of the updated terms.'),
        LegalSection('Contact',
          'Questions about these terms? Reach us at: support@aqistat.app'),
      ],
    );
  }
}
