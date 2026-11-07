import 'dart:math';

import 'player_stats.dart';

/// Un joueur humain de la base — une PERSONNE, durable d'une partie à l'autre.
///
/// À ne pas confondre avec `Player` (`player.dart`), qui n'est que la feuille
/// de score d'un siège dans UNE partie : celui-ci naît et meurt avec elle,
/// celui-là lui survit et accumule son historique.
class PlayerProfile {
  /// Identité stable, jamais réutilisée : c'est elle, et non le nom, que les
  /// parties référencent, pour qu'un renommage ne casse aucun lien.
  final String id;

  final String name;
  final String? nickname;

  /// Latéralité du joueur, qui décide du côté où placer les commandes pendant
  /// son tour (voir `_controlRow` dans `game_screen.dart`).
  final bool rightHanded;

  /// « AutoRoll » : les actions de ce joueur se valident seules, après le délai
  /// des préférences, au lieu d'attendre un appui. C'est le réglage de SA fiche,
  /// relu à chaque action : on le change en pleine partie, depuis les réglages.
  final bool autoRoll;

  /// La couleur de fond de la pastille choisie par le joueur : un identifiant de
  /// `avatar_catalog.dart`. `null` : la partie en attribue une (voir
  /// `assignAvatarColors`). Un identifiant inconnu (fiche venue d'une app plus
  /// récente) se lit comme `null`.
  final String? avatarColor;

  /// L'animal choisi pour la pastille, qui remplace la lettre : un identifiant de
  /// `avatar_catalog.dart`. `null` : la pastille porte la première lettre du nom
  /// affiché.
  final String? avatarAnimal;

  /// Anciens noms de ce joueur, conservés à chaque renommage.
  ///
  /// Les parties archivées ne contiennent que des NOMS : c'est par eux que le
  /// recalcul rétroactif leur rattache une fiche. Sans cette liste, renommer
  /// un joueur effacerait silencieusement tout son historique au recalcul
  /// suivant — la fiche ne correspondrait plus à rien dans les archives.
  final List<String> formerNames;

  final PlayerStats stats;

  const PlayerProfile({
    required this.id,
    required this.name,
    this.nickname,
    this.rightHanded = true,
    this.autoRoll = false,
    this.avatarColor,
    this.avatarAnimal,
    this.formerNames = const [],
    this.stats = PlayerStats.empty,
  });

  /// Crée une fiche avec une identité neuve. [Random.secure] plutôt que le
  /// générateur par défaut : deux fiches créées dans la même milliseconde ne
  /// doivent pas pouvoir partager un identifiant.
  factory PlayerProfile.create({
    required String name,
    String? nickname,
    bool rightHanded = true,
    bool autoRoll = false,
    String? avatarColor,
    String? avatarAnimal,
  }) {
    final random = Random.secure();
    final suffix = List.generate(4, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return PlayerProfile(
      id: '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-$suffix',
      name: name.trim(),
      nickname: (nickname?.trim().isEmpty ?? true) ? null : nickname!.trim(),
      rightHanded: rightHanded,
      autoRoll: autoRoll,
      avatarColor: avatarColor,
      avatarAnimal: avatarAnimal,
    );
  }

  /// Tous les noms sous lesquels ce joueur a pu figurer dans une partie.
  List<String> get allNames => [name, ...formerNames];

  /// Nom affiché : le surnom quand il y en a un, le nom sinon.
  String get displayName => nickname ?? name;

  /// Renomme en conservant l'ancien nom (voir [formerNames]). Un aller-retour
  /// vers un nom déjà porté ne le duplique pas.
  PlayerProfile renamedTo(String newName) {
    final trimmed = newName.trim();
    if (normalizeName(trimmed) == normalizeName(name)) return copyWith(name: trimmed);
    // Le nom repris sort de la liste des anciens : il redevient le nom
    // courant, et `allNames` le compterait deux fois.
    final kept = formerNames.where((n) {
      final key = normalizeName(n);
      return key != normalizeName(name) && key != normalizeName(trimmed);
    });
    return copyWith(name: trimmed, formerNames: [name, ...kept]);
  }

  PlayerProfile copyWith({
    String? name,
    String? nickname,
    bool clearNickname = false,
    bool? rightHanded,
    bool? autoRoll,
    String? avatarColor,
    bool clearAvatarColor = false,
    String? avatarAnimal,
    bool clearAvatarAnimal = false,
    List<String>? formerNames,
    PlayerStats? stats,
  }) {
    return PlayerProfile(
      id: id,
      name: name ?? this.name,
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      rightHanded: rightHanded ?? this.rightHanded,
      autoRoll: autoRoll ?? this.autoRoll,
      avatarColor: clearAvatarColor ? null : (avatarColor ?? this.avatarColor),
      avatarAnimal: clearAvatarAnimal ? null : (avatarAnimal ?? this.avatarAnimal),
      formerNames: formerNames ?? this.formerNames,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'rightHanded': rightHanded,
        'autoRoll': autoRoll,
        'avatarColor': avatarColor,
        'avatarAnimal': avatarAnimal,
        'formerNames': formerNames,
        'stats': stats.toJson(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        rightHanded: json['rightHanded'] as bool? ?? true,
        autoRoll: json['autoRoll'] as bool? ?? false,
        avatarColor: json['avatarColor'] as String?,
        avatarAnimal: json['avatarAnimal'] as String?,
        formerNames: List<String>.from(json['formerNames'] as List? ?? const []),
        stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
      );
}

/// Forme comparable d'un nom, pour l'unicité : casse et accents neutralisés,
/// espaces resserrés. « Rémi », « remi » et « RÉMI  » désignent la même
/// personne et ne doivent pas pouvoir coexister dans la base.
String normalizeName(String name) {
  final lowered = name.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lowered.runes) {
    buffer.write(_accentFolding[String.fromCharCode(rune)] ?? String.fromCharCode(rune));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Repli des seules lettres accentuées atteignables au clavier français, plus
/// quelques voisines courantes : une table suffit ici et évite d'ajouter une
/// dépendance de normalisation Unicode pour une poignée de caractères.
const Map<String, String> _accentFolding = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'æ': 'ae', 'œ': 'oe', 'ß': 'ss',
};
