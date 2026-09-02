import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Écran d'aide expliquant les règles du jeu en langage clair, accessible
/// depuis le bouton "?" de l'écran d'accueil. Contenu purement statique (pas
/// de provider), une section par règle non-évidente.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (l10n.rulesGoalTitle, l10n.rulesGoalBody),
      (l10n.rulesTurnTitle, l10n.rulesTurnBody),
      (l10n.rulesScoringTitle, l10n.rulesScoringBody),
      (l10n.rulesHotDiceTitle, l10n.rulesHotDiceBody),
      (l10n.rulesBustTitle, l10n.rulesBustBody),
      (l10n.rulesEntryTitle, l10n.rulesEntryBody),
      (l10n.rulesNoFiftyTitle, l10n.rulesNoFiftyBody),
      (l10n.rulesExtensionTitle, l10n.rulesExtensionBody),
      (l10n.rulesInheritTitle, l10n.rulesInheritBody),
      (l10n.rulesBarredTitle, l10n.rulesBarredBody),
      (l10n.rulesVictoryTitle, l10n.rulesVictoryBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (title, body) in sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(height: 1.4)),
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
