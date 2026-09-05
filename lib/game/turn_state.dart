import 'dart:math';

import 'combination.dart';
import 'dice_roll.dart';
import 'player.dart' show winningScore;
import 'turn_result.dart';

/// Un dé effectivement gardé (mis de côté) au cours du tour, avec la valeur
/// de points qu'il a rapportée. [isExtended] signale un dé isolé dont la
/// valeur de points vient de la règle d'extension (100 points "temporaires",
/// au lieu de 0 normalement, ou 100 au lieu de 50 pour un 5) plutôt que de sa
/// valeur de base — utile pour le mettre en évidence à l'écran.
class KeptDie {
  final int value;
  final int points;
  final bool isExtended;

  const KeptDie({required this.value, required this.points, required this.isExtended});
}

/// Décompose les dés effectivement gardés lors de l'application d'une
/// décision de garde (groupes obligatoires + 5 isolés conservés) en dés
/// individuels, pour l'affichage permanent des dés gardés ce tour.
List<KeptDie> _keptDiceFrom(RollAnalysis analysis, int declineFivesCount) {
  if (analysis.groups.any((g) => g.isSuite)) {
    const perDie = 500 ~/ 5;
    return [for (final f in analysis.faces) KeptDie(value: f, points: perDie, isExtended: false)];
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] = (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }
  final fivesGroup = analysis.declinableFives;
  var declineRemaining = declineFivesCount;

  final result = <KeptDie>[];
  for (final f in analysis.faces) {
    final remaining = mandatoryRemaining[f];
    if (remaining != null && remaining > 0) {
      final g = analysis.mandatoryGroups.firstWhere((g) => g.value == f);
      final perDie = g.points ~/ g.diceCount;
      // Un groupe obligatoire isolé (moins de 3 dés) de valeur non-as ne peut
      // exister que via la règle d'extension : ses points sont "temporaires".
      final isExtended = g.diceCount < 3 && g.value != 1;
      result.add(KeptDie(value: f, points: perDie, isExtended: isExtended));
      mandatoryRemaining[f] = remaining - 1;
    } else if (fivesGroup != null && f == 5) {
      if (declineRemaining > 0) {
        declineRemaining--;
      } else {
        final perDie = fivesGroup.points ~/ fivesGroup.diceCount;
        result.add(KeptDie(value: 5, points: perDie, isExtended: perDie == 100));
      }
    }
  }
  return result;
}

/// Pourquoi un tour s'est terminé par un craque — l'UI n'a pas à le déduire
/// de la forme de l'état (voir `game_screen.dart`, qui affichait auparavant
/// son message d'explication en se fiant à l'absence de lancer en attente).
enum BustReason {
  /// Aucun dé du lancer ne marque : le craque classique.
  noScore,

  /// Le lancer marque, mais même en écartant tous les 5 que le joueur a le
  /// droit d'écarter, son total dépasserait 10000 (voir [GameEngine.roll]).
  exceedsTarget,

  /// Le lancer complète la main (tous les dés marquent) en tombant pile sur
  /// 10000 : la main pleine oblige à relancer, et n'importe quel relancer
  /// marquant dépasserait la cible — l'impasse est totale, le tour est perdu
  /// dès cet instant plutôt qu'au relancer suivant (voir
  /// [GameEngine.applyKeep]).
  fullHandAtTarget,
}

/// État immuable d'un tour en cours. Un tour s'étend sur un ou plusieurs
/// lancers ; chaque lancer produit une [RollAnalysis] en attente de décision
/// ([pendingRoll]) tant que le joueur n'a pas choisi quels dés garder.
class TurnState {
  /// Nombre de dés à lancer au prochain lancer.
  final int diceToRoll;

  /// Score accumulé et verrouillé ce tour (hors lancer en attente de décision).
  final int bankedScore;

