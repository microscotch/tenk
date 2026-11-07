import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/avatar_catalog.dart';
import '../game/player_profile.dart';
import 'game_providers.dart';
import 'game_save_store.dart';
import 'online_providers.dart';
import 'player_store.dart';
import 'settings_providers.dart';

/// Latéralité à appliquer AU SIÈGE COURANT : celle du joueur dont c'est le
/// tour, quand il est rattaché à une fiche.
///
/// Repli sur le réglage d'appareil dans tous les autres cas — un bot, qui n'a
/// pas de latéralité ; une partie enregistrée avant la base de joueurs, qui ne
/// porte aucun lien ; un état chargé en test. La disposition des commandes
/// peut donc basculer d'un côté à l'autre en cours de partie, ce qui est le
/// comportement voulu : elle suit la main de qui joue.
final currentSeatRightHandedProvider = Provider<bool>((ref) {
  // Le réglage par défaut est la latéralité de l'utilisateur de l'appareil
  // (son profil) ; l'ancien réglage d'appareil ne sert plus que tant que le
  // profil n'est pas là (fiches pas encore relues, profil pas encore créé).
  final deviceDefault = ref.watch(myProfileProvider)?.rightHanded ?? ref.watch(settingsProvider).rightHanded;
  final engine = ref.watch(gameProvider);
  if (engine == null) return deviceDefault;

  // `GameNotifier` expose la config RÉORDONNÉE : c'est bien elle qu'indexe
  // `currentPlayerIndex`.
  final id = ref.watch(gameProvider.notifier).orderedSetup?.playerIdAt(engine.currentPlayerIndex);
  if (id == null) return deviceDefault;

  final players = ref.watch(playersProvider).value;
  if (players == null) return deviceDefault;
  for (final player in players) {
    if (player.id == id) return player.rightHanded;
  }
  return deviceDefault;
});

/// Nom sous lequel afficher chaque joueur d'UNE partie, décrite par sa config
/// [setup] : son surnom quand son siège est rattaché à une fiche qui en porte
/// un.
///
/// Table indexée par le nom EN JEU (`Player.name`) — c'est ce que tous les
/// rendus ont sous la main, `Player` ignorant tout des fiches. Un siège non
/// rattaché n'y figure pas du tout : un bot, une partie antérieure à la base,
/// une fiche supprimée. L'appelant retombe alors sur le nom, c'est-à-dire sur
/// ce que la partie a réellement enregistré.
///
/// Le lien est l'identifiant de la fiche, jamais le nom : une fiche renommée
/// depuis la partie garde son surnom, et deux parties qui ont un joueur du même
/// nom en jeu ne se prêtent pas leurs surnoms. C'est pourquoi la table se
/// calcule depuis la config de la partie AFFICHÉE — celle du journal d'un run
/// archivé, par exemple — et non depuis la partie en cours, qui peut n'exister
/// pas, ou être une autre.
///
/// La lettre de la pastille, elle, vient de ce nom affiché (voir
/// [avatarLooksFor]) : le joueur qui se choisit un surnom voit sa pastille suivre.
Map<String, String> displayNamesFor(GameSetup setup, Iterable<PlayerProfile>? profiles) {
  if (profiles == null) return const {};
  final byId = {for (final profile in profiles) profile.id: profile};
  final names = <String, String>{};
  for (var seat = 0; seat < setup.playerNames.length; seat++) {
    final profile = byId[setup.playerIdAt(seat)];
    if (profile == null) continue;
    final inGame = setup.playerNames[seat];
    // Rien à substituer quand le surnom est absent : la table reste vide et
    // l'appelant garde le nom, sans détour.
    if (profile.displayName != inGame) names[inGame] = profile.displayName;
  }
  return names;
}

/// Les noms à afficher pour la partie EN COURS (ou en rejeu) : voir
/// [displayNamesFor], appliqué à sa config réordonnée — celle que porte le
/// moteur exposé par [gameProvider].
final displayNamesProvider = Provider<Map<String, String>>((ref) {
  final engine = ref.watch(gameProvider);
  final setup = ref.watch(gameProvider.notifier).orderedSetup;
  if (engine == null || setup == null) return const {};
  return displayNamesFor(setup, ref.watch(playersProvider).value);
});

/// Les noms à afficher pour la partie que montre un écran : celle de son
/// journal [record] quand il en a un — une partie terminée, archivée ou non —
/// et sinon la partie en cours (voir [displayNamesProvider]).
///
/// À appeler dans un `build`, l'écran se redessine alors quand les fiches
/// changent (un surnom modifié, une fiche supprimée).
Map<String, String> watchDisplayNames(WidgetRef ref, SavedGame? record) {
  if (record == null) return ref.watch(displayNamesProvider);
  return displayNamesFor(record.setup, ref.watch(playersProvider).value);
}

/// L'apparence de la pastille de chaque joueur d'UNE partie, décrite par sa config
/// [setup] : la lettre vient du nom affiché (le surnom d'abord), la couleur et
/// l'animal sont ceux de la fiche. Même principe que [displayNamesFor], dont elle
/// reprend la règle de lien — **l'identifiant de la fiche, jamais le nom** : un
/// adversaire en ligne, un bot ou une fiche supprimée n'y figurent pas (la pastille
/// retombe sur la lettre du nom en jeu et une couleur attribuée par la partie), et
/// deux parties qui ont un joueur du même nom ne se prêtent pas leurs choix.
///
/// [remote] : les choix annoncés par les adversaires d'une partie en ligne, par nom
/// en jeu ; une fiche liée au siège l'emporte.
Map<String, AvatarLook> avatarLooksFor(
  GameSetup setup,
  Iterable<PlayerProfile>? profiles, {
  Map<String, AvatarLook> remote = const {},
}) {
  final looks = <String, AvatarLook>{...remote};
  if (profiles == null) return looks;
  final byId = {for (final profile in profiles) profile.id: profile};
  for (var seat = 0; seat < setup.playerNames.length; seat++) {
    final profile = byId[setup.playerIdAt(seat)];
    if (profile == null) continue;
    final inGame = setup.playerNames[seat];
    looks[inGame] = AvatarLook(
      name: profile.displayName != inGame ? profile.displayName : null,
      color: profile.avatarColor,
      animal: profile.avatarAnimal,
    );
  }
  return looks;
}

