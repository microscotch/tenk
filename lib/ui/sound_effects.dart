import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../state/settings_providers.dart';

/// Effets sonores courts (lancer de dés, craque, victoire, écran de
/// présentation) et musique de fond en boucle. Chaque effet court crée un
/// lecteur jetable dédié : les sons se chevauchent parfois (plusieurs dés
/// qui roulent en même temps), donc pas de lecteur partagé à réinitialiser
/// entre deux lectures. La musique utilise à l'inverse un unique lecteur
/// persistant, démarré/arrêté selon les préférences.
///
/// Toute erreur (plateforme sans backend audio, ex. certains environnements
/// Linux embarqués, ou tests widgets sans plugin) est silencieusement
/// ignorée : le son est un agrément, jamais une condition de bon
/// fonctionnement du jeu.
class SoundEffects {
  SoundEffects._();

  static final SoundEffects instance = SoundEffects._();

  bool _effectsEnabled = true;
  bool _musicWanted = true;
  bool _musicPlaying = false;
  bool _testDisabled = false;
  AudioPlayer? _musicPlayer;

  /// Synchronise l'état (effets sonores + musique) avec les préférences
  /// utilisateur ; appelé à chaque changement de réglages.
  void applySettings(AppSettings settings) {
    _effectsEnabled = settings.soundEffectsEnabled;
    _musicWanted = settings.musicEnabled;
    if (_musicWanted && !_musicPlaying) {
      _startMusic();
    } else if (!_musicWanted && _musicPlaying) {
      _stopMusic();
    }
  }

  Future<void> _play(String assetPath) async {
    if (_testDisabled || !_effectsEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Son indisponible sur cette plateforme : sans conséquence pour le jeu.
    }
  }

  Future<void> _startMusic() async {
    if (_testDisabled) return;
    _musicPlaying = true; // évite les démarrages concurrents si appelé deux fois
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/background_music.wav'));
      _musicPlayer = player;
    } catch (_) {
      // Pas de backend audio disponible : la musique reste simplement coupée.
    }
  }

  Future<void> _stopMusic() async {
    _musicPlaying = false;
    final player = _musicPlayer;
    _musicPlayer = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {
      // Rien à faire de plus si l'arrêt échoue : le lecteur est abandonné.
    }
  }

  Future<void> playDiceRoll() => _play('sounds/dice_roll.wav');
  Future<void> playBust() => _play('sounds/bust.wav');
  Future<void> playVictory() => _play('sounds/victory.wav');
  Future<void> playSplash() => _play('sounds/splash.wav');
}

@visibleForTesting
void debugDisableSoundEffects() {
  SoundEffects.instance._testDisabled = true;
}