  /// Valeurs pour lesquelles un brelan/carré a déjà été encaissé ce tour
  /// (déclenche la règle d'extension sur les lancers suivants).
  final Set<int> extendedValues;

  /// Analyse du dernier lancer, en attente d'une décision du joueur
  /// (null si aucun lancer n'est en attente, par ex. juste après l'application
  /// d'une décision, ou en tout début de tour).
  final RollAnalysis? pendingRoll;

  /// True juste après un lancer où tous les dés ont scoré ("dés chauds") :
  /// le joueur est obligé de relancer, il ne peut pas s'arrêter.
  final bool mustContinue;

  /// True si le tour est terminé (craque). Un tour se termine aussi
  /// "normalement" par un banquage explicite, géré au niveau du moteur de
  /// partie (GameEngine), pas ici.
  final bool busted;

  /// Motif du craque, null hors craque.
  final BustReason? bustReason;

  /// Tous les dés gardés depuis le début du tour (persiste à travers les
  /// lancers successifs, y compris après des dés chauds), pour un affichage
  /// permanent à l'écran.
  final List<KeptDie> keptDiceThisTurn;

  /// True dès qu'au moins un lancer a eu lieu ce tour. Un tour qui démarre
  /// sur une main héritée (score/dés d'un autre joueur repris comme base)
  /// a un bankedScore potentiellement déjà au-dessus du minimum sans qu'aucun
  /// dé n'ait encore été lancé cette fois-ci : il ne doit pas être possible
  /// de s'arrêter avant d'avoir effectivement relancé les dés hérités.
  final bool hasRolledThisTurn;

  const TurnState({
    required this.diceToRoll,
    this.bankedScore = 0,
    this.extendedValues = const {},
    this.pendingRoll,
    this.mustContinue = false,
    this.busted = false,
    this.bustReason,
    this.keptDiceThisTurn = const [],
    this.hasRolledThisTurn = false,
  });

  factory TurnState.initial(int diceToRoll) => TurnState(diceToRoll: diceToRoll);

  bool get isOver => busted;

  int get turnScoreEndsIn50 => bankedScore % 100;

  TurnState copyWith({
    int? diceToRoll,
    int? bankedScore,
    Set<int>? extendedValues,
    RollAnalysis? pendingRoll,
    bool clearPendingRoll = false,
    bool? mustContinue,
    bool? busted,
    BustReason? bustReason,
    List<KeptDie>? keptDiceThisTurn,
    bool? hasRolledThisTurn,
  }) {
    return TurnState(
      diceToRoll: diceToRoll ?? this.diceToRoll,
      bankedScore: bankedScore ?? this.bankedScore,
      extendedValues: extendedValues ?? this.extendedValues,
      pendingRoll: clearPendingRoll ? null : (pendingRoll ?? this.pendingRoll),
      mustContinue: mustContinue ?? this.mustContinue,
      busted: busted ?? this.busted,
      bustReason: bustReason ?? this.bustReason,
      keptDiceThisTurn: keptDiceThisTurn ?? this.keptDiceThisTurn,
      hasRolledThisTurn: hasRolledThisTurn ?? this.hasRolledThisTurn,
    );
  }
}

/// Effectue un lancer des dés disponibles de [state] et retourne le nouvel
/// état avec l'analyse en attente de décision. Si le lancer ne rapporte
/// aucun point, le tour se termine immédiatement en craque.
TurnState rollTurn(TurnState state, {Random? random}) {
  if (state.pendingRoll != null) {
    throw StateError('Une décision est en attente sur le lancer précédent');
  }
  if (state.busted) {
    throw StateError('Le tour est terminé');
  }

  final faces = rollDice(state.diceToRoll, random);
  final analysis = analyzeRoll(faces, extendedValues: state.extendedValues);

  if (!analysis.hasAnyScore) {
    return state.copyWith(
      pendingRoll: analysis,
      busted: true,
      bustReason: BustReason.noScore,
      hasRolledThisTurn: true,
    );
  }
  return state.copyWith(pendingRoll: analysis, hasRolledThisTurn: true);
}