/// Ce que les adversaires d'une partie en ligne ont annoncé de leur pastille, par nom en
/// jeu (le pseudo du siège) : vide hors partie en ligne. Un siège de bot, ou qui n'a rien
/// choisi, n'y figure pas.
final remoteAvatarLooksProvider = Provider<Map<String, AvatarLook>>((ref) {
  if (!ref.watch(gameProvider.notifier).isOnline) return const {};
  final seats = ref.watch(onlineSessionProvider.select((s) => s.seats));
  return {for (final seat in seats) seat.name: ?seat.avatar};
});

/// Les pastilles de la partie EN COURS (ou en rejeu) : voir [avatarLooksFor], appliqué
/// à sa config réordonnée — celle que porte le moteur exposé par [gameProvider] — et,
/// en ligne, aux choix annoncés par les adversaires ([remoteAvatarLooksProvider]).
final avatarLooksProvider = Provider<Map<String, AvatarLook>>((ref) {
  final engine = ref.watch(gameProvider);
  final setup = ref.watch(gameProvider.notifier).orderedSetup;
  if (engine == null || setup == null) return const {};
  return avatarLooksFor(setup, ref.watch(playersProvider).value, remote: ref.watch(remoteAvatarLooksProvider));
});

/// Les pastilles de la partie que montre un écran : celle de son journal [record]
/// quand il en a un, sinon la partie en cours (voir [avatarLooksProvider]). À
/// appeler dans un `build` : l'écran se redessine quand une fiche change.
///
/// Le journal de la partie en ligne qui vient de se terminer (celui que le notifier
/// porte encore) garde les pastilles annoncées par les adversaires ; un autre journal,
/// archivé, n'en a plus aucune trace : la lettre du nom en jeu et une couleur attribuée.
Map<String, AvatarLook> watchAvatarLooks(WidgetRef ref, SavedGame? record) {
  if (record == null) return ref.watch(avatarLooksProvider);
  final notifier = ref.watch(gameProvider.notifier);
  final live = notifier.isOnline && notifier.gameRecord?.seed == record.seed;
  return avatarLooksFor(
    record.setup,
    ref.watch(playersProvider).value,
    remote: live ? ref.watch(remoteAvatarLooksProvider) : const {},
  );
}

/// Le profil de l'utilisateur de l'appareil : sa fiche dans la base des
/// joueurs, désignée par `AppSettings.myProfileId`. Nul tant que les réglages
/// ou les fiches ne sont pas relus, que le profil n'a pas été choisi, ou si sa
/// fiche a disparu — c'est [isMyProfileMissing] qui tranche au lancement.
///
/// Une fiche comme les autres (statistiques, surnom, latéralité), et non une
/// donnée à part : ses parties, locales comme en ligne, s'y cumulent.
final myProfileProvider = Provider<PlayerProfile?>((ref) {
  final id = ref.watch(settingsProvider.select((s) => s.myProfileId));
  if (id == null) return null;
  final players = ref.watch(playersProvider).value;
  return players?.where((p) => p.id == id).firstOrNull;
});

/// Vrai s'il faut demander son profil à l'utilisateur : aucun n'a été choisi,
/// ou sa fiche n'existe plus. Attend que réglages ET fiches soient réellement
/// relus — décider sur les valeurs par défaut enverrait un utilisateur qui a
/// déjà un profil vers l'écran de création.
///
/// Faux si les fiches ne peuvent pas être lues : mieux vaut laisser entrer dans
/// le jeu que bloquer sur un écran dont l'enregistrement échouerait aussi.
Future<bool> isMyProfileMissing(ProviderContainer container) async {
  if (!container.read(settingsProvider).loaded) {
    final loaded = Completer<void>();
    final subscription = container.listen(settingsProvider, (_, next) {
      if (next.loaded && !loaded.isCompleted) loaded.complete();
    });
    if (container.read(settingsProvider).loaded && !loaded.isCompleted) loaded.complete();
    await loaded.future;
    subscription.close();
  }
  final List<PlayerProfile> players;
  try {
    // Le store lui-même, pas `playersProvider.future` : Riverpod réessaie de
    // lui-même un provider en échec, et cette attente ne finirait jamais.
    players = await container.read(playerStoreProvider).list();
  } catch (_) {
    return false;
  }
  final id = container.read(settingsProvider).myProfileId;
  return id == null || !players.any((p) => p.id == id);
}

/// La fiche dont le nom est l'ancien « nom du joueur principal » des réglages,
/// s'il y en a une : l'utilisateur d'avant la notion de profil y est sans doute
/// déjà, avec ses statistiques — on la lui propose d'abord plutôt que de lui
/// en faire créer une seconde, refusée d'ailleurs pour nom déjà pris.
PlayerProfile? profileMatchingLegacyName(Iterable<PlayerProfile> players, String legacyName) {
  if (legacyName.trim().isEmpty) return null;
  final key = normalizeName(legacyName);
  return players.where((p) => p.allNames.any((n) => normalizeName(n) == key)).firstOrNull;
}

/// Nom à afficher pour [name], ou [name] lui-même faute de mieux.
String displayNameOf(Map<String, String> displayNames, String name) =>
    displayNames[name] ?? name;
