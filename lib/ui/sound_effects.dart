import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Effets sonores courts du jeu (lancer de dés, craque, victoire, écran de
/// présentation). Chaque appel crée un lecteur jetable dédié : les sons sont
/// courts et se chevauchent parfois (plusieurs dés qui roulent en même
/// temps), donc pas de lecteur partagé à réinitialiser entre deux lectures.
///
/// Toute erreur (plateforme sans backend audio, ex. certains environnements
/// Linux embarqués, ou tests widgets sans plugin) est silencieusement
/// ignorée : le son est un agrément, jamais une condition de bon
/// fonctionnement du jeu.
class SoundEffects {
  SoundEffects._();

  static final SoundEffects instance = SoundEffects._();

  bool enabled = true;

  Future<void> _play(String assetPath) async {
    if (!enabled) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Son indisponible sur cette plateforme : sans conséquence pour le jeu.
    }
  }

  Future<void> playDiceRoll() => _play('sounds/dice_roll.wav');
  Future<void> playBust() => _play('sounds/bust.wav');
  Future<void> playVictory() => _play('sounds/victory.wav');
  Future<void> playSplash() => _play('sounds/splash.wav');
}

@visibleForTesting
void debugDisableSoundEffects() => SoundEffects.instance.enabled = false;
