/// Score minimum requis pour "entrer" dans la partie.
const int entryThreshold = 500;

/// Score minimum requis par tour une fois entré dans la partie.
const int normalThreshold = 200;

/// Score exact à atteindre pour gagner la partie.
const int winningScore = 10000;

/// Une ligne de la grille de score d'un joueur : un score validé, avec son
/// éventuel tiret d'avertissement ou son statut barré. Une fois créée, une
/// entrée n'est jamais supprimée de la grille : le tiret ou le barré adhère
/// à cette ligne précise et y reste affiché même après que d'autres tours
/// ont été validés par la suite.
class ScoreEntry {
  final int value;
  final bool hasTiret;
  final bool isBarred;

  const ScoreEntry(this.value, {this.hasTiret = false, this.isBarred = false});

  ScoreEntry copyWith({bool? hasTiret, bool? isBarred}) {
    return ScoreEntry(
      value,
      hasTiret: hasTiret ?? this.hasTiret,
      isBarred: isBarred ?? this.isBarred,
    );
  }
}

/// Un joueur et sa grille de score complète.
///
/// Le mécanisme du "tiret" fonctionne ainsi : un craque marque la ligne
/// courante de la grille d'un tiret d'avertissement si elle n'en portait pas
/// déjà. Un tour réussi validé ensuite ajoute une NOUVELLE ligne (sans
/// tiret) : le tiret d'une ligne plus ancienne reste affiché sur cette
/// ligne-là, mais n'a plus d'effet — c'est toujours la ligne courante qui
/// reçoit le prochain tiret ou barré. Si la ligne courante porte déjà un
/// tiret au moment d'un nouveau craque, elle est barrée et le score revient
/// à la ligne précédente (une nouvelle ligne, propre, y est ajoutée pour
/// pouvoir continuer à jouer).
///
/// Un score peut aussi être barré par un autre mécanisme, indépendant du
/// tiret : si un autre joueur termine son tour exactement sur le même score,
/// ce joueur-ci se retrouve barré (voir [applyScoreCollisionBar]), qu'il
/// porte ou non un tiret.
class Player {
  final String name;
  final List<ScoreEntry> grid;
  final bool hasEntered;

  Player({
    required this.name,
    int totalScore = 0,
    int? previousScore,
    bool hasTiret = false,
    this.hasEntered = false,
  }) : grid = previousScore != null
            ? [ScoreEntry(previousScore), ScoreEntry(totalScore, hasTiret: hasTiret)]
            : [ScoreEntry(totalScore, hasTiret: hasTiret)];

  Player._raw({required this.name, required this.grid, required this.hasEntered});

  ScoreEntry get currentEntry => grid.last;
  int get totalScore => currentEntry.value;
  bool get hasTiret => currentEntry.hasTiret;

  /// Score de la ligne précédant la ligne courante dans la grille (0 s'il
  /// n'y en a pas). Pratique pour les tests / la construction directe d'un
  /// [Player] dans un état donné.
  int get previousScore => grid.length >= 2 ? grid[grid.length - 2].value : 0;

  int get minimumForNextTurn => hasEntered ? normalThreshold : entryThreshold;

  /// Applique un tour validé avec succès (le contrôle du minimum requis et
  /// de la règle du 50 a déjà été fait au niveau du moteur de tour) : ajoute
  /// une nouvelle ligne à la grille.
  Player applySuccessfulTurn(int points) {
    return Player._raw(
      name: name,
      grid: [...grid, ScoreEntry(totalScore + points)],
      hasEntered: true,
    );
  }

  /// Applique un craque : marque la ligne courante d'un tiret si elle n'en
  /// portait pas déjà, ou la barre sinon.
  Player applyBust() {
    if (!hasTiret) {
      final marked = List<ScoreEntry>.of(grid);
      marked[marked.length - 1] = currentEntry.copyWith(hasTiret: true);
      return Player._raw(name: name, grid: marked, hasEntered: hasEntered);
    }
    return _bar();
  }

  /// Applique un score barré suite à une collision : un autre joueur vient
  /// de terminer son tour avec exactement le même score que celui-ci. Barre
  /// toujours la ligne courante, qu'elle porte ou non un tiret.
  Player applyScoreCollisionBar() => _bar();

  Player _bar() {
    final previousValue = grid.length >= 2 ? grid[grid.length - 2].value : 0;
    final newGrid = List<ScoreEntry>.of(grid);
    newGrid[newGrid.length - 1] = currentEntry.copyWith(isBarred: true);
    newGrid.add(ScoreEntry(previousValue));
    // Un retour à 0 remet l'entrée en jeu à zéro : il faudra de nouveau
    // marquer au moins 500 points en un tour pour entrer à nouveau.
    return Player._raw(name: name, grid: newGrid, hasEntered: previousValue == 0 ? false : hasEntered);
  }
}