/// Nombre de 5 isolés déclinables que le joueur est OBLIGÉ de garder sur ce
/// lancer. Encode les mêmes contraintes que [applyKeepDecision] :
/// - sans dé non-marquant pour les accompagner au relancer, aucun 5 ne peut
///   être écarté (voir [RollAnalysis.canDeclineFives]) : ils sont tous forcés ;
/// - si le lancer ne contient aucun groupe obligatoire, au moins un dé
///   marquant doit être gardé, donc au moins un 5 ;
/// - sinon, les groupes obligatoires suffisent et tous les 5 sont écartables.
int minKeepableFives(RollAnalysis analysis) {
  final fives = analysis.declinableFives;
  if (fives == null) return 0;
  if (!analysis.canDeclineFives) return fives.diceCount;
  return analysis.mandatoryGroups.isEmpty ? 1 : 0;
}

/// Points que ce lancer rapportera au minimum, quoi que le joueur décide :
/// groupes obligatoires + les 5 qu'il ne peut pas écarter.
int minimumUnavoidableGain(RollAnalysis analysis) {
  var points = 0;
  for (final group in analysis.mandatoryGroups) {
    points += group.points;
  }
  final fives = analysis.declinableFives;
  if (fives != null) {
    points += minKeepableFives(analysis) * (fives.points ~/ fives.diceCount);
  }
  return points;
}

/// Nombre maximum de 5 isolés que le joueur peut garder sans faire dépasser
/// [winningScore] à son total — garder au-delà ne lui est jamais proposé
/// (côté humain comme côté IA). Peut être inférieur à [minKeepableFives] :
/// c'est alors qu'aucune décision de garde ne sauve le tour, et le craque est
/// prononcé dès le lancer (voir [GameEngine.roll]).
int maxKeepableFives(TurnState state, RollAnalysis analysis, {required int currentTotal}) {
  final fives = analysis.declinableFives;
  if (fives == null) return 0;
  final perDie = fives.points ~/ fives.diceCount;
  var mandatoryPoints = 0;
  for (final group in analysis.mandatoryGroups) {
    mandatoryPoints += group.points;
  }
  final base = currentTotal + state.bankedScore + mandatoryPoints;
  for (var keep = fives.diceCount; keep >= 0; keep--) {
    if (base + keep * perDie <= winningScore) return keep;
  }
  return 0;
}

/// Applique la décision du joueur sur le lancer en attente : combien de 5
/// isolés (parmi ceux déclinables) il choisit de ne PAS garder pour les
/// relancer avec les dés non-marquants.
TurnState applyKeepDecision(TurnState state, {int declineFivesCount = 0}) {
  final analysis = state.pendingRoll;
  if (analysis == null) {
    throw StateError('Aucun lancer en attente de décision');
  }
  if (declineFivesCount < 0) {
    throw ArgumentError('declineFivesCount ne peut pas être négatif');
  }

  final fivesGroup = analysis.declinableFives;
  if (declineFivesCount > 0) {
    if (fivesGroup == null || declineFivesCount > fivesGroup.diceCount) {
      throw ArgumentError('Rejet de 5 invalide : aucun 5 déclinable disponible en quantité suffisante');
    }
    if (!analysis.canDeclineFives) {
      throw StateError('Impossible de rejeter un 5 : aucun dé non-marquant à relancer avec');
    }
    if (analysis.mandatoryGroups.isEmpty && declineFivesCount == fivesGroup.diceCount) {
      throw ArgumentError(
        'Impossible de rejeter tous les 5 : au moins un dé marquant doit être gardé sur ce lancer',
      );
    }
  }

  var diceKept = 0;
  var roundPoints = 0;
  final newExtended = {...state.extendedValues};

  for (final g in analysis.mandatoryGroups) {
    diceKept += g.diceCount;
    roundPoints += g.points;
    if (!g.isSuite) newExtended.add(g.value);
  }

  if (fivesGroup != null) {
    final keptFivesCount = fivesGroup.diceCount - declineFivesCount;
    if (keptFivesCount > 0) {
      final perDie = fivesGroup.points ~/ fivesGroup.diceCount;
      diceKept += keptFivesCount;
      roundPoints += keptFivesCount * perDie;
    }
  }

  final diceRemaining = analysis.totalDiceRolled - diceKept;
  final hotDice = diceRemaining == 0;

  // La règle d'extension n'est active que tant qu'il reste des dés à jouer
  // dans la main en cours : un "dés chauds" (plus aucun dé restant) repart
  // sur un jeu de 5 dés neufs, ce qui efface les valeurs étendues. Idem pour
  // l'affichage des dés gardés : il ne doit refléter que la main en cours,
  // pas les mains précédentes du même tour.
  return state.copyWith(
    diceToRoll: hotDice ? 5 : diceRemaining,
    bankedScore: state.bankedScore + roundPoints,
    extendedValues: hotDice ? const {} : newExtended,
    keptDiceThisTurn: hotDice ? const [] : [...state.keptDiceThisTurn, ..._keptDiceFrom(analysis, declineFivesCount)],
    clearPendingRoll: true,
    mustContinue: hotDice,
  );
}

