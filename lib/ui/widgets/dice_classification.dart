import '../../game/combination.dart';
import 'die_widget.dart';

/// Détermine l'état visuel de chaque dé d'un lancer, en tenant compte du
/// nombre de 5 que le joueur envisage de garder (aperçu avant validation).
List<DieVisualState> classifyDiceForDisplay(
  RollAnalysis analysis,
  int selectedKeepCount,
) {
  if (analysis.groups.any((g) => g.isSuite)) {
    return List.filled(analysis.faces.length, DieVisualState.kept);
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] =
        (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }

  final fives = analysis.declinableFives;
  var keepRemaining = selectedKeepCount;

  return [
    for (final v in analysis.faces)
      if ((mandatoryRemaining[v] ?? 0) > 0)
        _consume(mandatoryRemaining, v, _mandatoryVisualState(analysis, v))
      else if (fives != null && v == 5)
        (() {
          if (keepRemaining > 0) {
            keepRemaining--;
            final perDie = fives.points ~/ fives.diceCount;
            return perDie == 100
                ? DieVisualState.extended
                : DieVisualState.kept;
          }
          return DieVisualState.declined;
        })()
      else
        DieVisualState.junk,
  ];
}

DieVisualState _mandatoryVisualState(RollAnalysis analysis, int value) {
  final g = analysis.mandatoryGroups.firstWhere((g) => g.value == value);
  // Un groupe obligatoire isolé (moins de 3 dés) de valeur non-as ne peut
  // exister que via la règle d'extension : ses points sont "temporaires".
  final isExtended = g.diceCount < 3 && g.value != 1;
  return isExtended ? DieVisualState.extended : DieVisualState.kept;
}

DieVisualState _consume(
  Map<int, int> remaining,
  int value,
  DieVisualState result,
) {
  remaining[value] = remaining[value]! - 1;
  return result;
}
