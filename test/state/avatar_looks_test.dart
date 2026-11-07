import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/avatar_catalog.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/state/player_providers.dart';

void main() {
  final marie = PlayerProfile.create(name: 'Marie', nickname: 'Mimi', avatarColor: 'teal', avatarAnimal: 'fox');
  final paul = PlayerProfile.create(name: 'Paul');

  test('un siège lié à une fiche prend sa couleur, son animal et la lettre de son nom affiché', () {
    final setup = GameSetup(playerNames: ['Marie', 'Paul'], playerIds: {0: marie.id, 1: paul.id});

    final looks = avatarLooksFor(setup, [marie, paul]);

    expect(looks['Marie'], const AvatarLook(name: 'Mimi', color: 'teal', animal: 'fox'));
    expect(looks['Paul'], const AvatarLook(), reason: 'rien de choisi, nom affiché = nom en jeu');
  });

  test('le lien est l\'identifiant de la fiche, jamais le nom', () {
    // Un joueur de la partie appelé « Marie » mais sans fiche liée (un adversaire en ligne, un
    // bot) ne reçoit rien de la fiche « Marie » qui existe sur ce téléphone.
    const setup = GameSetup(playerNames: ['Marie', 'Zoé']);

    expect(avatarLooksFor(setup, [marie]), isEmpty);
  });

  test('une fiche supprimée ne laisse que la lettre du nom en jeu', () {
    final setup = GameSetup(playerNames: ['Marie'], playerIds: {0: marie.id});

    expect(avatarLooksFor(setup, const []), isEmpty);
  });

  test('sans fiches lues, rien', () {
    final setup = GameSetup(playerNames: ['Marie'], playerIds: {0: marie.id});

    expect(avatarLooksFor(setup, null), isEmpty);
  });

  test('les choix annoncés par les adversaires en ligne servent, la fiche liée l\'emporte', () {
    final setup = GameSetup(playerNames: ['Marie', 'Zoé'], playerIds: {0: marie.id});

    final looks = avatarLooksFor(
      setup,
      [marie],
      remote: {
        'Zoé': const AvatarLook(color: 'rose', animal: 'owl'),
        'Marie': const AvatarLook(color: 'brick', animal: 'dog'),
      },
    );

    expect(looks['Zoé'], const AvatarLook(color: 'rose', animal: 'owl'));
    expect(looks['Marie']?.animal, 'fox');
  });

  test('un renommage de la fiche suit : la lettre vient du nom affiché d\'aujourd\'hui', () {
    final renamed = marie.copyWith(nickname: 'Zaza');
    final setup = GameSetup(playerNames: ['Marie'], playerIds: {0: marie.id});

    expect(avatarLooksFor(setup, [renamed])['Marie']?.name, 'Zaza');
  });
}
