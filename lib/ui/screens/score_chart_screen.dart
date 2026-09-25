import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player.dart';
import '../../game/score_series.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/player_providers.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';
import '../widgets/score_chart.dart';

/// La courbe des scores d'une partie : un joueur, une couleur, une ligne brisée
/// dont chaque point est la fin d'un de SES tours.
///
/// **Deux usages.** Sans argument, la partie EN COURS, suivie en direct : les
/// tours de l'IA continuent pendant qu'on la regarde, et la courbe avance avec
/// eux. Avec [players] et [record], cette partie-là, figée — celle d'une partie
/// terminée, y compris un run archivé, qui n'est pas dans le notifier de partie.
class ScoreChartScreen extends ConsumerWidget {
  /// Les joueurs dans l'ordre du MOTEUR (celui de `GameEngine.players`) et le
  /// journal de la partie à tracer. À fournir ensemble, ou pas du tout.
  final List<Player>? players;
  final SavedGame? record;

  const ScoreChartScreen({super.key, this.players, this.record})
      : assert((players == null) == (record == null), 'players et record vont ensemble');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final displayNames = watchDisplayNames(ref, record);

    final SavedGame? journal;
    final List<Player>? seats;
    if (record != null) {
      journal = record;
      seats = players;
    } else {
      seats = ref.watch(gameProvider)?.players;
      journal = ref.read(gameProvider.notifier).gameRecord;
    }

    // Sans journal, rien à tracer : c'est le cas d'un état chargé directement
    // (`debugLoadState`), qui ne renseigne ni seed ni actions. Même garde que
    // le journal de partie (`_seedLogFromHistory`), et pour la même raison.
    final series = <ScoreSeries>[];
    if (seats != null && journal != null && journal.actions.isNotEmpty) {
      final scores = scoreSeriesByPlayer(journal.setup, journal.seed, journal.actions);
      // `scoreSeriesByPlayer` rend les sièges du MOTEUR, exactement l'ordre de
      // `seats` : noms et couleurs s'alignent sans traduction.
      final colors = assignAvatarColors(seats.map((p) => p.name));
      for (var seat = 0; seat < seats.length && seat < scores.length; seat++) {
        final name = seats[seat].name;
        series.add(ScoreSeries(
          name: name,
          color: colors[name] ?? Colors.white,
          scores: scores[seat],
          // L'infobulle appelle le joueur comme le reste de l'écran : par son
          // surnom quand il en a un.
          label: displayNameOf(displayNames, name),
        ));
      }
    }

    final hasPoints = series.any((s) => s.scores.length > 1);

    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.scoreChartTitle)),
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
