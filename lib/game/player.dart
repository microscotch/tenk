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
/// un tiret, son score est "barré" : il retombe à [preTiretScore], le
/// dernier score non barré (celui d'avant le tiret), et le cycle recommence.
class Player {
  final String name;
  final int totalScore;
  final bool hasEntered;
  final bool hasTiret;
  final int? preTiretScore;

  const Player({
    required this.name,
    this.totalScore = 0,
    this.hasEntered = false,
    this.hasTiret = false,
    this.preTiretScore,
  });

  int get minimumForNextTurn => hasEntered ? normalThreshold : entryThreshold;

  Player copyWith({
    int? totalScore,
    bool? hasEntered,
    bool? hasTiret,
    int? preTiretScore,
    bool clearPreTiretScore = false,
  }) {
    return Player(
      name: name,
      totalScore: totalScore ?? this.totalScore,
      hasEntered: hasEntered ?? this.hasEntered,
      hasTiret: hasTiret ?? this.hasTiret,
      preTiretScore: clearPreTiretScore ? null : (preTiretScore ?? this.preTiretScore),
    );
  }

  /// Applique un tour validé avec succès (le contrôle du minimum requis et
  /// de la règle du 50 a déjà été fait au niveau du moteur de tour).
  Player applySuccessfulTurn(int points) {
    return copyWith(totalScore: totalScore + points, hasEntered: true);
  }

  /// Applique un craque : marque un tiret la première fois, ou barre le
  /// score (retour au dernier score non barré) la seconde fois.
  Player applyBust() {
    if (!hasTiret) {
      return copyWith(hasTiret: true, preTiretScore: totalScore);
    }
    return Player(
      name: name,
      totalScore: preTiretScore!,
      hasEntered: hasEntered,
      hasTiret: false,
      preTiretScore: null,
    );
  }
}
