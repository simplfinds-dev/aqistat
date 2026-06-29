import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared scaffold for legal/info pages with a clean readable layout.
class LegalScaffold extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalScaffold({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Last updated: $lastUpdated', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ...sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.heading, style: const TextStyle(color: AppColors.textWhite, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(s.body, style: const TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.6)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}
