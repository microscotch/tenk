import 'package:flutter/material.dart';

/// Observateur de navigation global, enregistré sur [MaterialApp] dans
/// `main.dart`. Permet à un écran qui n'est jamais re-poussé (par ex.
/// [SetupScreen], toujours la première route de la pile) de savoir qu'il
/// redevient visible après qu'une route poussée par-dessus a été dépilée
/// (`RouteAware.didPopNext`), pour se rafraîchir à ce moment-là.
final RouteObserver<PageRoute<void>> routeObserver = RouteObserver<PageRoute<void>>();