/// Tente de banquer (valider) le score du tour en cours. [currentTotal] est
/// le score déjà validé du joueur AVANT ce tour (hors tour en cours), pour
/// détecter les deux cas limites autour de la victoire exacte à 10000 :
/// - Une main pleine oblige à relancer, sans exception : y compris quand elle
///   tombe pile sur [winningScore]. Loin d'être une victoire, c'est une
///   impasse — tout relancer marquant dépasserait la cible — et le moteur la
///   sanctionne d'ailleurs en craque immédiat (voir [GameEngine.applyKeep]),
///   sans laisser ce banquage être proposé.
/// - Si banquer atteindrait exactement [winningScore], c'est sinon toujours
///   autorisé, y compris sur un score de tour finissant par 50 : cette
///   restriction-là existe pour éviter un arrêt "facile", pas pour empêcher
///   la victoire elle-même.
/// - Sinon, si banquer laisserait un total strictement inférieur à
///   [winningScore] mais à moins de [minimumRequired] de la cible, aucun
///   tour futur ne pourrait plus jamais valider exactement 10000 (le
///   minimum par tour l'en empêcherait toujours) : refusé, pour ne pas
///   piéger le joueur dans une position de victoire déjà mathématiquement
///   impossible sans qu'il l'ait choisi explicitement en craquant.
BankAttempt tryBank(TurnState state, {required int minimumRequired, required int currentTotal}) {
  if (state.pendingRoll != null) {
    throw StateError('Une décision est en attente sur le lancer précédent');
  }
  if (!state.hasRolledThisTurn) {
    return const BankAttempt.failure(BankFailureReason.notRolledYet);
  }

  // Testé AVANT la victoire exacte : une main pleine ne peut jamais être
  // banquée, même pile sur 10000 (voir la doc ci-dessus).
  if (state.mustContinue) {
    return const BankAttempt.failure(BankFailureReason.mustContinueHotDice);
  }

  final newTotal = currentTotal + state.bankedScore;
  if (newTotal == winningScore) {
    return BankAttempt.success(state.bankedScore);
  }
  if (state.bankedScore < minimumRequired) {
    return const BankAttempt.failure(BankFailureReason.belowMinimum);
  }
  if (state.turnScoreEndsIn50 == 50) {
    return const BankAttempt.failure(BankFailureReason.endsIn50);
  }
  if (newTotal > winningScore - minimumRequired) {
    return const BankAttempt.failure(BankFailureReason.wouldMakeWinningImpossible);
  }
  return BankAttempt.success(state.bankedScore);
}
