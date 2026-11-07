/// Ce qu'un joueur peut choisir pour sa pastille : une couleur de fond et un
/// animal (un emoji) qui remplace sa lettre. Du Dart pur, sans Flutter : le
/// serveur d'une partie en ligne s'en sert aussi, pour ne relayer que des
/// choix qu'il connaît.
///
/// Chaque choix est désigné par un **identifiant stable** (une chaîne), jamais
/// par son rang dans la liste : la fiche d'un joueur, une sauvegarde et le fil
/// d'une partie en ligne portent l'identifiant, et la liste peut s'allonger ou
/// être réordonnée sans rien casser. Un choix retiré du menu passe dans
/// [retiredAvatarColorIds] / [retiredAvatarAnimalIds] au lieu d'être supprimé :
/// une fiche ou une app plus ancienne peut encore le porter.
library;

/// Une couleur de fond de pastille. Fond assez soutenu pour que la lettre
/// blanche reste lisible sur toutes.
class AvatarColorChoice {
  final String id;

  /// La couleur en ARGB (0xAARRGGBB), sans type Flutter : voir l'en-tête.
  final int argb;

  const AvatarColorChoice(this.id, this.argb);
}

/// Les couleurs proposées dans le profil, dans l'ordre du menu. Les six
/// premières sont celles que les anciens blasons attribuaient d'office.
const List<AvatarColorChoice> avatarColorChoices = [
  AvatarColorChoice('brick', 0xFFB5443B),
  AvatarColorChoice('blue', 0xFF3B6EA5),
  AvatarColorChoice('green', 0xFF4A8B5C),
  AvatarColorChoice('amber', 0xFFB08A2E),
  AvatarColorChoice('violet', 0xFF7A4FA0),
  AvatarColorChoice('slate', 0xFF4E5D6C),
  AvatarColorChoice('teal', 0xFF2E8B8B),
  AvatarColorChoice('rose', 0xFFB84F78),
  AvatarColorChoice('orange', 0xFFC0642B),
  AvatarColorChoice('olive', 0xFF6F7F2F),
  AvatarColorChoice('navy', 0xFF2F4B8A),
  AvatarColorChoice('plum', 0xFF6B3F63),
];

/// Identifiants de couleurs sortis du menu mais encore reconnus.
const Set<String> retiredAvatarColorIds = {};

/// Un animal, et l'emoji qui le représente.
class AvatarAnimalChoice {
  final String id;
  final String emoji;

  const AvatarAnimalChoice(this.id, this.emoji);
}

/// Les animaux proposés dans le profil, dans l'ordre du menu.
const List<AvatarAnimalChoice> avatarAnimalChoices = [
  AvatarAnimalChoice('dog', '🐶'),
  AvatarAnimalChoice('cat', '🐱'),
  AvatarAnimalChoice('mouse', '🐭'),
  AvatarAnimalChoice('rabbit', '🐰'),
  AvatarAnimalChoice('fox', '🦊'),
  AvatarAnimalChoice('bear', '🐻'),
  AvatarAnimalChoice('panda', '🐼'),
  AvatarAnimalChoice('koala', '🐨'),
  AvatarAnimalChoice('tiger', '🐯'),
  AvatarAnimalChoice('lion', '🦁'),
  AvatarAnimalChoice('cow', '🐮'),
  AvatarAnimalChoice('pig', '🐷'),
  AvatarAnimalChoice('frog', '🐸'),
  AvatarAnimalChoice('monkey', '🐵'),
  AvatarAnimalChoice('penguin', '🐧'),
  AvatarAnimalChoice('owl', '🦉'),
  AvatarAnimalChoice('duck', '🦆'),
  AvatarAnimalChoice('wolf', '🐺'),
  AvatarAnimalChoice('horse', '🐴'),
  AvatarAnimalChoice('turtle', '🐢'),
  AvatarAnimalChoice('octopus', '🐙'),
  AvatarAnimalChoice('dolphin', '🐬'),
  AvatarAnimalChoice('hedgehog', '🦔'),
  AvatarAnimalChoice('elephant', '🐘'),
];

/// Identifiants d'animaux sortis du menu mais encore reconnus.
const Set<String> retiredAvatarAnimalIds = {};

/// La couleur désignée par [id], ou `null` si l'identifiant est absent ou
/// inconnu (une app plus ancienne face à une couleur plus récente : elle
/// retombe sur la couleur automatique).
AvatarColorChoice? avatarColorById(String? id) {
  if (id == null) return null;
  for (final c in avatarColorChoices) {
    if (c.id == id) return c;
  }
  return null;
}

/// L'animal désigné par [id], ou `null` si l'identifiant est absent ou
/// inconnu (la pastille retombe alors sur la lettre).
AvatarAnimalChoice? avatarAnimalById(String? id) {
  if (id == null) return null;
  for (final a in avatarAnimalChoices) {
    if (a.id == id) return a;
  }
  return null;
}

/// Vrai si [id] est une couleur que ce code connaît, retirée ou non : ce que
/// le serveur accepte de relayer.
bool isKnownAvatarColorId(String id) => avatarColorById(id) != null || retiredAvatarColorIds.contains(id);

/// Vrai si [id] est un animal que ce code connaît, retiré ou non.
bool isKnownAvatarAnimalId(String id) => avatarAnimalById(id) != null || retiredAvatarAnimalIds.contains(id);

/// Ce qu'une pastille montre pour un siège d'une partie, tel que la fiche (ou, en
/// ligne, l'adversaire) l'a choisi. Tout est facultatif : une apparence vide donne
/// la lettre du nom en jeu sur une couleur attribuée par la partie.
class AvatarLook {
  /// Le nom dont vient la lettre : le nom affiché (le surnom d'abord), quand il
  /// diffère du nom en jeu. `null` : le nom en jeu.
  final String? name;

  /// Identifiant de la couleur choisie, `null` si la partie doit en attribuer une.
  final String? color;

  /// Identifiant de l'animal choisi, `null` pour la lettre.
  final String? animal;

  const AvatarLook({this.name, this.color, this.animal});

  @override
  bool operator ==(Object other) =>
      other is AvatarLook && other.name == name && other.color == color && other.animal == animal;

  @override
  int get hashCode => Object.hash(name, color, animal);
}
