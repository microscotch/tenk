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
/// ont été validés par la suite, ou qu'un barrage ultérieur ait ramené la
/// ligne courante dessus (voir [Player.currentIndex]).
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
/// courante d'un tiret d'avertissement si elle n'en a pas déjà un actif. Un
/// tour réussi validé ensuite ajoute une NOUVELLE ligne (sans tiret actif) et
/// en fait la ligne courante ; l'ancienne ligne garde son tiret affiché dans
/// la grille (historique), mais celui-ci n'a plus d'effet. Si la ligne
/// courante a déjà un tiret actif au moment d'un nouveau craque, elle est
/// barrée et [currentIndex] recule vers la ligne précédente déjà existante
/// dans la grille (jamais de nouvelle ligne dupliquant le même score) ; cette
/// ligne redevient courante avec un cycle de tiret entièrement frais, même si
/// elle affiche encore un tiret historique d'un cycle antérieur.
///
/// Un score peut aussi être barré par un autre mécanisme, indépendant du
/// tiret : si un autre joueur termine son tour exactement sur le même score,
/// ce joueur-ci se retrouve barré (voir [applyScoreCollisionBar]), qu'il
/// porte ou non un tiret actif.
class Player {
  final String name;
  final List<ScoreEntry> grid;

  /// Index dans [grid] de la ligne actuellement "vivante" (celle que
  /// [totalScore] expose). Recule d'un cran vers une ligne déjà existante à
  /// chaque barrage plutôt que de dupliquer une ligne ; avance vers une
  /// toute nouvelle ligne à chaque tour réussi.
  final int currentIndex;

  /// Tiret actif du cycle en cours sur la ligne courante, distinct du
  /// [ScoreEntry.hasTiret] historique affiché dans la grille : un retour à
  /// une ligne déjà existante (barrage) démarre toujours un cycle frais, même
  /// si cette ligne affiche encore un tiret historique d'un cycle antérieur.
  final bool _currentHasTiret;

  final bool hasEntered;

  Player({
    required this.name,
    int totalScore = 0,
    int? previousScore,
    bool hasTiret = false,
    this.hasEntered = false,
  })  : grid = previousScore != null
            ? [ScoreEntry(previousScore), ScoreEntry(totalScore, hasTiret: hasTiret)]
            : [ScoreEntry(totalScore, hasTiret: hasTiret)],
        currentIndex = previousScore != null ? 1 : 0,
        _currentHasTiret = hasTiret;

  Player._raw({
    required this.name,
    required this.grid,
    required this.currentIndex,
    required this._currentHasTiret,
    required this.hasEntered,
  });

  ScoreEntry get currentEntry => grid[currentIndex];
  int get totalScore => currentEntry.value;
  bool get hasTiret => _currentHasTiret;

  /// Score de la ligne précédant la ligne courante dans la grille (0 s'il
  /// n'y en a pas). Pratique pour les tests / la construction directe d'un
  /// [Player] dans un état donné.
  int get previousScore => currentIndex >= 1 ? grid[currentIndex - 1].value : 0;

  /// Ligne précédant la ligne courante dans la grille (null s'il n'y en a
  /// pas), avec son éventuel tiret/barré historique — pour afficher l'état
  /// de sanction du score précédent, indépendamment du cycle en cours sur
  /// la ligne courante (voir [hasTiret]).
  ScoreEntry? get previousEntry => currentIndex >= 1 ? grid[currentIndex - 1] : null;

  /// Dernière ligne non barrée avant la ligne courante, en remontant
  /// au-delà des lignes barrées (qui ne représentent plus un score valide) :
  /// null s'il n'en reste aucune. Contrairement à [previousEntry] (toujours
  /// la ligne juste avant, utilisée en interne pour le repli du barrage),
  /// c'est celle-ci qu'il faut afficher comme "score précédent" à l'écran.
  ScoreEntry? get lastUnbarredEntry {
    for (var i = currentIndex - 1; i >= 0; i--) {
      if (!grid[i].isBarred) return grid[i];
    }
    return null;
  }

  int get minimumForNextTurn => hasEntered ? normalThreshold : entryThreshold;

  /// Applique un tour validé avec succès (le contrôle du minimum requis et
  /// de la règle du 50 a déjà été fait au niveau du moteur de tour) : ajoute
  /// une nouvelle ligne à la grille et en fait la ligne courante.
  Player applySuccessfulTurn(int points) {
    final newGrid = [...grid, ScoreEntry(totalScore + points)];
    return Player._raw(
      name: name,
      grid: newGrid,
      currentIndex: newGrid.length - 1,
      currentHasTiret: false,
      hasEntered: true,
    );
  }

  /// Applique un craque : marque la ligne courante d'un tiret si elle n'en a
  /// pas déjà un actif, ou la barre sinon. Un craque à 0 ne marque jamais de
  /// tiret : il n'y a rien à sanctionner en dessous du plancher.
  Player applyBust() {
    if (totalScore == 0) return this;
    if (!hasTiret) {
      final marked = List<ScoreEntry>.of(grid);
      marked[currentIndex] = currentEntry.copyWith(hasTiret: true);
      return Player._raw(
        name: name,
        grid: marked,
        currentIndex: currentIndex,
        currentHasTiret: true,
        hasEntered: hasEntered,
      );
    }
    return _bar();
  }

  /// Applique un score barré suite à une collision : un autre joueur vient
  /// de terminer son tour avec exactement le même score que celui-ci. Barre
  /// toujours la ligne courante, qu'elle porte ou non un tiret actif.
  Player applyScoreCollisionBar() => _bar();

  Player _bar() {
    final newGrid = List<ScoreEntry>.of(grid);
    newGrid[currentIndex] = currentEntry.copyWith(isBarred: true);
    final fallbackIndex = currentIndex > 0 ? currentIndex - 1 : 0;
    final fallbackValue = newGrid[fallbackIndex].value;
    // Un retour à 0 remet l'entrée en jeu à zéro : il faudra de nouveau
    // marquer au moins 500 points en un tour pour entrer à nouveau.
    return Player._raw(
      name: name,
      grid: newGrid,
      currentIndex: fallbackIndex,
      currentHasTiret: false,
      hasEntered: fallbackValue == 0 ? false : hasEntered,
    );
  }
}
