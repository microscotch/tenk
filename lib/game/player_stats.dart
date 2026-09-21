/// Statistiques de jeu accumulées par un joueur.
///
/// Le même type sert à DEUX usages : la contribution d'une seule partie, et le
/// cumul de toutes les parties d'une fiche. L'addition ([operator +]) fait le
/// pont entre les deux, ce qui garde en un seul endroit la façon de combiner
/// chaque grandeur — somme, maximum ou minimum selon sa nature — et rend le
/// cumul associatif : l'ordre dans lequel les parties sont repliées n'a aucune
/// importance, ce qui est indispensable pour un recalcul rétroactif.
///
/// Seuls des TOTAUX et des extrema sont stockés ; les moyennes sont calculées
/// à la lecture (voir les accesseurs dérivés). Une fiche ne peut donc jamais
/// devenir incohérente en voyant sa moyenne et son total diverger.
class PlayerStats {
  /// Parties menées à leur terme auxquelles ce joueur a participé. Une partie
  /// abandonnée ne compte pas : elle n'a ni vainqueur ni durée définitive.
  final int gamesPlayed;
  final int gamesWon;

  /// Durée ACTIVE cumulée, hors interruptions (voir `activePlayingSecondsFor`
  /// dans `game_recording.dart`). C'est la durée de la partie, identique pour
  /// tous ses participants, et non le temps des tours de ce joueur.
  final int totalActiveSeconds;

  /// Bornes des durées de partie. `null` tant qu'aucune partie n'a été jouée —
  /// un minimum sur l'ensemble vide n'existe pas, et le représenter par 0
  /// ferait passer « aucune partie » pour « une partie instantanée ».
  final int? shortestActiveSeconds;
  final int? longestActiveSeconds;

  /// Dés isolés effectivement GARDÉS, comptés par dé et non par figure : un
  /// lancer montrant deux as isolés en compte deux. Un 5 décliné puis relancé
  /// n'est jamais compté, puisqu'il n'a pas été gardé.
  final int keptLoneAces;
  final int keptLoneFives;

  /// Figures par valeur de dé (1 à 6), comptées dès qu'elles SORTENT — même
  /// sur un lancer qui fait craquer par dépassement. Les figures étant de
  /// toute façon obligatoires à garder, l'écart avec « gardées » ne concerne
  /// que les lancers perdus.
  final Map<int, int> brelans;
  final Map<int, int> carres;
  final Map<int, int> quintes;

  final int petitesSuites;
  final int grandesSuites;

  /// Quintes d'as, la seule figure valant 10000 d'un coup. Réussie quand le
  /// joueur était encore à la niche (score à 0) : elle tombe alors pile sur la
  /// cible. Perdue sinon : elle dépasse et fait craquer.
  final int quintesDAsReussies;
  final int quintesDAsPerdues;

  /// Meilleur tour jamais banqué, mains pleines cumulées comprises.
  final int bestBankedTurn;

  /// Plus longue série de mains pleines enchaînées à l'intérieur d'un tour.
  final int longestHotDiceRun;

  /// Craquages : le total, la plus longue série de tours craqués d'affilée, et
  /// le nombre de séries — ce dernier n'existe que pour pouvoir donner la
  /// longueur MOYENNE d'une série sans la stocker (voir [averageBustStreak]).
  final int bustsTotal;
  final int longestBustStreak;
  final int bustStreakCount;

  /// Lignes barrées par son propre second craque consécutif.
  final int selfBarsTotal;
  final int selfBarsMaxInGame;

  /// Lignes barrées chez un adversaire par collision de score.
  final int barsInflictedTotal;
  final int barsInflictedMaxInGame;

  /// Lancers de dés, tous comptés : celui qui fait craquer, les relances de
  /// main pleine. Et tours terminés, banqués comme craqués — de quoi donner
  /// les lancers PAR TOUR sans stocker cette moyenne (voir
  /// [averageRollsPerTurn]).
  final int rollsTotal;
  final int turnsTotal;

