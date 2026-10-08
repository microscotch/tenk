import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/app_top_bar.dart';
import 'tutorial_screen.dart';

/// Écran d'aide expliquant les règles du jeu en langage clair, accessible
/// depuis le bouton "?" de l'écran d'accueil. Contenu purement statique (pas
/// de provider), une section par règle non-évidente.
class RulesScreen extends StatelessWidget {
  /// Offre « Revoir le tutoriel ». Seulement depuis l'accueil : le tutoriel
  /// joue sur l'état de la partie à l'écran, et écraserait celle d'un écran de
  /// jeu resté empilé dessous (les règles s'ouvrent aussi depuis son menu).
  final bool canReplayTutorial;

  const RulesScreen({super.key, this.canReplayTutorial = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (l10n.rulesGoalTitle, l10n.rulesGoalBody),
      (l10n.rulesTurnTitle, l10n.rulesTurnBody),
      (l10n.rulesScoringTitle, l10n.rulesScoringBody),
      (l10n.rulesBustTitle, l10n.rulesBustBody),
      (l10n.rulesEntryTitle, l10n.rulesEntryBody),
      (l10n.rulesExtensionTitle, l10n.rulesExtensionBody),
      (l10n.rulesInheritTitle, l10n.rulesInheritBody),
      (l10n.rulesVictoryTitle, l10n.rulesVictoryBody),
    ];

    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.rulesScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canReplayTutorial) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TutorialScreen())),
                  icon: const Icon(Icons.school),
                  label: Text(l10n.tutorialReplayButton),
                ),
                const SizedBox(height: 24),
              ],
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
