/// Durée d'affichage par défaut de l'écran de démarrage avant de passer seul
/// à l'écran d'accueil (voir [SplashScreen.displayDuration]) ; sautable par
/// un clic n'importe où sur l'écran.
///
/// Les délais d'action IA et d'action automatique du joueur humain sont
/// réglables séparément dans les préférences (voir `settings_providers.dart`)
/// et n'utilisent plus cette constante.
const Duration kAutoAdvanceDelay = Duration(seconds: 5);
