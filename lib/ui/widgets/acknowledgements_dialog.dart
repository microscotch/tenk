import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Les remerciements, ouverts depuis le dialogue « À propos », par-dessus lui comme
/// la fenêtre des crédits : les testeurs de la première heure, par leur pseudo (des
/// noms propres, jamais traduits).
Future<void> showAcknowledgementsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AcknowledgementsDialog(),
  );
}

class AcknowledgementsDialog extends StatelessWidget {
  const AcknowledgementsDialog({super.key});

  /// Les beta-testeurs de la première heure, par ordre alphabétique.
  static const betaTesters = [
    'Alex',
    'Cam',
    'Chris',
    'Deepsound',
    'Finette',
    'Fluo',
    'Greg',
    'IvenKor',
    'Kali78',
    'Nico',
    'Popoche',
    'R1',
    'Sam',
    'Seb',
    'Town God',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(l10n.acknowledgementsButton),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.closeButton),
        ),
      ],
    );
  }
}
