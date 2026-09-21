import 'game_recording.dart';
import 'game_setup.dart';

/// Score courant de chaque joueur après chacun de SES tours.
///
/// Une entrée par siège, chaque série commençant à 0 puis gagnant un point par
/// tour terminé — banqué comme craqué. Un craque laisse le score inchangé et
/// produit donc un palier : c'est voulu, un tour perdu reste un tour joué.
///
/// **Ne peut pas se lire dans `Player.grid`.** Celle-ci n'accueille une
/// nouvelle ligne qu'à un tour réussi (`applySuccessfulTurn`) ; un craque se
/// contente de marquer d'un tiret la ligne existante, quand il ne la barre pas.
/// Les tours craqués y seraient donc invisibles, et l'abscisse fausse.
///
/// Les index sont ceux du MOTEUR, c'est-à-dire l'ordre réordonné par le
/// départage — le même que `GameEngine.players`, d'où viennent les noms et les
/// couleurs à l'écran. Aucune traduction vers l'ordre d'origine n'est donc
/// nécessaire ici, contrairement aux statistiques de fiches : ne pas en
/// rajouter une par réflexe.
List<List<int>> scoreSeriesByPlayer(GameSetup setup, int seed, List<GameAction> actions) {
  final playerCount = setup.playerNames.length;
  final series = List.generate(playerCount, (_) => <int>[0]);

  replayGame(setup, seed, actions, onGameAction: (previous, next, action) {
    if (previous == null) return;
    if (action.type != GameActionType.bank && action.type != GameActionType.endBustedTurn) {
      return;
    }
    // Le joueur dont le tour s'achève est celui d'AVANT la transition : après
    // un banquage, le moteur a déjà passé la main.
    final seat = previous.currentPlayerIndex;
    if (seat >= series.length) return;
    series[seat].add(next.players[seat].totalScore);
  });

  return series;
}
