import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/ai/ai_profiles.dart';

/// Rendu des dés : une seule couleur pour tous, ou une couleur différente
/// par dé (façon set de dés de casino).
enum DiceColorMode { uniform, varied }

/// Préférences utilisateur persistées localement (indépendantes de toute
/// partie en cours). Chargées de façon best-effort au démarrage : en cas
/// d'échec (plateforme sans backend, tests) on reste sur les valeurs par
/// défaut plutôt que de bloquer ou de faire planter l'app.
class AppSettings {
  final String playerName;
  final int aiMessageDelayMs;
  final int autoActionDelayMs;
  final DiceColorMode diceColorMode;
  final bool musicEnabled;
  final bool soundEffectsEnabled;

  /// Demande confirmation avant de purger une partie en pause (swipe sur
  /// l'écran d'accueil). Désactivable pour une suppression immédiate.
  final bool confirmBeforeDeleteGame;

  /// Difficulté par défaut des joueurs IA sur une nouvelle partie (réglage
  /// global, plus de sélecteur par partie sur l'écran de configuration).
  final AiDifficulty aiDifficulty;

  /// Autorise le lancer de dés en secouant le téléphone (voir
  /// `ShakeDetector`), en plus du bouton "Lancer". Désactivé par défaut : un
  /// geste physique déclenché malgré lui (transport, poche...) resterait
  /// sans conséquence, mais reste une surprise pour qui ne l'a pas demandée.
  final bool shakeToRollEnabled;

  /// Affiche sur les boutons "Lancer" la probabilité de marquer au moins un
  /// point sur le prochain lancer. Désactivé par défaut : c'est une aide au
  /// calcul, qui retire au jeu une part de son pari.
  final bool showProbabilities;

  /// Code de langue forcé (ex. "en", "es") ; null = suit la langue de
  /// l'appareil.
  final String? languageOverride;

  /// Disposition des deux commandes latérales de la ligne de contrôle :
  /// vrai (défaut) place l'échange des 5 à gauche et Stop à droite, sous le
  /// pouce d'un droitier ; faux les échange. "Lancer" reste centré dans les
  /// deux cas.
  final bool rightHanded;

  /// Vrai une fois les préférences persistées relues — ou leur lecture
  /// abandonnée faute de backend. Tant que c'est faux, les valeurs exposées
  /// ne sont que les défauts : agir dessus démarrerait la musique juste pour
  /// la couper une fraction de seconde plus tard, et ça s'entend (voir
  /// `SoundEffects.applySettings`).
  final bool loaded;

  const AppSettings({
    this.playerName = '',
    this.aiMessageDelayMs = 1000,
    this.autoActionDelayMs = 2000,
    this.diceColorMode = DiceColorMode.uniform,
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.confirmBeforeDeleteGame = true,
    this.aiDifficulty = AiDifficulty.prudent,
    this.shakeToRollEnabled = false,
    this.showProbabilities = false,
    this.languageOverride,
    this.rightHanded = true,
    this.loaded = false,
  });

  Duration get aiMessageDelay => Duration(milliseconds: aiMessageDelayMs);
  Duration get autoActionDelay => Duration(milliseconds: autoActionDelayMs);

  AppSettings copyWith({
    String? playerName,
    int? aiMessageDelayMs,
    int? autoActionDelayMs,
    DiceColorMode? diceColorMode,
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? confirmBeforeDeleteGame,
    AiDifficulty? aiDifficulty,
    bool? shakeToRollEnabled,
    bool? showProbabilities,
    Object? languageOverride = _unset,
    bool? rightHanded,
    bool? loaded,
  }) {
    return AppSettings(
      playerName: playerName ?? this.playerName,
      aiMessageDelayMs: aiMessageDelayMs ?? this.aiMessageDelayMs,
      autoActionDelayMs: autoActionDelayMs ?? this.autoActionDelayMs,
      diceColorMode: diceColorMode ?? this.diceColorMode,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      confirmBeforeDeleteGame: confirmBeforeDeleteGame ?? this.confirmBeforeDeleteGame,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      shakeToRollEnabled: shakeToRollEnabled ?? this.shakeToRollEnabled,
      showProbabilities: showProbabilities ?? this.showProbabilities,
      languageOverride: identical(languageOverride, _unset) ? this.languageOverride : languageOverride as String?,
      rightHanded: rightHanded ?? this.rightHanded,
      loaded: loaded ?? this.loaded,
    );
  }
}

/// Sentinelle distincte de `null` : permet à [AppSettings.copyWith] de
/// distinguer "ne pas toucher à ce champ" de "le remettre à null" (suivre la
/// langue de l'appareil), pour un champ nullable.
const Object _unset = Object();

