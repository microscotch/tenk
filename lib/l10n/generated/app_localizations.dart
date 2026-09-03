import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('it'),
    Locale('nb'),
    Locale('pt'),
    Locale('ro'),
    Locale('sv'),
  ];

  /// Mot affiché sous l'avatar sur l'écran d'introduction ("[Auteur] présente").
  ///
  /// In fr, this message translates to:
  /// **'présente'**
  String get splashPresents;

  /// Titre du dialogue demandant son nom au propriétaire de l'appareil.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom ?'**
  String get ownerNameDialogTitle;

  /// Libellé du champ de saisie dans le dialogue "Votre nom ?".
  ///
  /// In fr, this message translates to:
  /// **'Nom du joueur principal'**
  String get ownerNameFieldLabel;

  /// Bouton pour repousser la saisie du nom du joueur principal.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get laterButton;

  /// Bouton de validation d'un dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validateButton;

  /// Infobulle de l'icône d'accès aux réglages.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTooltip;

  /// Infobulle de l'icône d'accès à l'écran des règles du jeu, sur l'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Règles du jeu'**
  String get helpTooltip;

  /// Infobulle de l'icône d'accès au dialogue "À propos", sur l'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTooltip;

  /// Ligne affichant le numéro de version et le code de version (versionCode Android / CFBundleVersion iOS) dans le dialogue "À propos".
  ///
  /// In fr, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String aboutVersionLabel(String version, String buildNumber);

  /// Bouton générique pour fermer un dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// Bouton d'acquittement de l'écran de fin de partie, qui ramène à l'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get okButton;

  /// Titre de la liste des joueurs sur l'écran de configuration, avec leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs ({count})'**
  String playersCountTitle(int count);

  /// Nom par défaut attribué à un joueur humain (ex. "Joueur 1").
  ///
  /// In fr, this message translates to:
  /// **'Joueur {number}'**
  String defaultPlayerName(int number);

  /// Nom de secours si le champ de nom d'un joueur est laissé vide au démarrage de la partie.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get unnamedPlayerFallback;

  /// Libellé du champ de saisie du nom d'un joueur, sur l'écran de configuration.
  ///
  /// In fr, this message translates to:
  /// **'Nom du joueur {number}'**
  String playerNameFieldLabel(int number);

  /// Libellé du bouton à bascule activant le mode automatique d'un joueur.
  ///
  /// In fr, this message translates to:
  /// **'AutoRoll'**
  String get autoChipLabel;

  /// Libellé du bouton à bascule désignant un joueur comme IA.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get aiChipLabel;

  /// Bouton pour ajouter un joueur sur l'écran de configuration.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addPlayerButton;

  /// Bouton pour retirer un joueur sur l'écran de configuration.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get removePlayerButton;

  /// Titre du sélecteur de difficulté des joueurs IA.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté des bots'**
  String get botDifficultyTitle;

  /// Niveau de difficulté IA le plus prudent.
  ///
  /// In fr, this message translates to:
  /// **'Prudent'**
  String get aiDifficultyCautious;

  /// Niveau de difficulté IA intermédiaire.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get aiDifficultyBalanced;

  /// Niveau de difficulté IA le plus agressif.
  ///
  /// In fr, this message translates to:
  /// **'Agressif'**
  String get aiDifficultyAggressive;

  /// Bouton pour démarrer la partie (écran de configuration et écran de tirage au sort).
  ///
  /// In fr, this message translates to:
  /// **'Commencer la partie'**
  String get startGameButton;

  /// Libellé de la zone de l'écran d'accueil contenant la configuration d'une nouvelle partie.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau run...'**
  String get newGameSectionLabel;

  /// Libellé de la zone de l'écran d'accueil listant les parties en pause reprenables, avec leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Runs interrompus ({count})'**
  String pausedGamesSectionLabel(int count);

  /// Libellé de la zone de l'écran d'accueil listant les runs terminés, rejouables en mode spectateur, avec leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Runs terminés ({count})'**
  String finishedRunsSectionLabel(int count);

  /// Message affiché quand la liste des parties en pause est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie en pause pour l\'instant.'**
  String get noPausedGamesMessage;

  /// Message affiché quand la liste des runs terminés est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun run terminé pour l\'instant.'**
  String get noFinishedRunsMessage;

  /// Titre de la boîte de dialogue confirmant la suppression d'une partie en pause.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette partie ?'**
  String get deleteGameConfirmTitle;

  /// Message de la boîte de dialogue confirmant la suppression d'une partie en pause.
  ///
  /// In fr, this message translates to:
  /// **'La partie « {alias} » sera définitivement supprimée.'**
  String deleteGameConfirmMessage(String alias);

  /// Bouton générique pour annuler une action en cours (ex: boîte de dialogue de confirmation).
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// Bouton générique pour confirmer une suppression (ex: boîte de dialogue de confirmation).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// Titre de la boîte de dialogue proposant de reprendre la dernière partie interrompue, affichée à l'ouverture de l'écran d'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la partie ?'**
  String get resumeLastGameDialogTitle;

  /// Message de la boîte de dialogue proposant de reprendre la dernière partie interrompue.
  ///
  /// In fr, this message translates to:
  /// **'Une partie « {alias} » est en cours. Voulez-vous la reprendre ?'**
  String resumeLastGameDialogMessage(String alias);

  /// Bouton pour confirmer la reprise de la dernière partie interrompue.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resumeGameButton;

  /// Infobulle de l'icône permettant de quitter une partie en cours pour revenir à l'écran d'accueil (la partie reste sauvegardée).
  ///
  /// In fr, this message translates to:
  /// **'Quitter la partie'**
  String get leaveGameTooltip;

  /// Titre/infobulle de l'écran affichant la grille complète des scores de tous les joueurs.
  ///
  /// In fr, this message translates to:
  /// **'Grille des scores'**
  String get scoreGridLabel;

  /// Bandeau affiché quand un joueur a atteint 10000 et que les autres jouent leur dernier tour.
  ///
  /// In fr, this message translates to:
  /// **'Tour final : un joueur a atteint 10000 !'**
  String get finalRoundBanner;

  /// Libellé de la zone bordurée affichant le lancer de dés en attente de décision, sans lancer en attente.
  ///
  /// In fr, this message translates to:
  /// **'Piste'**
  String get currentRollZoneLabel;

  /// Libellé de la zone "Piste" quand un lancer est en attente de décision, avec son score entre parenthèses.
  ///
  /// In fr, this message translates to:
  /// **'Piste ({points})'**
  String currentRollZoneLabelWithScore(int points);

  /// Préfixe du libellé de la zone bordurée affichant les dés gardés ce tour, suivi du score du tour et du minimum requis (colorés en Dart, voir game_screen.dart).
  ///
  /// In fr, this message translates to:
  /// **'Main courante'**
  String get currentHandZoneLabel;

  /// Texte de substitution dans la zone "Lancé" quand aucun lancer n'est en attente de décision.
  ///
  /// In fr, this message translates to:
  /// **'En attente du prochain lancer'**
  String get awaitingRollPlaceholder;

  /// Entrée du journal de partie quand un lancer déclenche des dés chauds (tous les dés ont scoré).
  ///
  /// In fr, this message translates to:
  /// **'Main pleine !'**
  String get logHotDiceMessage;

  /// Entrée du journal de partie quand le score d'un autre joueur est barré par collision (score identique nouvellement marqué) ; suivi du score barré et du blason du joueur concerné.
  ///
  /// In fr, this message translates to:
  /// **'Score barré :'**
  String get logScoreCollisionMessage;

  /// Entrée du journal de partie quand le joueur prend la mise (banque son score) : score pris, suivi du nombre de dés restants hérités par le joueur suivant.
  ///
  /// In fr, this message translates to:
  /// **'{score} {count, plural, one{{count} dé} other{{count} dés}}'**
  String logBankedMessage(int score, int count);

  /// Message expliquant pourquoi la main héritée ne peut pas être reprise.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre cette main dépasserait déjà 10000 : impossible de banquer.'**
  String get inheritedHandExceedsWinning;

  /// Bouton pour refuser la main héritée et repartir avec une main pleine (joueur humain).
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get declineInheritedHandButton;

  /// Libellé du bouton unique de l'IA quand elle décide de repartir avec une main pleine.
  ///
  /// In fr, this message translates to:
  /// **'Repartir avec 5 dés neufs'**
  String get aiRestartWithFreshDiceLabel;

  /// Bouton reflétant l'action de l'IA sur un lancer en attente de décision (tour IA uniquement).
  ///
  /// In fr, this message translates to:
  /// **'Garder les dés'**
  String get keepDiceButton;

  /// Bouton pour arrêter son tour et banquer le score.
  ///
  /// In fr, this message translates to:
  /// **'S\'arrêter'**
  String get stopButton;

  /// Nombre de dés que le joueur courant s'apprête à lancer.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} dé} other{{count} dés}} à lancer'**
  String diceToRollLabel(int count);

  /// Titre affiché quand le joueur craque (bust).
  ///
  /// In fr, this message translates to:
  /// **'Craqué !'**
  String get bustedTitle;

  /// Explique un craque déclenché par un dépassement de 10000 points.
  ///
  /// In fr, this message translates to:
  /// **'Ce lancer ferait dépasser 10000.'**
  String get bustExceedsTarget;

  /// Avertissement affiché quand tous les dés ont scoré, obligeant à relancer.
  ///
  /// In fr, this message translates to:
  /// **'Main pleine : vous devez relancer !'**
  String get fullHandMustReroll;

  /// Raison pour laquelle le joueur ne peut pas encore s'arrêter : score sous le minimum requis.
  ///
  /// In fr, this message translates to:
  /// **'Score insuffisant pour s\'arrêter.'**
  String get failureBelowMinimum;

  /// Raison pour laquelle le joueur ne peut pas s'arrêter : le score se terminerait par 50.
  ///
  /// In fr, this message translates to:
  /// **'Interdit de s\'arrêter sur un score finissant par 50.'**
  String get failureEndsIn50;

  /// Raison pour laquelle le joueur ne peut pas s'arrêter : main pleine, relance obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez relancer.'**
  String get failureMustContinueHotDice;

  /// Raison pour laquelle le joueur ne peut pas s'arrêter : aucun lancer effectué ce tour.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez lancer les dés avant de pouvoir vous arrêter.'**
  String get failureNotRolledYet;

  /// Raison pour laquelle le joueur ne peut pas s'arrêter : le score obtenu serait trop proche de 10000 pour qu'un futur tour (minimum 200) puisse encore l'atteindre exactement.
  ///
  /// In fr, this message translates to:
  /// **'S\'arrêter rendrait la victoire à 10000 inatteignable.'**
  String get failureWouldMakeWinningImpossible;

  /// Titre de la section réglages consacrée au joueur principal.
  ///
  /// In fr, this message translates to:
  /// **'Joueur principal'**
  String get settingsMainPlayerTitle;

  /// Libellé du champ de saisie du nom du propriétaire de l'appareil, dans les réglages.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom (propriétaire de l\'appareil)'**
  String get settingsYourNameLabel;

  /// Titre de la section réglages consacrée aux délais d'auto-validation.
  ///
  /// In fr, this message translates to:
  /// **'Temporisations'**
  String get settingsDelaysTitle;

  /// Explication de la section temporisations.
  ///
  /// In fr, this message translates to:
  /// **'Délai avant qu\'une action automatique ne se déclenche seule. 0 pour désactiver.'**
  String get settingsDelaysDescription;

  /// Libellé du champ réglant le délai d'auto-validation des actions IA.
  ///
  /// In fr, this message translates to:
  /// **'Messages IA (ms)'**
  String get settingsAiDelayLabel;

  /// Libellé du champ réglant le délai d'auto-validation des actions du joueur humain.
  ///
  /// In fr, this message translates to:
  /// **'Actions automatiques du joueur humain (ms)'**
  String get settingsAutoActionDelayLabel;

  /// Titre de la section réglages consacrée à l'apparence des dés.
  ///
  /// In fr, this message translates to:
  /// **'Dés'**
  String get settingsDiceTitle;

  /// Mode de couleur des dés : une seule couleur pour tous.
  ///
  /// In fr, this message translates to:
  /// **'Uniforme'**
  String get settingsDiceUniform;

  /// Mode de couleur des dés : une couleur différente par dé.
  ///
  /// In fr, this message translates to:
  /// **'Panachée'**
  String get settingsDiceVaried;

  /// Titre de la section réglages consacrée au son.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settingsSoundsTitle;

  /// Interrupteur activant/désactivant la musique de fond.
  ///
  /// In fr, this message translates to:
  /// **'Musique de fond'**
  String get settingsMusicLabel;

  /// Interrupteur activant/désactivant les effets sonores.
  ///
  /// In fr, this message translates to:
  /// **'Effets sonores'**
  String get settingsSoundEffectsLabel;

  /// Titre de la section réglages consacrée aux parties en pause.
  ///
  /// In fr, this message translates to:
  /// **'Parties en pause'**
  String get settingsPausedGamesTitle;

  /// Interrupteur activant/désactivant la confirmation avant de purger une partie en pause par balayage.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer avant de supprimer une partie'**
  String get settingsConfirmBeforeDeleteGameLabel;

  /// Titre de la section réglages consacrée à la langue de l'application.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageTitle;

  /// Option du sélecteur de langue qui suit automatiquement la langue de l'appareil.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get settingsLanguageSystemOption;

  /// Titre de l'écran de tirage au sort de l'ordre de jeu.
  ///
  /// In fr, this message translates to:
  /// **'Qui commence ?'**
  String get diceOffTitle;

  /// Explication de la règle du tirage au sort.
  ///
  /// In fr, this message translates to:
  /// **'Chacun lance un dé : le score le plus faible commence la partie.'**
  String get diceOffInstructions;

  /// Annonce d'une égalité au tirage au sort ; noms déjà joints par des virgules.
  ///
  /// In fr, this message translates to:
  /// **'Égalité : {names} relancent.'**
  String diceOffTieBreak(String names);

  /// Indique quel joueur doit lancer le dé, pendant le tirage au sort.
  ///
  /// In fr, this message translates to:
  /// **'{playerName} lance le dé'**
  String diceOffPlayerTurn(String playerName);

  /// Bouton pour lancer le dé pendant le tirage au sort.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le dé'**
  String get diceOffRollButton;

  /// Annonce du joueur qui commence la partie, à l'issue du tirage au sort.
  ///
  /// In fr, this message translates to:
  /// **'{playerName} commence la partie !'**
  String diceOffWinnerAnnouncement(String playerName);

  /// Titre de l'écran de fin de partie.
  ///
  /// In fr, this message translates to:
  /// **'Fin de la partie'**
  String get gameOverTitle;

  /// Annonce du vainqueur sur l'écran de fin de partie.
  ///
  /// In fr, this message translates to:
  /// **'{playerName} gagne !'**
  String winnerAnnouncement(String playerName);

  /// Ligne "Nom : Score" dans le classement final.
  ///
  /// In fr, this message translates to:
  /// **'{name} : {score}'**
  String playerScoreLine(String name, int score);

  /// Instruction affichée entre deux tours, avant le nom du joueur suivant.
  ///
  /// In fr, this message translates to:
  /// **'Passez l\'appareil à'**
  String get passDeviceInstruction;

  /// Bouton confirmant que l'appareil a été passé au joueur suivant.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get readyButton;

  /// Indique qu'un joueur n'a pas encore atteint le score d'entrée en jeu.
  ///
  /// In fr, this message translates to:
  /// **'(pas entré)'**
  String get notEnteredLabel;

  /// Infobulle : le joueur peut barrer son voisin du dessus au tour suivant.
  ///
  /// In fr, this message translates to:
  /// **'À 200 points de barrer le joueur juste au-dessus !'**
  String get opportunityTooltip;

  /// Infobulle : le joueur risque d'être barré par son voisin du dessous au tour suivant.
  ///
  /// In fr, this message translates to:
  /// **'Danger : le joueur juste en dessous n\'est qu\'à 200 points, risque de vous barrer'**
  String get dangerTooltip;

  /// Infobulle expliquant la sanction "tiret" sur la ligne de score courante.
  ///
  /// In fr, this message translates to:
  /// **'Tiret : un second craque barrera le score'**
  String get tiretTooltip;

  /// Infobulle indiquant que la ligne de score précédente portait un tiret.
  ///
  /// In fr, this message translates to:
  /// **'Le score précédent portait un tiret'**
  String get previousScoreHadTiretTooltip;

  /// Infobulle de la médaille d'or, sur la ligne du joueur en tête des scores.
  ///
  /// In fr, this message translates to:
  /// **'En tête'**
  String get rankFirstTooltip;

  /// Infobulle de la médaille d'argent, sur la ligne du deuxième joueur au score.
  ///
  /// In fr, this message translates to:
  /// **'2e au score'**
  String get rankSecondTooltip;

  /// Infobulle de la médaille de bronze, sur la ligne du troisième joueur au score.
  ///
  /// In fr, this message translates to:
  /// **'3e au score'**
  String get rankThirdTooltip;

  /// Titre de l'écran expliquant les règles du jeu.
  ///
  /// In fr, this message translates to:
  /// **'Règles du jeu'**
  String get rulesScreenTitle;

  /// Titre de la section "but du jeu" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'But du jeu'**
  String get rulesGoalTitle;

  /// Texte de la section "but du jeu" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Le premier joueur à atteindre exactement 10 000 points gagne la partie. Il faut viser ce chiffre pile : le dépasser ne compte pas.'**
  String get rulesGoalBody;

  /// Titre de la section "déroulement d'un tour" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Comment se joue un tour'**
  String get rulesTurnTitle;

  /// Texte de la section "déroulement d'un tour" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'À votre tour, vous lancez 5 dés. Certaines valeurs rapportent des points (voir ci-dessous), d\'autres ne servent à rien. Vous mettez de côté au moins un dé qui rapporte, puis vous choisissez : relancer les dés restants pour tenter d\'engranger plus de points, ou vous arrêter et encaisser ce que vous avez accumulé ce tour. Si un lancer ne rapporte aucun point, c\'est un craque (voir plus bas) et vous perdez tout ce que vous aviez accumulé ce tour.'**
  String get rulesTurnBody;

  /// Titre de la section "ce qui rapporte des points" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui rapporte des points'**
  String get rulesScoringTitle;

  /// Texte de la section "ce qui rapporte des points" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'• Un 1 isolé : 100 points. Un 5 isolé : 50 points. Les autres valeurs isolées (2, 3, 4, 6) ne rapportent rien.\n• Trois dés identiques : 1000 points pour trois 1, sinon la valeur du dé × 100 (trois 4 valent 400, trois 6 valent 600).\n• Un quatrième dé de la même valeur ajoute 1000 points de plus.\n• Les 5 dés identiques valent la valeur du dé × 1000, sauf cinq 1 qui rapportent directement 10 000 points : la victoire immédiate.\n• Une suite de 5 dés qui se suivent (1-2-3-4-5 ou 2-3-4-5-6) vaut 500 points.'**
  String get rulesScoringBody;

  /// Titre de la section "dés chauds" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Dés chauds : une seconde chance forcée'**
  String get rulesHotDiceTitle;

  /// Texte de la section "dés chauds" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Si tous les dés que vous venez de lancer rapportent des points, vous devez relancer les 5 dés en main : impossible de s\'arrêter à ce moment précis. C\'est ce qu\'on appelle des « dés chauds ».'**
  String get rulesHotDiceBody;

  /// Titre de la section "craque" (bust) de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Le craque'**
  String get rulesBustTitle;

  /// Texte de la section "craque" (bust) de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Si un lancer ne rapporte strictement aucun point, votre tour s\'arrête immédiatement et vous perdez tous les points accumulés ce tour (ce que vous aviez déjà encaissé lors des tours précédents reste acquis). Un craque marque aussi votre ligne de score actuelle d\'un tiret ; si elle en portait déjà un, elle est barrée et votre score retombe à sa valeur précédente.'**
  String get rulesBustBody;

  /// Titre de la section "seuil d'entrée" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Entrer dans la partie'**
  String get rulesEntryTitle;

  /// Texte de la section "seuil d'entrée" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Pour commencer à marquer des points, votre tout premier tour réussi doit rapporter au moins 500 points. Une fois entré dans la partie, chaque tour suivant doit rapporter au moins 200 points pour pouvoir s\'arrêter.'**
  String get rulesEntryBody;

  /// Titre de la section "interdiction de s'arrêter sur 50" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Jamais de score finissant par 50'**
  String get rulesNoFiftyTitle;

  /// Texte de la section "interdiction de s'arrêter sur 50" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez jamais choisir de vous arrêter volontairement sur un total de tour qui finit par 50 (comme 250 ou 450) : il faut relancer les dés jusqu\'à obtenir un total valide.'**
  String get rulesNoFiftyBody;

  /// Titre de la section "règle d'extension" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'La règle d\'extension'**
  String get rulesExtensionTitle;

  /// Texte de la section "règle d'extension" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Une fois que vous avez encaissé un brelan ou un carré d\'une valeur donnée (par exemple trois 4), tout dé isolé de cette même valeur obtenu plus tard dans le même tour rapporte 100 points au lieu de sa valeur habituelle — y compris un 5 isolé, qui vaut alors 100 au lieu de 50. Cet avantage disparaît dès que vous obtenez des dés chauds.'**
  String get rulesExtensionBody;

  /// Titre de la section "héritage des dés" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Hériter des dés du joueur précédent'**
  String get rulesInheritTitle;

  /// Texte de la section "héritage des dés" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Quand un joueur s\'arrête volontairement en ayant encore des dés non lancés, le joueur suivant peut choisir de reprendre ces dés restants ainsi que le score déjà accumulé comme base de départ, ou de repartir à zéro avec 5 dés neufs. En cas de craque, en revanche, le joueur suivant repart toujours avec 5 dés neufs, sans rien hériter.'**
  String get rulesInheritBody;

  /// Titre de la section "tiret et barré" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Tiret et barré'**
  String get rulesBarredTitle;

  /// Texte de la section "tiret et barré" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Un craque place un tiret d\'avertissement sur votre ligne de score actuelle si elle n\'en a pas déjà un. Si elle en a déjà un, la ligne est barrée et votre score retombe à sa valeur précédente. Si votre score atteint exactement le même total qu\'un autre joueur, ce dernier est barré de la même façon, qu\'il ait déjà un tiret ou non.'**
  String get rulesBarredBody;

  /// Titre de la section "victoire" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Comment gagner'**
  String get rulesVictoryTitle;

  /// Texte de la section "victoire" de l'écran des règles.
  ///
  /// In fr, this message translates to:
  /// **'Le premier joueur à atteindre exactement 10 000 points déclenche un tour final : chaque autre joueur a une dernière chance de l\'égaler ou de le dépasser à son tour. Si un autre joueur atteint lui aussi exactement 10 000 pendant ce tour final, il prend la couronne à sa place et un nouveau tour final recommence autour de lui.'**
  String get rulesVictoryBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bg',
    'de',
    'en',
    'es',
    'fi',
    'fr',
    'it',
    'nb',
    'pt',
    'ro',
    'sv',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nb':
      return AppLocalizationsNb();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