  const PlayerStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalActiveSeconds = 0,
    this.shortestActiveSeconds,
    this.longestActiveSeconds,
    this.keptLoneAces = 0,
    this.keptLoneFives = 0,
    this.brelans = const {},
    this.carres = const {},
    this.quintes = const {},
    this.petitesSuites = 0,
    this.grandesSuites = 0,
    this.quintesDAsReussies = 0,
    this.quintesDAsPerdues = 0,
    this.bestBankedTurn = 0,
    this.longestHotDiceRun = 0,
    this.bustsTotal = 0,
    this.longestBustStreak = 0,
    this.bustStreakCount = 0,
    this.selfBarsTotal = 0,
    this.selfBarsMaxInGame = 0,
    this.barsInflictedTotal = 0,
    this.barsInflictedMaxInGame = 0,
    this.rollsTotal = 0,
    this.turnsTotal = 0,
  });

  static const empty = PlayerStats();

  /// Parties perdues : tout ce qui n'a pas été gagné. Pas de champ dédié, pour
  /// qu'un cumul ne puisse pas afficher jouées ≠ gagnées + perdues.
  int get gamesLost => gamesPlayed - gamesWon;

  int get brelansTotal => _sum(brelans);
  int get carresTotal => _sum(carres);
  int get quintesTotal => _sum(quintes);
  int get suitesTotal => petitesSuites + grandesSuites;
  int get quintesDAsTotal => quintesDAsReussies + quintesDAsPerdues;

  /// Moyennes, toutes dérivées : `null` quand elles n'ont pas de sens faute de
  /// partie (ou, pour les séries de craquages, faute de série).
  double? get averageActiveSeconds => gamesPlayed == 0 ? null : totalActiveSeconds / gamesPlayed;
  double? get averageBustStreak => bustStreakCount == 0 ? null : bustsTotal / bustStreakCount;
  double? get averageSelfBarsPerGame => gamesPlayed == 0 ? null : selfBarsTotal / gamesPlayed;
  double? get averageBarsInflictedPerGame =>
      gamesPlayed == 0 ? null : barsInflictedTotal / gamesPlayed;
  double? get averageRollsPerTurn => turnsTotal == 0 ? null : rollsTotal / turnsTotal;

  /// Replie une partie (ou un autre cumul) dans celui-ci. Chaque grandeur est
  /// combinée selon sa nature, et les bornes de durée absorbent proprement le
  /// `null` de l'opérande vide.
  PlayerStats operator +(PlayerStats other) {
    return PlayerStats(
      gamesPlayed: gamesPlayed + other.gamesPlayed,
      gamesWon: gamesWon + other.gamesWon,
      totalActiveSeconds: totalActiveSeconds + other.totalActiveSeconds,
      shortestActiveSeconds: _minOf(shortestActiveSeconds, other.shortestActiveSeconds),
      longestActiveSeconds: _maxOf(longestActiveSeconds, other.longestActiveSeconds),
      keptLoneAces: keptLoneAces + other.keptLoneAces,
      keptLoneFives: keptLoneFives + other.keptLoneFives,
      brelans: _mergeCounts(brelans, other.brelans),
      carres: _mergeCounts(carres, other.carres),
      quintes: _mergeCounts(quintes, other.quintes),
      petitesSuites: petitesSuites + other.petitesSuites,
      grandesSuites: grandesSuites + other.grandesSuites,
      quintesDAsReussies: quintesDAsReussies + other.quintesDAsReussies,
      quintesDAsPerdues: quintesDAsPerdues + other.quintesDAsPerdues,
      bestBankedTurn: bestBankedTurn > other.bestBankedTurn ? bestBankedTurn : other.bestBankedTurn,
      longestHotDiceRun:
          longestHotDiceRun > other.longestHotDiceRun ? longestHotDiceRun : other.longestHotDiceRun,
      bustsTotal: bustsTotal + other.bustsTotal,
      longestBustStreak:
          longestBustStreak > other.longestBustStreak ? longestBustStreak : other.longestBustStreak,
      bustStreakCount: bustStreakCount + other.bustStreakCount,
      selfBarsTotal: selfBarsTotal + other.selfBarsTotal,
      selfBarsMaxInGame:
          selfBarsMaxInGame > other.selfBarsMaxInGame ? selfBarsMaxInGame : other.selfBarsMaxInGame,
      barsInflictedTotal: barsInflictedTotal + other.barsInflictedTotal,
      barsInflictedMaxInGame: barsInflictedMaxInGame > other.barsInflictedMaxInGame
          ? barsInflictedMaxInGame
          : other.barsInflictedMaxInGame,
      rollsTotal: rollsTotal + other.rollsTotal,
      turnsTotal: turnsTotal + other.turnsTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'totalActiveSeconds': totalActiveSeconds,
        'shortestActiveSeconds': shortestActiveSeconds,
        'longestActiveSeconds': longestActiveSeconds,
        'keptLoneAces': keptLoneAces,
        'keptLoneFives': keptLoneFives,
        'brelans': _countsToJson(brelans),
        'carres': _countsToJson(carres),
        'quintes': _countsToJson(quintes),
        'petitesSuites': petitesSuites,
        'grandesSuites': grandesSuites,
        'quintesDAsReussies': quintesDAsReussies,
        'quintesDAsPerdues': quintesDAsPerdues,
        'bestBankedTurn': bestBankedTurn,
        'longestHotDiceRun': longestHotDiceRun,
        'bustsTotal': bustsTotal,
        'longestBustStreak': longestBustStreak,
        'bustStreakCount': bustStreakCount,
        'selfBarsTotal': selfBarsTotal,
        'selfBarsMaxInGame': selfBarsMaxInGame,
        'barsInflictedTotal': barsInflictedTotal,
        'barsInflictedMaxInGame': barsInflictedMaxInGame,
        'rollsTotal': rollsTotal,
        'turnsTotal': turnsTotal,
      };

  /// Lecture tolérante : tout champ absent retombe sur sa valeur par défaut,
  /// pour qu'ajouter une statistique plus tard ne rende pas illisibles les
  /// fiches déjà enregistrées.
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    int at(String key) => json[key] as int? ?? 0;
    return PlayerStats(
      gamesPlayed: at('gamesPlayed'),
      gamesWon: at('gamesWon'),
      totalActiveSeconds: at('totalActiveSeconds'),
      shortestActiveSeconds: json['shortestActiveSeconds'] as int?,
      longestActiveSeconds: json['longestActiveSeconds'] as int?,
      keptLoneAces: at('keptLoneAces'),
      keptLoneFives: at('keptLoneFives'),
      brelans: _countsFromJson(json['brelans']),
      carres: _countsFromJson(json['carres']),
      quintes: _countsFromJson(json['quintes']),
      petitesSuites: at('petitesSuites'),
      grandesSuites: at('grandesSuites'),
      quintesDAsReussies: at('quintesDAsReussies'),
      quintesDAsPerdues: at('quintesDAsPerdues'),
      bestBankedTurn: at('bestBankedTurn'),
      longestHotDiceRun: at('longestHotDiceRun'),
      bustsTotal: at('bustsTotal'),
      longestBustStreak: at('longestBustStreak'),
      bustStreakCount: at('bustStreakCount'),
      selfBarsTotal: at('selfBarsTotal'),
      selfBarsMaxInGame: at('selfBarsMaxInGame'),
      barsInflictedTotal: at('barsInflictedTotal'),
      barsInflictedMaxInGame: at('barsInflictedMaxInGame'),
      rollsTotal: at('rollsTotal'),
      turnsTotal: at('turnsTotal'),
    );
  }
}

int _sum(Map<int, int> counts) => counts.values.fold(0, (a, b) => a + b);

int? _minOf(int? a, int? b) => a == null ? b : (b == null ? a : (a < b ? a : b));
int? _maxOf(int? a, int? b) => a == null ? b : (b == null ? a : (a > b ? a : b));

Map<int, int> _mergeCounts(Map<int, int> a, Map<int, int> b) {
  final merged = <int, int>{...a};
  b.forEach((value, count) => merged[value] = (merged[value] ?? 0) + count);
  return merged;
}

/// Clés converties en chaînes, comme `aiPlayers` dans `SavedGame` : JSON
/// n'admet pas de clé numérique.
Map<String, int> _countsToJson(Map<int, int> counts) =>
    counts.map((value, count) => MapEntry(value.toString(), count));

Map<int, int> _countsFromJson(Object? raw) {
  if (raw is! Map) return const {};
  return raw.map((value, count) => MapEntry(int.parse(value as String), count as int));
}
