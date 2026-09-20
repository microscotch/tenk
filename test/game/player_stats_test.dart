import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_stats.dart';

/// Le même type sert à une partie et à un cumul : ces tests portent surtout
/// sur l'addition, qui fait le pont entre les deux.
void main() {
  group('addition', () {
    test('somme les totaux et retient les extrema', () {
      const a = PlayerStats(
        gamesPlayed: 1,
        gamesWon: 1,
        totalActiveSeconds: 600,
        shortestActiveSeconds: 600,
        longestActiveSeconds: 600,
        bestBankedTurn: 1200,
        longestHotDiceRun: 2,
      );
      const b = PlayerStats(
        gamesPlayed: 1,
        totalActiveSeconds: 900,
        shortestActiveSeconds: 900,
        longestActiveSeconds: 900,
        bestBankedTurn: 800,
        longestHotDiceRun: 3,
      );

      final total = a + b;

      expect(total.gamesPlayed, 2);
      expect(total.gamesWon, 1);
      expect(total.gamesLost, 1);
      expect(total.totalActiveSeconds, 1500);
      expect(total.shortestActiveSeconds, 600, reason: 'le minimum des deux');
      expect(total.longestActiveSeconds, 900, reason: 'le maximum des deux');
      expect(total.bestBankedTurn, 1200, reason: 'un maximum, pas une somme');
      expect(total.longestHotDiceRun, 3);
    });

    test('est associative : l\'ordre des parties repliées ne change rien', () {
      const a = PlayerStats(gamesPlayed: 1, totalActiveSeconds: 100, shortestActiveSeconds: 100, brelans: {4: 1});
      const b = PlayerStats(gamesPlayed: 1, totalActiveSeconds: 200, shortestActiveSeconds: 200, brelans: {4: 2});
      const c = PlayerStats(gamesPlayed: 1, totalActiveSeconds: 300, shortestActiveSeconds: 300, brelans: {2: 1});

      final left = (a + b) + c;
      final right = a + (b + c);

      expect(left.toJson(), right.toJson(),
          reason: 'indispensable pour qu\'un recalcul rétroactif soit reproductible');
    });

    test('l\'élément neutre ne modifie rien', () {
      const a = PlayerStats(gamesPlayed: 3, gamesWon: 2, shortestActiveSeconds: 42, quintes: {1: 1});

      expect((a + PlayerStats.empty).toJson(), a.toJson());
      expect((PlayerStats.empty + a).toJson(), a.toJson());
    });

    test('cumule les ventilations par valeur de dé', () {
      const a = PlayerStats(brelans: {4: 2, 6: 1}, carres: {1: 1});
      const b = PlayerStats(brelans: {4: 1, 2: 5}, carres: {1: 2});

      final total = a + b;

      expect(total.brelans, {4: 3, 6: 1, 2: 5});
      expect(total.brelansTotal, 9);
      expect(total.carres, {1: 3});
    });
  });

  group('grandeurs dérivées', () {
    test('sans aucune partie, les moyennes et les bornes valent null', () {
      const stats = PlayerStats.empty;

      expect(stats.averageActiveSeconds, isNull, reason: 'une moyenne sur zéro partie n\'existe pas');
      expect(stats.shortestActiveSeconds, isNull);
      expect(stats.longestActiveSeconds, isNull);
      expect(stats.averageBustStreak, isNull);
      expect(stats.averageSelfBarsPerGame, isNull);
      expect(stats.gamesLost, 0);
    });

    test('les moyennes se calculent depuis les totaux', () {
      const stats = PlayerStats(
        gamesPlayed: 4,
        totalActiveSeconds: 1000,
        bustsTotal: 9,
        bustStreakCount: 3,
        selfBarsTotal: 2,
        barsInflictedTotal: 6,
      );

      expect(stats.averageActiveSeconds, 250);
      expect(stats.averageBustStreak, 3, reason: '9 craquages répartis en 3 séries');
      expect(stats.averageSelfBarsPerGame, 0.5);
      expect(stats.averageBarsInflictedPerGame, 1.5);
    });

    test('les totaux de figures se déduisent de leur ventilation', () {
      const stats = PlayerStats(
        quintes: {1: 1, 5: 2},
        petitesSuites: 3,
        grandesSuites: 4,
        quintesDAsReussies: 1,
        quintesDAsPerdues: 2,
      );

      expect(stats.quintesTotal, 3);
      expect(stats.suitesTotal, 7);
      expect(stats.quintesDAsTotal, 3);
    });
  });

  group('sérialisation', () {
    test('aller-retour complet', () {
      const stats = PlayerStats(
        gamesPlayed: 5,
        gamesWon: 2,
        totalActiveSeconds: 3600,
        shortestActiveSeconds: 300,
        longestActiveSeconds: 1800,
        keptLoneAces: 12,
        keptLoneFives: 30,
        brelans: {1: 2, 4: 5},
        carres: {6: 1},
        quintes: {1: 1},
        petitesSuites: 2,
        grandesSuites: 1,
        quintesDAsReussies: 1,
        quintesDAsPerdues: 3,
        bestBankedTurn: 2500,
        longestHotDiceRun: 4,
        bustsTotal: 20,
        longestBustStreak: 4,
        bustStreakCount: 8,
        selfBarsTotal: 3,
        selfBarsMaxInGame: 2,
        barsInflictedTotal: 5,
        barsInflictedMaxInGame: 3,
      );

      final restored = PlayerStats.fromJson(stats.toJson());

      expect(restored.toJson(), stats.toJson());
      expect(restored.brelans, {1: 2, 4: 5}, reason: 'clés numériques restituées');
    });

    test('un champ absent retombe sur sa valeur par défaut', () {
      final restored = PlayerStats.fromJson(const {'gamesPlayed': 2});

      expect(restored.gamesPlayed, 2);
      expect(restored.bestBankedTurn, 0);
      expect(restored.brelans, isEmpty);
      expect(restored.shortestActiveSeconds, isNull,
          reason: 'une borne absente reste absente, surtout pas 0');
    });
  });
}
