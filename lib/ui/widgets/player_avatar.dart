import 'package:flutter/material.dart';

import '../../game/avatar_catalog.dart';
import '../../game/avatar_initials.dart';
import '../../game/player_profile.dart';

/// Les couleurs de fond de pastille que la partie peut attribuer d'office : celles
/// du catalogue (voir [avatarColorChoices]).
final List<Color> kAvatarColorPalette = [for (final c in avatarColorChoices) Color(c.argb)];

int _paletteIndexFor(String name) {
  final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return hash % kAvatarColorPalette.length;
}

/// Couleur de fond de la pastille d'un joueur qui n'en a pas choisi : déterministe
/// à partir de son nom (même joueur = même couleur d'un affichage à l'autre, sans
/// état à gérer). Ne garantit PAS l'absence de collision entre plusieurs joueurs
/// d'une même partie (voir [assignAvatarColors]) — à réserver aux affichages hors
/// contexte de partie (ex. l'aperçu du nom dans l'écran de configuration).
Color avatarColorFor(String name) => kAvatarColorPalette[_paletteIndexFor(name)];

/// Attribue une couleur de pastille à chaque nom de [names] : d'abord celle que le
/// joueur a CHOISIE dans son profil ([looks], indexé par nom en jeu), dans l'ordre
/// des joueurs — une couleur déjà prise par un joueur précédent n'est pas donnée une
/// seconde fois : le suivant retombe sur une couleur attribuée, comme s'il n'avait
/// rien choisi (deux pastilles identiques, et deux courbes indiscernables) —, puis,
/// pour les autres, une couleur attribuée sans jamais en répéter une tant que la
/// palette n'est pas épuisée : chaque nom se voit d'abord proposer sa couleur
/// "naturelle" ([avatarColorFor]), et en cas de collision la première couleur libre
/// suivante dans la palette (en balayant circulairement). Déterministe pour un ordre
/// de [names] donné (celui des joueurs dans la partie), donc stable d'un affichage à
/// l'autre tant que la liste de joueurs et leurs choix ne changent pas. La palette
/// compte plus de couleurs que la partie de joueurs (6 au plus, voir
/// `new_game_screen.dart`) : une collision irrésolvable ne devrait pas se produire ;
/// le cas échéant, les couleurs recommencent à se répéter plutôt que de boucler.
Map<String, Color> assignAvatarColors(Iterable<String> names, {Map<String, AvatarLook> looks = const {}}) {
  final colors = <String, Color>{};
  final used = <int>{};
  final list = names.toList();
  for (final name in list) {
    if (colors.containsKey(name)) continue;
    final chosen = avatarColorById(looks[name]?.color);
    if (chosen == null) continue;
    final index = avatarColorChoices.indexOf(chosen);
    if (used.add(index)) colors[name] = kAvatarColorPalette[index];
  }
  for (final name in list) {
    if (colors.containsKey(name)) continue;
    var index = _paletteIndexFor(name);
    var attempts = 0;
    while (used.contains(index) && attempts < kAvatarColorPalette.length) {
      index = (index + 1) % kAvatarColorPalette.length;
      attempts++;
    }
    used.add(index);
    colors[name] = kAvatarColorPalette[index];
  }
  return colors;
}

/// Les polices d'emoji du système, par plateforme : sur mobile le texte retombe de
/// toute façon dessus, mais une machine de bureau ne l'a pas toujours en secours.
const kEmojiFontFallback = ['Apple Color Emoji', 'Noto Color Emoji', 'Segoe UI Emoji'];

/// Pastille d'un joueur : un disque de couleur portant la première lettre de son
/// nom — ou, s'il en a choisi un dans son profil, un animal (un emoji, désigné par
/// son identifiant [animal], voir `avatar_catalog.dart`) qui remplace la lettre.
///
/// [color] impose une couleur résolue au niveau de la partie entière (voir
/// [assignAvatarColors], à préférer dès que la liste des autres joueurs est
/// connue) ; par défaut, retombe sur [avatarColorFor] (déterministe mais sans
/// garantie anti-collision, pour les affichages isolés).
class PlayerAvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  /// Identifiant de l'animal choisi, `null` pour la lettre. Un identifiant
  /// inconnu se lit comme `null`.
  final String? animal;

  const PlayerAvatarWidget({super.key, required this.name, this.size = 40, this.color, this.animal});

  /// La pastille d'un joueur d'une fiche : la lettre de son nom affiché (le surnom
  /// d'abord), sa couleur et son animal choisis. Sans couleur choisie, celle que la
  /// partie lui donnerait d'office (déterminée par son NOM en jeu, pas par son surnom).
  PlayerAvatarWidget.profile(PlayerProfile profile, {Key? key, double size = 40})
      : this(
          key: key,
          name: profile.displayName,
          size: size,
          color: avatarColorById(profile.avatarColor) == null
              ? avatarColorFor(profile.name)
              : Color(avatarColorById(profile.avatarColor)!.argb),
          animal: profile.avatarAnimal,
        );

  /// La pastille du siège [seat] (son nom en jeu) d'une partie dont les apparences
  /// sont [looks] : sa lettre vient du nom affiché, son animal du profil. [color] est
  /// la couleur déjà résolue pour toute la partie (voir [assignAvatarColors], qui y a
  /// mis la couleur choisie).
  PlayerAvatarWidget.seat(String seat, {Key? key, required Map<String, AvatarLook> looks, Color? color, double size = 40})
      : this(key: key, name: looks[seat]?.name ?? seat, size: size, color: color, animal: looks[seat]?.animal);

  @override
  Widget build(BuildContext context) {
    final emoji = avatarAnimalById(animal)?.emoji;
    final resolvedColor = color ?? avatarColorFor(name);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolvedColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: size * 0.035),
        ),
        child: Center(
          child: emoji != null
              // Un emoji est dessiné par la police du système : sa hauteur de ligne
              // n'est pas celle d'une lettre, d'où le FittedBox qui le garde dans le disque.
              ? FittedBox(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.14),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: size * 0.56, height: 1, fontFamilyFallback: kEmojiFontFallback),
                    ),
                  ),
                )
              : Text(
                  avatarLetterFor(name),
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Les pastilles de tous les joueurs d'UNE partie, résolues ensemble : la couleur de
/// chacun ([assignAvatarColors], choix des profils d'abord, sans doublon) et son
/// apparence ([AvatarLook] : lettre du nom affiché, animal). Se construit depuis
/// l'ordre des joueurs de la partie, et se passe d'un écran à ses sous-widgets à la
/// place de deux tables.
class AvatarSet {
  /// La couleur de chaque nom en jeu.
  final Map<String, Color> colors;

  /// L'apparence de chaque nom en jeu (`avatarLooksFor`).
  final Map<String, AvatarLook> looks;

  const AvatarSet(this.colors, this.looks);

  /// Les pastilles de [seats] (les noms en jeu, dans l'ordre des joueurs) selon [looks].
  factory AvatarSet.resolve(Iterable<String> seats, Map<String, AvatarLook> looks) =>
      AvatarSet(assignAvatarColors(seats, looks: looks), looks);

  /// La pastille du siège [seat].
  PlayerAvatarWidget of(String seat, {double size = 40, Key? key}) =>
      PlayerAvatarWidget.seat(seat, key: key, looks: looks, color: colors[seat], size: size);

  /// La couleur du siège [seat], `null` s'il n'est pas de la partie.
  Color? color(String seat) => colors[seat];
}
