/// Délai par défaut avant qu'une action ou transition automatique (lancer de
/// l'IA, décision de garde/banque automatique d'un joueur humain sans choix
/// réel, changement d'écran) ne se déclenche seule. Centralisé ici pour
/// rester configurable en un seul endroit ; chaque écran concerné doit aussi
/// permettre d'interrompre l'attente par un clic n'importe où sur l'écran.
const Duration kAutoAdvanceDelay = Duration(seconds: 5);
