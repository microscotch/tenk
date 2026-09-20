import 'combination.dart';
import 'game_engine.dart';
import 'game_recording.dart';
import 'game_setup.dart';
import 'player_stats.dart';

/// Statistiques d'UNE partie, prêtes à être repliées dans les fiches des
/// joueurs (voir `PlayerStats.operator +`).
class GameStatistics {
  /// Une entrée par siège, dans l'ordre de la config **d'origine** — celui de
  /// `SavedGame.setup`, pas l'ordre de jeu réordonné par le départage.
  final List<PlayerStats> bySeat;

  /// Durée active de la partie, identique pour tous ses participants.
  final int activeSeconds;

  const GameStatistics({required this.bySeat, required this.activeSeconds});
}

/// Rejoue une partie et en dérive les statistiques de chaque siège.
///
/// Tout passe par le callback `onGameAction` de [replayGame], prévu pour ça :
/// aucune règle n'est réimplémentée ici, on ne fait qu'observer le moteur
/// avant et après chaque action.
///
/// **Deux espaces d'index cohabitent et les confondre fausserait tout.** Le
/// [setup] reçu est celui d'origine ; `replayGame` le réordonne lui-même une
/// fois le départage rejoué, et tout ce que le moteur expose ensuite
/// (`currentPlayerIndex`, `winnerIndex`, `players[i]`) est dans cet ordre
/// réordonné. Le résultat est retraduit vers l'ordre d'origine avant d'être
/// rendu.
///
/// Une partie non terminée ne compte pour rien : elle n'a ni vainqueur ni
/// durée définitive, et ses figures seraient comptées une seconde fois le jour
/// où elle s'achève.
GameStatistics collectGameStatistics({
  required GameSetup setup,
  required int seed,
  required List<GameAction> actions,
}) {
  final playerCount = setup.playerNames.length;
  final collector = GameStatisticsCollector(playerCount);

  final replay = replayGame(setup, seed, actions, onGameAction: collector.apply);

  final engine = replay.engine;
  final winnerIndex = replay.diceOff.winnerIndex;
  if (engine == null || !engine.gameOver || winnerIndex == null) {
    return GameStatistics(
      bySeat: List.filled(playerCount, PlayerStats.empty),
      activeSeconds: 0,
    );
  }

  final activeSeconds = activePlayingSecondsFor(actions);
  final rotated = List.generate(
    playerCount,
    (seat) => collector.statsFor(seat, activeSeconds: activeSeconds, won: seat == engine.winnerIndex),
  );

  // Retour à l'ordre d'origine : `GameSetup.rotated` a placé le joueur
  // d'origine `(winnerIndex + i) % n` au siège réordonné `i`.
  final bySeat = List.filled(playerCount, PlayerStats.empty);
  for (var i = 0; i < playerCount; i++) {
    bySeat[(winnerIndex + i) % playerCount] = rotated[i];
  }
  return GameStatistics(bySeat: bySeat, activeSeconds: activeSeconds);
}

/// Accumule les statistiques d'une partie au fil de son rejeu.
///
/// Exposé — et non caché derrière [collectGameStatistics] — pour être
/// testable coup par coup : les dés étant déterminés par la seed, vérifier le
/// décompte de chaque figure en cherchant une seed qui la produise tiendrait
/// de l'archéologie. Les tests lui passent directement les deux états du
/// moteur qu'ils veulent observer.
///
/// Les index reçus sont ceux du moteur, donc l'ordre **réordonné** par le
/// départage ; la traduction vers l'ordre d'origine est faite par
/// [collectGameStatistics].
class GameStatisticsCollector {
  final List<_SeatTally> _tallies;

  GameStatisticsCollector(int playerCount)
      : _tallies = List.generate(playerCount, (_) => _SeatTally());

  /// Signature de `onGameAction` de [replayGame], telle quelle.
  void apply(GameEngine? previous, GameEngine next, GameAction action) =>
      _observe(_tallies, previous, next, action);

  PlayerStats statsFor(int seat, {required int activeSeconds, required bool won}) =>
      _tallies[seat].toStats(activeSeconds: activeSeconds, won: won);
}

