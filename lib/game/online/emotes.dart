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
/// négociée (`emotes2`), pas une modification de [emotesFeature].
library;

/// Fonction facultative du protocole (voir `supportedFeatures`) : envoyer et
/// recevoir des émotions.
const String emotesFeature = 'emotes';

/// Délai minimal entre deux émotions d'un même joueur : le serveur ignore ce qui
/// arrive plus tôt, l'app grise ses boutons le temps qu'il passe.
const Duration emoteCooldown = Duration(seconds: 3);

/// Une émotion, et les phrases courtes qu'elle propose à l'appui long.
enum Emote {
  thoughtful(['tooLucky', 'dryTenThousand'], retired: ['coincidence']),
  /// « Mort de rire » à l'écran : le nom `mocking` (ex-« moqueur ») reste,
  /// c'est l'identifiant qui voyage.
  mocking(['stickyFive', 'fullHandEmptyHand', 'neverTakeA1000', 'tooGreedy']),
  devastated(['noWay', 'coincidence', 'lucky', 'argh']),
  /// « Câlin » à l'écran : le nom `joyful` (ex-« joyeux ») reste,
  /// c'est l'identifiant qui voyage.
  joyful(['hello', 'goodLuck', 'thanks', 'sorryMustGo'], retired: ['yes']);

  const Emote(this.phrases, {this.retired = const []});

  /// Les identifiants des phrases de cette émotion, dans l'ordre du menu.
  final List<String> phrases;

  /// Les phrases retirées du menu, toujours acceptées : une app plus ancienne
  /// peut encore les envoyer.
  final List<String> retired;

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
}
