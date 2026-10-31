import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/app_top_bar.dart';

/// Les remerciements, ouverts depuis le dialogue « À propos » : les testeurs de la
/// première heure, par leur pseudo (des noms propres, jamais traduits).
class AcknowledgementsScreen extends StatelessWidget {
  const AcknowledgementsScreen({super.key});

  /// Les beta-testeurs de la première heure, dans l'ordre où on les remercie.
  static const betaTesters = [
    'IvenKor',
    'Cam',
    'Fluo',
    'Popoche',
    'Sam',
    'Town God',
    'Finette',
    'Greg',
    'R1',
    'Seb',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.acknowledgementsButton)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.acknowledgementsIntro, style: textTheme.titleMedium),
              const SizedBox(height: 16),
              for (final name in betaTesters)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: textTheme.titleMedium),
                      Expanded(child: Text(name, style: textTheme.titleMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
