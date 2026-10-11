/// Les émotions qu'un joueur peut envoyer aux autres pendant une partie en
/// ligne : un « chat contrôlé ». Rien d'autre que ces identifiants ne voyage —
/// ni texte libre (rien à modérer), ni texte traduit (chaque appareil affiche la
/// phrase dans sa langue).
///
/// Les identifiants sont des noms stables, jamais des positions : réordonner ou
/// ajouter une phrase est sans risque (une app déjà installée ignore en silence
/// une phrase qu'elle ne connaît pas). Une phrase qu'on retire du menu passe dans
/// [Emote.retired] au lieu d'être supprimée : une app plus ancienne peut encore
/// l'envoyer, et le serveur la refuserait. Changer le texte d'une phrase garde son
/// identifiant. Retirer ou renommer une émotion demande une nouvelle fonction
/// négociée (voir [emotes2Feature], qui a ajouté Fâché et Soulagé), pas une
/// modification de [emotesFeature].
library;

/// Fonction facultative du protocole (voir `supportedFeatures`) : envoyer et
/// recevoir des émotions.
const String emotesFeature = 'emotes';

/// Délai minimal entre deux émotions d'un même joueur : le serveur ignore ce qui
/// arrive plus tôt, l'app grise ses boutons le temps qu'il passe.
const Duration emoteCooldown = Duration(seconds: 3);

/// Fonction facultative du protocole, en plus de [emotesFeature] : les
/// émotions de la seconde série (Fâché, Soulagé) et les phrases ajoutées ou
/// déplacées avec elles. Un client ou un serveur qui ne l'annonce pas en reste à
/// la première série : le serveur lui fait parvenir une version rétrogradée de
/// ce que les autres envoient (voir [downgradeForV1]), l'app ne lui envoie que
/// la première série (voir [emotesFor], [Emote.phrasesFor]).
const String emotes2Feature = 'emotes2';

/// Une émotion, et les phrases courtes qu'elle propose à l'appui long.
enum Emote {
  thoughtful(['tooLucky', 'dryTenThousand', 'strangeChoice'], retired: ['coincidence']),
  /// « Mort de rire » à l'écran : le nom `mocking` (ex-« moqueur ») reste,
  /// c'est l'identifiant qui voyage.
  mocking(['stickyFive', 'fullHandEmptyHand', 'neverTakeA1000', 'tooGreedy', 'allByFives', 'withPanache']),
  /// « Comme de par hasard... » et « Veinard va ! » sont passées chez [angry] :
  /// toujours acceptées ici, une app d'avant les envoie encore sous cette émotion.
  devastated(['noWay', 'unfair', 'argh'], retired: ['coincidence', 'lucky']),
  /// Fâché — seconde série (voir [emotes2Feature]).
  angry(['coincidence', 'lucky'], v2Only: true),
  /// Soulagé — seconde série (voir [emotes2Feature]).
  relieved(['phew', 'atLast', 'closeCall'], v2Only: true),
  /// « Câlin » à l'écran : le nom `joyful` (ex-« joyeux ») reste,
  /// c'est l'identifiant qui voyage.
  joyful(['hello', 'goodLuck', 'thanks', 'sorryMustGo', 'wellPlayed', 'sorry'], retired: ['yes']);

  const Emote(this.phrases, {this.retired = const [], this.v2Only = false});

  /// Les identifiants des phrases de cette émotion, dans l'ordre du menu.
  final List<String> phrases;

  /// Les phrases retirées du menu, toujours acceptées : une app plus ancienne
  /// peut encore les envoyer.
  final List<String> retired;

  /// Vrai pour une émotion de la seconde série, inconnue d'un client ou d'un
  /// serveur sans [emotes2Feature].
  final bool v2Only;

  /// L'émotion de nom [name] (`Emote.name`), ou null.
  static Emote? byName(Object? name) {
    for (final emote in values) {
      if (emote.name == name) return emote;
    }
    return null;
  }

  /// Vrai si [phrase] est absente (l'émotion seule) ou l'une des siennes,
  /// retirées comprises.
  bool accepts(String? phrase) => phrase == null || phrases.contains(phrase) || retired.contains(phrase);

  /// Les phrases du menu de cette émotion face à un serveur qui connaît la
  /// seconde série ([v2]) ou non : sans elle, seules celles qu'un serveur de la
  /// première série accepte sous cette émotion.
  List<String> phrasesFor({required bool v2}) =>
      v2 ? phrases : [for (final p in _v1Menus[this] ?? const <String>[]) p];
}

/// Les émotions proposées, selon que le serveur connaît la seconde série ([v2]).
List<Emote> emotesFor({required bool v2}) => [for (final e in Emote.values) if (v2 || !e.v2Only) e];

/// Le menu de chaque émotion de la première série, tel qu'un serveur ou une
/// app sans [emotes2Feature] le connaît (identifiants ; les textes, eux, ont
/// pu changer).
const Map<Emote, List<String>> _v1Menus = {
  Emote.thoughtful: ['tooLucky', 'dryTenThousand'],
  Emote.mocking: ['stickyFive', 'fullHandEmptyHand', 'neverTakeA1000', 'tooGreedy'],
  Emote.devastated: ['noWay', 'coincidence', 'lucky', 'argh'],
  Emote.joyful: ['hello', 'goodLuck', 'thanks', 'sorryMustGo'],
};

/// Ce qu'un client ou un serveur de la première série accepte, retirées comprises.
const Map<Emote, Set<String>> emotesV1 = {
  Emote.thoughtful: {'tooLucky', 'dryTenThousand', 'coincidence'},
  Emote.mocking: {'stickyFive', 'fullHandEmptyHand', 'neverTakeA1000', 'tooGreedy'},
  Emote.devastated: {'noWay', 'coincidence', 'lucky', 'argh'},
  Emote.joyful: {'hello', 'goodLuck', 'thanks', 'sorryMustGo', 'yes'},
};

/// Ce qu'on peut faire parvenir d'une émotion [emote] (et de sa phrase) à un
/// client de la première série : telle quelle s'il la connaît ; une phrase de
/// Fâché sous Dévasté, où ce client l'a toujours rangée ; une phrase nouvelle
/// réduite à son émotion ; rien (null) pour une émotion qu'il ne connaît pas.
(Emote, String?)? downgradeForV1(Emote emote, String? phrase) {
  final known = emotesV1[emote];
  if (known != null && (phrase == null || known.contains(phrase))) return (emote, phrase);
  if (emote == Emote.angry && phrase != null && emotesV1[Emote.devastated]!.contains(phrase)) {
    return (Emote.devastated, phrase);
  }
  if (known != null) return (emote, null);
  return null;
}
