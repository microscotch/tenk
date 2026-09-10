import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/sound_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la musique n\'est pas lancée tant que les préférences ne sont pas relues', () {
    final sounds = SoundEffects.instance;

    // Au tout premier build, le fournisseur n'expose que les valeurs par
    // défaut — musique activée — en attendant la lecture du disque. Les
    // appliquer démarrait la musique chez quelqu'un qui l'avait coupée.
    final before = sounds.musicStartCount;
    sounds.applySettings(const AppSettings());
    expect(sounds.musicStartCount, before,
        reason: 'valeurs par défaut non confirmées : rien ne doit démarrer');

    // Préférences relues, musique effectivement coupée : toujours rien.
    sounds.applySettings(const AppSettings(musicEnabled: false, loaded: true));
    expect(sounds.musicStartCount, before, reason: 'la musique est désactivée');

    // Préférences relues, musique voulue : cette fois elle démarre.
    sounds.applySettings(const AppSettings(loaded: true));
    expect(sounds.musicStartCount, before + 1);
  });
}
