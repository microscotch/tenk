/// Score minimum requis pour "entrer" dans la partie.
const int entryThreshold = 500;

/// Score minimum requis par tour une fois entré dans la partie.
const int normalThreshold = 200;

/// Score exact à atteindre pour gagner la partie.
const int winningScore = 10000;

/// Un joueur et son état de score.
///
/// Le mécanisme du "tiret" fonctionne ainsi : le premier craque après un
/// score validé marque ce score d'un tiret d'avertissement ([hasTiret]).
/// Ce tiret ne disparaît jamais tout seul (même si le joueur réussit des
/// tours entre-temps). S'il craque une seconde fois alors qu'il porte déjà
/// un tiret, son score est "barré" : il retombe d'un seul cran, au score
/// d'avant le dernier tour validé ([previousScore]), et le cycle recommence.
///
/// Un score peut aussi être barré par un autre mécanisme, indépendant du
/// tiret : si un autre joueur termine son tour exactement sur le même score,
/// ce joueur-ci se retrouve barré (voir [applyScoreCollisionBar]), qu'il
/// porte ou non un tiret.
class Player {
  final String name;
  final int totalScore;

  /// Score d'avant le dernier tour validé, utilisé comme point de retour en
  /// cas de score barré (un seul cran en arrière, jamais plus).
  final int previousScore;
  final bool hasEntered;
  final bool hasTiret;

  const Player({
    required this.name,
    this.totalScore = 0,
    this.previousScore = 0,
    this.hasEntered = false,
    this.hasTiret = false,
  });

  int get minimumForNextTurn => hasEntered ? normalThreshold : entryThreshold;

  Player copyWith({
    int? totalScore,
    int? previousScore,
    bool? hasEntered,
    bool? hasTiret,
  }) {
    return Player(
      name: name,
      totalScore: totalScore ?? this.totalScore,
      previousScore: previousScore ?? this.previousScore,
      hasEntered: hasEntered ?? this.hasEntered,
      hasTiret: hasTiret ?? this.hasTiret,
    );
  }

  /// Applique un tour validé avec succès (le contrôle du minimum requis et
  /// de la règle du 50 a déjà été fait au niveau du moteur de tour).
  Player applySuccessfulTurn(int points) {
    return copyWith(
      previousScore: totalScore,
      totalScore: totalScore + points,
      hasEntered: true,
    );
  }

  /// Revient d'un cran en arrière (au score d'avant le dernier tour validé)
  /// et efface un éventuel tiret : c'est l'action de "barrer" un score,
  /// déclenchée soit par un second craque, soit par une collision de score.
  Player _bar() => copyWith(totalScore: previousScore, hasTiret: false);

  /// Applique un craque : marque un tiret la première fois, ou barre le
  /// score la seconde fois (s'il portait déjà un tiret).
  Player applyBust() {
    if (!hasTiret) {
      return copyWith(hasTiret: true);
    }
    return _bar();
  }

  /// Applique un score barré suite à une collision : un autre joueur vient
  /// de terminer son tour avec exactement le même score que celui-ci. Barre
  /// toujours, que ce joueur porte ou non un tiret.
  Player applyScoreCollisionBar() => _bar();
}
