import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/score_series.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/player_providers.dart';
import '../widgets/player_avatar.dart';
import '../widgets/score_chart.dart';

/// La courbe des scores de la partie en cours : un joueur, une couleur, une
/// ligne brisée dont chaque point est la fin d'un de SES tours.
class ScoreChartScreen extends ConsumerWidget {
  const ScoreChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.watch(gameProvider);
    final displayNames = ref.watch(displayNamesProvider);
    final notifier = ref.read(gameProvider.notifier);
    final seed = notifier.seed;
    final setup = notifier.originalSetup;

    // Sans journal, rien à tracer : c'est le cas d'un état chargé directement
    // (`debugLoadState`), qui ne renseigne ni seed ni actions. Même garde que
    // le journal de partie (`_seedLogFromHistory`), et pour la même raison.
    final series = <ScoreSeries>[];
    if (engine != null && seed != null && setup != null && notifier.actions.isNotEmpty) {
      final scores = scoreSeriesByPlayer(setup, seed, notifier.actions);
      // `scoreSeriesByPlayer` rend les sièges du MOTEUR, exactement l'ordre de
      // `engine.players` : noms et couleurs s'alignent sans traduction.
      final colors = assignAvatarColors(engine.players.map((p) => p.name));
      for (var seat = 0; seat < engine.players.length && seat < scores.length; seat++) {
        final name = engine.players[seat].name;
        series.add(ScoreSeries(
          name: name,
          color: colors[name] ?? Colors.white,
          scores: scores[seat],
        ));
      }
    }

    final hasPoints = series.any((s) => s.scores.length > 1);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scoreChartTitle)),
      body: SafeArea(
        child: hasPoints
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(child: ScoreChart(series: series)),
                    const SizedBox(height: 8),
                    Text(l10n.scoreChartXAxis, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final one in series)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 16, height: 3, color: one.color),
                              const SizedBox(width: 6),
                              // Le blason garde le nom, le libellé suit le
                              // surnom : l'un est un repère d'identité, l'autre
                              // la façon dont on appelle le joueur.
                              PlayerAvatarWidget(name: one.name, size: 24, color: one.color),
                              const SizedBox(width: 6),
                              Text(displayNameOf(displayNames, one.name)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.scoreChartEmpty, textAlign: TextAlign.center),
                ),
              ),
      ),
    );
  }
}
