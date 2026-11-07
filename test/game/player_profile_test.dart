import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';

void main() {
  group('normalizeName', () {
    test('neutralise casse, accents et espaces superflus', () {
      expect(normalizeName('Rémi'), normalizeName('remi'));
      expect(normalizeName('  RÉMI  '), normalizeName('Rémi'));
      expect(normalizeName('Jean  Pierre'), 'jean pierre', reason: 'espaces resserrés');
      expect(normalizeName('Benoît'), 'benoit');
      expect(normalizeName('Lœtitia'), 'loetitia');
    });

    test('distingue deux noms réellement différents', () {
      expect(normalizeName('Marie') == normalizeName('Maria'), isFalse);
    });
  });

  group('création', () {
    test('attribue une identité et nettoie les champs', () {
      final player = PlayerProfile.create(name: '  Marie  ', nickname: '  ');

      expect(player.id, isNotEmpty);
      expect(player.name, 'Marie', reason: 'nom rogné');
      expect(player.nickname, isNull, reason: 'un surnom vide vaut pas de surnom');
      expect(player.rightHanded, isTrue, reason: 'droitier par défaut');
      expect(player.avatarColor, isNull, reason: 'couleur automatique par défaut');
      expect(player.avatarAnimal, isNull, reason: 'la lettre par défaut');
      expect(player.stats.gamesPlayed, 0);
    });

    test('deux fiches créées coup sur coup ont des identités distinctes', () {
      final a = PlayerProfile.create(name: 'A');
      final b = PlayerProfile.create(name: 'B');

      expect(a.id, isNot(b.id));
    });
  });

  group('pastille', () {
    test('la couleur et l\'animal se choisissent, se changent et s\'effacent', () {
      final base = PlayerProfile.create(name: 'Marie');
      final chosen = base.copyWith(avatarColor: 'teal', avatarAnimal: 'fox');
      expect(chosen.avatarColor, 'teal');
      expect(chosen.avatarAnimal, 'fox');

      expect(chosen.copyWith(name: 'Maria').avatarColor, 'teal', reason: 'un autre champ ne les efface pas');
      expect(chosen.copyWith(clearAvatarColor: true).avatarColor, isNull);
      expect(chosen.copyWith(clearAvatarAnimal: true).avatarAnimal, isNull);
      expect(chosen.copyWith(clearAvatarAnimal: true).avatarColor, 'teal');
    });

    test('ils survivent à l\'écriture et à la lecture', () {
      final chosen = PlayerProfile.create(name: 'Marie', avatarColor: 'rose', avatarAnimal: 'owl');
      final back = PlayerProfile.fromJson(chosen.toJson());
      expect(back.avatarColor, 'rose');
      expect(back.avatarAnimal, 'owl');
    });

    test('une fiche d\'avant les pastilles se lit sans couleur ni animal', () {
      final old = PlayerProfile.fromJson({'id': 'x', 'name': 'Marie', 'avatarRef': null});
      expect(old.avatarColor, isNull);
      expect(old.avatarAnimal, isNull);
    });
  });

  group('renommage', () {
    test('conserve l\'ancien nom, sans quoi l\'historique archivé serait perdu', () {
      final player = PlayerProfile.create(name: 'Marie').renamedTo('Marie Curie');

      expect(player.name, 'Marie Curie');
      expect(player.formerNames, ['Marie']);
      expect(player.allNames, ['Marie Curie', 'Marie'],
          reason: 'les archives ne contiennent que des noms : il faut tous les connaître');
    });

    test('une simple correction de casse ou d\'accent n\'ajoute pas d\'ancien nom', () {
      final player = PlayerProfile.create(name: 'remi').renamedTo('Rémi');

      expect(player.name, 'Rémi');
      expect(player.formerNames, isEmpty, reason: 'c\'est la même personne écrite autrement');
    });

    test('un aller-retour ne duplique pas le nom repris', () {
      final player = PlayerProfile.create(name: 'Marie').renamedTo('Sophie').renamedTo('Marie');

      expect(player.name, 'Marie');
      expect(player.formerNames, ['Sophie']);
    });
  });

  test('le nom affiché privilégie le surnom', () {
    final withNickname = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
    final without = PlayerProfile.create(name: 'Marie Curie');

    expect(withNickname.displayName, 'Mimi');
    expect(without.displayName, 'Marie Curie');
  });

  group('sérialisation', () {
    test('aller-retour complet, statistiques comprises', () {
      final player = PlayerProfile.create(name: 'Marie', nickname: 'Mimi', rightHanded: false, autoRoll: true)
          .renamedTo('Marie Curie')
          .copyWith(stats: const PlayerStats(gamesPlayed: 3, gamesWon: 1, brelans: {4: 2}));

      final restored = PlayerProfile.fromJson(player.toJson());

      expect(restored.id, player.id);
      expect(restored.name, 'Marie Curie');
      expect(restored.nickname, 'Mimi');
      expect(restored.rightHanded, isFalse);
      expect(restored.autoRoll, isTrue);
      expect(restored.formerNames, ['Marie']);
      expect(restored.stats.gamesPlayed, 3);
      expect(restored.stats.brelans, {4: 2});
    });

    test('une fiche d\'ancienne facture se relit avec ses valeurs par défaut', () {
      final restored = PlayerProfile.fromJson(const {'id': 'abc', 'name': 'Bob'});

      expect(restored.nickname, isNull);
      expect(restored.rightHanded, isTrue);
      expect(restored.autoRoll, isFalse, reason: 'jamais d\'AutoRoll sur une fiche qui n\'en parle pas');
      expect(restored.formerNames, isEmpty);
      expect(restored.stats.gamesPlayed, 0);
    });
  });
}
