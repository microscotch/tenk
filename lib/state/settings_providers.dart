import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Code de langue forcé (ex. "en", "es") ; null = suit la langue de
  /// l'appareil.
  final String? languageOverride;

  const AppSettings({
    this.playerName = '',
    this.aiMessageDelayMs = 1000,
    this.autoActionDelayMs = 2000,
    this.diceColorMode = DiceColorMode.uniform,
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.confirmBeforeDeleteGame = true,
    this.languageOverride,
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
    Object? languageOverride = _unset,
  }) {
    return AppSettings(
      playerName: playerName ?? this.playerName,
      aiMessageDelayMs: aiMessageDelayMs ?? this.aiMessageDelayMs,
      autoActionDelayMs: autoActionDelayMs ?? this.autoActionDelayMs,
      diceColorMode: diceColorMode ?? this.diceColorMode,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      confirmBeforeDeleteGame: confirmBeforeDeleteGame ?? this.confirmBeforeDeleteGame,
      languageOverride: identical(languageOverride, _unset) ? this.languageOverride : languageOverride as String?,
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
        languageOverride: prefs.getString(_keyLanguageOverride),
      );
    } catch (_) {
      // Pas de backend de persistance disponible (tests, plateforme non
      // supportée) : on reste sur les valeurs par défaut en mémoire.
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