void _observe(List<_SeatTally> tallies, GameEngine? previous, GameEngine next, GameAction action) {
  if (previous == null) return;
  final seat = previous.currentPlayerIndex;
  final tally = tallies[seat];

  switch (action.type) {
    case GameActionType.startTurn:
      tally.hotDiceRun = 0;

    case GameActionType.roll:
      final analysis = next.activeTurn?.pendingRoll;
      if (analysis != null) {
        _countFigures(tally, analysis);
        _countAceQuint(tally, previous, analysis);
      }

    case GameActionType.applyKeep:
      _countKeptLoneDice(tally, previous, action);
      if (next.activeTurn?.mustContinue ?? false) {
        tally.hotDiceRun++;
        tally.longestHotDiceRun = _max(tally.longestHotDiceRun, tally.hotDiceRun);
      }
      // `_advance` vide toujours `activeTurn` : un `applyKeep` qui le laisse
      // nul a donc banqué sur place — le cas de la quinte d'as, seule figure
      // autorisée à conclure une main pleine.
      if (next.activeTurn == null) {
        _endTurnByBank(tally, previous);
      }

    case GameActionType.bank:
      _endTurnByBank(tally, previous);

    case GameActionType.endBustedTurn:
      tally.hotDiceRun = 0;
      tally.busts++;
      tally.bustStreak++;
      if (tally.bustStreak == 1) tally.bustStreakCount++;
      tally.longestBustStreak = _max(tally.longestBustStreak, tally.bustStreak);

    case GameActionType.diceOffRoll:
    case GameActionType.diceOffResolveRound:
    case GameActionType.resume:
      // Une reprise n'est pas un coup : `replayGame` ne la transmet même pas
      // ici. Le cas est listé pour que le switch reste exhaustif.
      break;
  }

  _countBars(tallies, previous, next);
}

void _endTurnByBank(_SeatTally tally, GameEngine previous) {
  tally.hotDiceRun = 0;
  tally.bustStreak = 0;
  tally.bestBankedTurn = _max(tally.bestBankedTurn, previous.activeTurn?.bankedScore ?? 0);
}

/// Figures comptées dès qu'elles SORTENT, même sur un lancer qui fait craquer
/// par dépassement — les figures étant de toute façon obligatoires à garder,
/// l'écart avec « gardées » ne concerne que les lancers perdus.
void _countFigures(_SeatTally tally, RollAnalysis analysis) {
  for (final group in analysis.groups) {
    if (group.isSuite) {
      // Une suite est toujours `value: 0` : petite ou grande ne se lit que sur
      // les faces réellement tombées.
      if (analysis.faces.contains(1)) {
        tally.petitesSuites++;
      } else {
        tally.grandesSuites++;
      }
      continue;
    }
    // `diceCount >= 3` est la seule lecture correcte : la règle d'extension
    // produit elle aussi des groupes de valeur quelconque, mais à 1 ou 2 dés.
    switch (group.diceCount) {
      case 3:
        tally.brelans[group.value] = (tally.brelans[group.value] ?? 0) + 1;
      case 4:
        tally.carres[group.value] = (tally.carres[group.value] ?? 0) + 1;
      case 5:
        tally.quintes[group.value] = (tally.quintes[group.value] ?? 0) + 1;
    }
  }
}

/// La quinte d'as vaut 10000 d'un coup : réussie si le joueur était encore à
/// la niche (rien au compteur, rien de banqué ce tour), elle tombe alors pile
/// sur la cible ; perdue sinon, elle dépasse et fait craquer. C'est le calcul
/// que fait `GameEngine.applyKeep`, relu ici sans le refaire.
void _countAceQuint(_SeatTally tally, GameEngine previous, RollAnalysis analysis) {
  final isAceQuint = analysis.groups.any((g) => g.value == 1 && g.diceCount == 5);
  if (!isAceQuint) return;
  // « À la niche » : rien au compteur et rien de banqué ce tour-ci. Ajouter
  // 10000 tombe alors pile sur la cible ; au moindre point déjà acquis, la
  // même figure dépasse.
  final before = previous.currentPlayer.totalScore + (previous.activeTurn?.bankedScore ?? 0);
  if (before == 0) {
    tally.quintesDAsReussies++;
  } else {
    tally.quintesDAsPerdues++;
  }
}

