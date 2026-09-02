import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../state/settings_providers.dart';

/// Effets sonores courts (lancer de dés, craque, victoire, écran de
/// présentation) et musique de fond en boucle. Chaque effet court crée un
/// lecteur jetable dédié : les sons se chevauchent parfois (plusieurs dés
/// qui roulent en même temps), donc pas de lecteur partagé à réinitialiser
/// entre deux lectures. La musique utilise à l'inverse un unique lecteur
/// persistant, démarré/arrêté selon les préférences.
///
/// Observe aussi le cycle de vie de l'app ([WidgetsBindingObserver]) : dès
/// qu'elle passe en arrière-plan (bouton d'accueil, autre app au premier
/// plan...), la musique se met en pause (pas juste "en sourdine" : au sens
/// propre, elle reprend exactement où elle en était au retour) et plus aucun
/// effet sonore ne se déclenche tant qu'elle n'est pas revenue au premier
/// plan — le jeu lui-même se met en pause séparément côté écran de jeu (voir
/// `game_screen.dart`, `_GameScreenState.didChangeAppLifecycleState`), mais
/// cette classe ne doit pas dépendre de cet écran précis pour couper le son.
///
/// Toute erreur (plateforme sans backend audio, ex. certains environnements
/// Linux embarqués, ou tests widgets sans plugin) est silencieusement
/// ignorée : le son est un agrément, jamais une condition de bon
/// fonctionnement du jeu.
class SoundEffects with WidgetsBindingObserver {
  SoundEffects._();

  static final SoundEffects instance = SoundEffects._();

  bool _effectsEnabled = true;
  bool _musicWanted = true;
  bool _musicPlaying = false;
  bool _testDisabled = false;
  bool _observing = false;
  bool _inBackground = false;
  AudioPlayer? _musicPlayer;

  /// Synchronise l'état (effets sonores + musique) avec les préférences
  /// utilisateur ; appelé à chaque changement de réglages.
  void applySettings(AppSettings settings) {
    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
    }
    _effectsEnabled = settings.soundEffectsEnabled;
    _musicWanted = settings.musicEnabled;
    if (_inBackground) return; // repris/coupé au retour, voir didChangeAppLifecycleState
    if (_musicWanted && !_musicPlaying) {
      _startMusic();
    } else if (!_musicWanted && _musicPlaying) {
      _stopMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_inBackground) return;
      _inBackground = false;
      if (_musicWanted) _resumeMusic();
      return;
    }
    // inactive/hidden/paused/detached : la première transition hors
    // "resumed" suffit à couper le son, pas la peine d'attendre "paused".
    if (_inBackground) return;
    _inBackground = true;
    _pauseMusic();
  }

  Future<void> _play(String assetPath) async {
    if (_testDisabled || !_effectsEnabled || _inBackground) return;
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

  /// Met la musique en pause sans la décharger (contrairement à
  /// [_stopMusic]) : elle reprend exactement où elle en était via
  /// [_resumeMusic], pas depuis le début.
  Future<void> _pauseMusic() async {
    final player = _musicPlayer;
    if (player == null) return;
    try {
      await player.pause();
    } catch (_) {
      // Rien de plus à faire : au pire la musique continue en arrière-plan.
    }
  }

  Future<void> _resumeMusic() async {
    final player = _musicPlayer;
    if (player == null) {
      // Aucun lecteur en pause à reprendre (ex: la musique était désactivée
      // au moment du passage en arrière-plan, puis réactivée entre-temps
      // dans les réglages) : redémarrer proprement plutôt que planter.
      if (_musicWanted) await _startMusic();
      return;
    }
    try {
      await player.resume();
    } catch (_) {
      // Rien de plus à faire : la musique reste simplement coupée.
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
