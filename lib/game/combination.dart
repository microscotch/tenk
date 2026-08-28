/// Un groupe de dés scorant issus d'un même lancer (brelan/carré/quinte,
/// suite, ou dés isolés de même valeur regroupés ensemble).
class ScoringGroup {
  /// Valeur des dés du groupe (1 à 6), ou 0 pour une suite.
  final int value;
  final int diceCount;
  final int points;
  final bool isSuite;

  /// Un groupe "déclinable" peut être laissé de côté par le joueur pour être
  /// relancé au lieu d'être encaissé (uniquement les 5 isolés hors combo).
  final bool declinable;

  const ScoringGroup({
    required this.value,
    required this.diceCount,
    required this.points,
    this.isSuite = false,
    this.declinable = false,
  });
}

/// Analyse d'un lancer de dés : la liste des groupes scorants qu'il contient,
/// et le nombre de dés "junk" qui ne rapportent jamais rien sur ce lancer.
class RollAnalysis {
  /// Faces brutes telles que lancées (pour l'affichage des dés côté UI).
  final List<int> faces;
  final List<ScoringGroup> groups;
  final int junkDiceCount;
  final int totalDiceRolled;

  const RollAnalysis({
    required this.faces,
    required this.groups,
    required this.junkDiceCount,
    required this.totalDiceRolled,
  });

  List<ScoringGroup> get mandatoryGroups =>
      groups.where((g) => !g.declinable).toList(growable: false);

  ScoringGroup? get declinableFives {
    for (final g in groups) {
      if (g.declinable) return g;
    }
    return null;
  }

  bool get hasAnyScore => groups.isNotEmpty;

  /// Le rejet des 5 isolés n'est possible que s'il reste au moins un dé
  /// "junk" dans ce lancer pour les accompagner au relancer.
  bool get canDeclineFives => declinableFives != null && junkDiceCount >= 1;
}

/// Analyse un lancer de dés et calcule les groupes scorants qu'il contient.
///
/// [extendedValues] contient les valeurs pour lesquelles un brelan ou un
/// carré a déjà été encaissé plus tôt dans le même tour : un dé isolé
/// supplémentaire de l'une de ces valeurs rapporte alors 100 points (règle
/// d'extension), y compris pour la valeur 5 (qui vaut alors 100 au lieu de
/// 50).
RollAnalysis analyzeRoll(List<int> faces, {Set<int> extendedValues = const {}}) {
  final n = faces.length;
  final counts = List<int>.filled(7, 0); // index 1..6, 0 inutilisé
  for (final f in faces) {
    counts[f]++;
  }

  // La suite n'existe que sur un lancer de 5 dés distincts consécutifs.
  if (n == 5) {
    final unique = faces.toSet();
    final isLowStraight = unique.length == 5 && unique.containsAll(const {1, 2, 3, 4, 5});
    final isHighStraight = unique.length == 5 && unique.containsAll(const {2, 3, 4, 5, 6});
    if (isLowStraight || isHighStraight) {
      return RollAnalysis(
        faces: faces,
        groups: const [ScoringGroup(value: 0, diceCount: 5, points: 500, isSuite: true)],
        junkDiceCount: 0,
        totalDiceRolled: 5,
      );
    }
  }

  final groups = <ScoringGroup>[];
  var accounted = 0;

  for (var v = 1; v <= 6; v++) {
    final c = counts[v];
    if (c == 0) continue;

    if (c >= 3) {
      groups.add(ScoringGroup(value: v, diceCount: c, points: _comboPoints(v, c)));
      accounted += c;
      continue;
    }

    // Dés isolés (1 ou 2 exemplaires, hors combo).
    if (v == 1) {
      groups.add(ScoringGroup(value: 1, diceCount: c, points: c * 100));
      accounted += c;
    } else if (v == 5) {
      final perDie = extendedValues.contains(5) ? 100 : 50;
      groups.add(ScoringGroup(
        value: 5,
        diceCount: c,
        points: c * perDie,
        declinable: true,
      ));
      accounted += c;
    } else if (extendedValues.contains(v)) {
      groups.add(ScoringGroup(value: v, diceCount: c, points: c * 100));
      accounted += c;
    }
    // Sinon : dés "junk", ne rapportent rien et ne sont jamais comptés.
  }

  return RollAnalysis(
    faces: faces,
    groups: groups,
    junkDiceCount: n - accounted,
    totalDiceRolled: n,
  );
}

int _comboPoints(int value, int count) {
  switch (count) {
    case 3:
      return value == 1 ? 1000 : value * 100;
    case 4:
      return value == 1 ? 2000 : value * 100 + 1000;
    case 5:
      return value == 1 ? 10000 : value * 1000;
    default:
      throw ArgumentError('Comptage de combo invalide: $count');
  }
}
