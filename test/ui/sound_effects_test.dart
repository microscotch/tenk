import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/sound_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la musique n\'est pas lancée tant que les préférences ne sont pas relues', () {
    final sounds = SoundEffects.instance;

    // Au tout premier build, le fournisseur n'expose que les valeurs par
    // défaut — musique activée chez qui l'a demandée — en attendant la lecture du disque. Les
    // appliquer démarrait la musique chez quelqu'un qui l'avait coupée.
    final before = sounds.musicStartCount;
    sounds.applySettings(const AppSettings(musicEnabled: true));
    expect(sounds.musicStartCount, before,
        reason: 'valeurs par défaut non confirmées : rien ne doit démarrer');

    // Préférences relues, musique effectivement coupée : toujours rien.
    sounds.applySettings(const AppSettings(musicEnabled: false, loaded: true));
    expect(sounds.musicStartCount, before, reason: 'la musique est désactivée');

    // Préférences relues, musique voulue : cette fois elle démarre.
    sounds.applySettings(const AppSettings(musicEnabled: true, loaded: true));
    expect(sounds.musicStartCount, before + 1);

    // Par défaut, la musique est coupée : rien ne démarre sans l'avoir demandé.
    sounds.applySettings(const AppSettings(loaded: true));
    expect(sounds.musicStartCount, before + 1);
  });

  test('changer de boucle pendant l\'écoute relance la musique avec la nouvelle', () async {
    final sounds = SoundEffects.instance;
    sounds.applySettings(const AppSettings(loaded: true)); // musique coupée : état de départ
    final before = sounds.musicStartCount;

    sounds.applySettings(const AppSettings(musicEnabled: true, loaded: true));
    expect(sounds.musicStartCount, before + 1);

    // Même boucle, autre réglage : rien ne redémarre.
    sounds.applySettings(const AppSettings(musicEnabled: true, soundEffectsEnabled: false, loaded: true));
    expect(sounds.musicStartCount, before + 1);

    sounds.applySettings(const AppSettings(musicEnabled: true, musicTrack: MusicTrack.original, loaded: true));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(sounds.musicStartCount, before + 2, reason: 'la nouvelle boucle démarre une fois l\'ancienne arrêtée');

    sounds.applySettings(const AppSettings(loaded: true));
  });

  test('un lecteur de musique qui ne démarre pas n\'est pas gardé : la reprise relance au lieu de reprendre un lecteur mort', () async {
    final sounds = SoundEffects.instance;
    sounds.applySettings(const AppSettings(loaded: true)); // musique coupée : état de départ
    debugEnableSoundEffects(); // vrai chemin audio : sans backend, `play` échoue
    addTearDown(debugDisableSoundEffects);

    sounds.applySettings(const AppSettings(musicEnabled: true, loaded: true));
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(sounds.musicPlayerForTest, isNull, reason: 'le lecteur qui a échoué ne doit pas rester le lecteur courant');
    expect(sounds.musicPlayingForTest, isFalse, reason: 'rien ne joue : une prochaine demande doit pouvoir réessayer');
    sounds.applySettings(const AppSettings(loaded: true));
  });

  test('un effet sonore qui ne démarre pas ne laisse pas son lecteur derrière lui', () async {
    final sounds = SoundEffects.instance;
    sounds.applySettings(const AppSettings(loaded: true));
    debugEnableSoundEffects(); // vrai chemin audio : sans backend, `play` échoue
    addTearDown(debugDisableSoundEffects);

    final before = sounds.effectPlayersAlive;
    await sounds.playDiceRoll(3);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(sounds.effectPlayersAlive, before, reason: 'le lecteur de l\'effet raté doit être libéré');
  });
}