const _keyPlayerName = 'settings.playerName';
const _keyAiMessageDelayMs = 'settings.aiMessageDelayMs';
const _keyAutoActionDelayMs = 'settings.autoActionDelayMs';
const _keyDiceColorMode = 'settings.diceColorMode';
const _keyMusicEnabled = 'settings.musicEnabled';
const _keySoundEffectsEnabled = 'settings.soundEffectsEnabled';
const _keyConfirmBeforeDeleteGame = 'settings.confirmBeforeDeleteGame';
const _keyAiDifficulty = 'settings.aiDifficulty';
const _keyShakeToRollEnabled = 'settings.shakeToRollEnabled';
const _keyShowProbabilities = 'settings.showProbabilities';
const _keyRightHanded = 'settings.rightHanded';
const _keyLanguageOverride = 'settings.languageOverride';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Valeurs par défaut synchrones : l'UI n'attend jamais après le disque,
    // les préférences sauvegardées sont appliquées dès qu'elles arrivent.
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppSettings(
        playerName: prefs.getString(_keyPlayerName) ?? '',
        aiMessageDelayMs: prefs.getInt(_keyAiMessageDelayMs) ?? 1000,
        autoActionDelayMs: prefs.getInt(_keyAutoActionDelayMs) ?? 2000,
        diceColorMode: prefs.getString(_keyDiceColorMode) == 'varied' ? DiceColorMode.varied : DiceColorMode.uniform,
        musicEnabled: prefs.getBool(_keyMusicEnabled) ?? true,
        soundEffectsEnabled: prefs.getBool(_keySoundEffectsEnabled) ?? true,
        confirmBeforeDeleteGame: prefs.getBool(_keyConfirmBeforeDeleteGame) ?? true,
        aiDifficulty: AiDifficulty.values.firstWhere(
          (d) => d.name == prefs.getString(_keyAiDifficulty),
          orElse: () => AiDifficulty.prudent,
        ),
        shakeToRollEnabled: prefs.getBool(_keyShakeToRollEnabled) ?? false,
        showProbabilities: prefs.getBool(_keyShowProbabilities) ?? false,
        languageOverride: prefs.getString(_keyLanguageOverride),
        rightHanded: prefs.getBool(_keyRightHanded) ?? true,
        loaded: true,
      );
    } catch (_) {
      // Pas de backend de persistance disponible (tests, plateforme non
      // supportée) : on reste sur les valeurs par défaut en mémoire, mais
      // elles sont désormais définitives — il n'y a plus rien à attendre.
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> _save(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (value) {
        case String s:
          await prefs.setString(key, s);
        case int i:
          await prefs.setInt(key, i);
        case bool b:
          await prefs.setBool(key, b);
      }
    } catch (_) {
      // Idem : la session en cours garde la valeur en mémoire.
    }
  }

  void setPlayerName(String name) {
    state = state.copyWith(playerName: name);
    _save(_keyPlayerName, name);
  }

  void setAiMessageDelayMs(int ms) {
    final clamped = ms < 0 ? 0 : ms;
    state = state.copyWith(aiMessageDelayMs: clamped);
    _save(_keyAiMessageDelayMs, clamped);
  }

  void setAutoActionDelayMs(int ms) {
    final clamped = ms < 0 ? 0 : ms;
    state = state.copyWith(autoActionDelayMs: clamped);
    _save(_keyAutoActionDelayMs, clamped);
  }

  void setDiceColorMode(DiceColorMode mode) {
    state = state.copyWith(diceColorMode: mode);
    _save(_keyDiceColorMode, mode == DiceColorMode.varied ? 'varied' : 'uniform');
  }

  void setMusicEnabled(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    _save(_keyMusicEnabled, enabled);
  }

  void setSoundEffectsEnabled(bool enabled) {
    state = state.copyWith(soundEffectsEnabled: enabled);
    _save(_keySoundEffectsEnabled, enabled);
  }

  void setConfirmBeforeDeleteGame(bool enabled) {
    state = state.copyWith(confirmBeforeDeleteGame: enabled);
    _save(_keyConfirmBeforeDeleteGame, enabled);
  }

  void setAiDifficulty(AiDifficulty difficulty) {
    state = state.copyWith(aiDifficulty: difficulty);
    _save(_keyAiDifficulty, difficulty.name);
  }

  void setShakeToRollEnabled(bool enabled) {
    state = state.copyWith(shakeToRollEnabled: enabled);
    _save(_keyShakeToRollEnabled, enabled);
  }

  void setShowProbabilities(bool enabled) {
    state = state.copyWith(showProbabilities: enabled);
    _save(_keyShowProbabilities, enabled);
  }

  void setRightHanded(bool rightHanded) {
    state = state.copyWith(rightHanded: rightHanded);
    _save(_keyRightHanded, rightHanded);
  }

  /// [code] est un code de langue supporté (ex. "en"), ou null pour suivre à
  /// nouveau la langue de l'appareil.
  Future<void> setLanguageOverride(String? code) async {
    state = state.copyWith(languageOverride: code);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null) {
        await prefs.remove(_keyLanguageOverride);
      } else {
        await prefs.setString(_keyLanguageOverride, code);
      }
    } catch (_) {
      // Idem : la session en cours garde la valeur en mémoire.
    }
  }
}
