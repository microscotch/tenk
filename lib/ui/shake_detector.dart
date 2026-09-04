import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Détecte un geste de secousse du téléphone à partir du flux accéléromètre,
/// pour servir de déclencheur alternatif au lancer de dés (réglage "Secouer
/// pour lancer"). N'écoute réellement que sur Android/iOS : `sensors_plus`
/// n'a pas d'implémentation native ailleurs (desktop, web), donc [start] ne
/// fait rien sur ces cibles plutôt que de laisser une `MissingPluginException`
/// remonter du canal de la plateforme — en particulier sur ce poste de dev
/// Linux, seule cible locale exécutable (voir CLAUDE.md).
class ShakeDetector {
  /// Écart à la gravité (m/s², 9.8 au repos) au-delà duquel un pic
  /// d'accélération est considéré comme une secousse. Valeur empirique,
  /// reprise des implémentations "secouer pour annuler" usuelles : assez
  /// haute pour ignorer la marche ou un dépôt sur une table, assez basse
  /// pour rester déclenchable d'un geste de poignet volontaire.
  static const double _shakeThreshold = 18.0;

  /// Délai minimal entre deux secousses détectées : un seul geste physique
  /// produit plusieurs pics d'accélération successifs, sans ça un unique
  /// coup de poignet déclencherait plusieurs lancers d'affilée.
  static const Duration _cooldown = Duration(milliseconds: 1200);

  final VoidCallback onShake;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeAt;

  ShakeDetector({required this.onShake});

  bool get _supportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  void start() {
    if (!_supportedPlatform || _subscription != null) return;
    _subscription = accelerometerEventStream().listen(
      _onEvent,
      // Capteur indisponible (permission refusée, matériel absent, canal de
      // plateforme non implémenté...) : le geste reste simplement hors
      // service, le bouton "Lancer" continue de fonctionner normalement.
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if ((magnitude - 9.8).abs() < _shakeThreshold) return;
    final now = DateTime.now();
    if (_lastShakeAt != null && now.difference(_lastShakeAt!) < _cooldown) return;
    _lastShakeAt = now;
    onShake();
  }
}