/// As et 5 isolés effectivement GARDÉS, comptés par dé. Les as ne sont jamais
/// déclinables, donc gardés vaut lancés ; les 5, eux, peuvent être rejetés
/// pour être relancés, et ceux-là ne comptent pas.
void _countKeptLoneDice(_SeatTally tally, GameEngine previous, GameAction action) {
  final analysis = previous.activeTurn?.pendingRoll;
  if (analysis == null) return;

  for (final group in analysis.mandatoryGroups) {
    if (group.value == 1 && group.diceCount < 3) tally.keptLoneAces += group.diceCount;
  }

  final fives = analysis.declinableFives;
  if (fives != null) {
    final declined = action.params['declineFivesCount'] as int? ?? 0;
    final kept = fives.diceCount - declined;
    if (kept > 0) tally.keptLoneFives += kept;
  }
}

/// Lignes nouvellement barrées, attribuées par `ScoreEntry.barredBy` — le
/// moteur y a déjà inscrit l'auteur : soi-même sur un second craque consécutif,
/// l'auteur de la collision de score sinon. Rien à recalculer, juste à lire.
void _countBars(List<_SeatTally> tallies, GameEngine previous, GameEngine next) {
  for (var victim = 0; victim < next.players.length; victim++) {
    final before = previous.players[victim].grid;
    final after = next.players[victim].grid;
    for (var line = 0; line < after.length; line++) {
      if (!after[line].isBarred) continue;
      if (line < before.length && before[line].isBarred) continue;

      final author = after[line].barredBy;
      if (author == null) continue;
      if (author == next.players[victim].name) {
        tallies[victim].selfBars++;
      } else {
        final authorSeat = next.players.indexWhere((p) => p.name == author);
        if (authorSeat >= 0) tallies[authorSeat].barsInflicted++;
      }
    }
  }
}

int _max(int a, int b) => a > b ? a : b;

/// Compteurs d'un siège pendant le rejeu, convertis en [PlayerStats] à la fin.
/// Mutable à dessein : un rejeu est une boucle, pas une réduction.
class _SeatTally {
  int keptLoneAces = 0;
  int keptLoneFives = 0;
  final Map<int, int> brelans = {};
  final Map<int, int> carres = {};
  final Map<int, int> quintes = {};
  int petitesSuites = 0;
  int grandesSuites = 0;
  int quintesDAsReussies = 0;
  int quintesDAsPerdues = 0;
  int bestBankedTurn = 0;
  int hotDiceRun = 0;
  int longestHotDiceRun = 0;
  int busts = 0;
  int bustStreak = 0;
  int longestBustStreak = 0;
  int bustStreakCount = 0;
  int selfBars = 0;
  int barsInflicted = 0;

  /// Sur une seule partie, un maximum « par partie » se confond avec le total :
  /// c'est l'addition de [PlayerStats] qui en fera un maximum entre parties.
  PlayerStats toStats({required int activeSeconds, required bool won}) => PlayerStats(
        gamesPlayed: 1,
        gamesWon: won ? 1 : 0,
        totalActiveSeconds: activeSeconds,
        shortestActiveSeconds: activeSeconds,
        longestActiveSeconds: activeSeconds,
        keptLoneAces: keptLoneAces,
        keptLoneFives: keptLoneFives,
        brelans: Map.unmodifiable(brelans),
        carres: Map.unmodifiable(carres),
        quintes: Map.unmodifiable(quintes),
        petitesSuites: petitesSuites,
        grandesSuites: grandesSuites,
        quintesDAsReussies: quintesDAsReussies,
        quintesDAsPerdues: quintesDAsPerdues,
        bestBankedTurn: bestBankedTurn,
        longestHotDiceRun: longestHotDiceRun,
        bustsTotal: busts,
        longestBustStreak: longestBustStreak,
        bustStreakCount: bustStreakCount,
        selfBarsTotal: selfBars,
        selfBarsMaxInGame: selfBars,
        barsInflictedTotal: barsInflicted,
        barsInflictedMaxInGame: barsInflicted,
      );
}
