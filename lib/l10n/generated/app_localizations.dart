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
  /// **'Auto'**
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
  /// **'Nouvelle partie...'**
  String get newGameSectionLabel;

  /// Libellé de la zone de l'écran d'accueil listant les parties en pause reprenables.
  ///
  /// In fr, this message translates to:
  /// **'Parties en pause'**
  String get pausedGamesSectionLabel;

  /// Message affiché quand la liste des parties en pause est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie en pause pour l\'instant.'**
  String get noPausedGamesMessage;

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

  /// Score cumulé du tour en cours.
  ///
  /// In fr, this message translates to:
  /// **'Score du tour : {score}'**
  String turnScoreLabel(int score);

  /// Score minimum requis pour que le joueur courant puisse s'arrêter.
  ///
  /// In fr, this message translates to:
  /// **'Minimum requis : {minimum}'**
  String minimumRequiredLabel(int minimum);

  /// Étiquette au-dessus de la rangée de dés déjà gardés pendant le tour en cours.
  ///
  /// In fr, this message translates to:
  /// **'Dés gardés ce tour'**
  String get keptDiceThisTurnLabel;

  /// Annonce qu'un joueur hérite de dés d'un tour précédent réussi.
  ///
  /// In fr, this message translates to:
  /// **'{playerName} hérite de {diceCount, plural, one{{diceCount} dé} other{{diceCount} dés}} du tour précédent.'**
  String inheritedHandMessage(String playerName, int diceCount);

  /// Score déjà accumulé sur la main héritée proposée au joueur.
  ///
  /// In fr, this message translates to:
  /// **'Score en cours : {score}'**
  String currentScoreLabel(int score);

  /// Bouton pour reprendre la main héritée avec le nombre de dés restants (joueur humain).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec {count, plural, one{{count} dé} other{{count} dés}}'**
  String continueWithDiceButton(int count);

  /// Message expliquant pourquoi la main héritée ne peut pas être reprise.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre cette main dépasserait déjà 10000 : impossible de banquer.'**
  String get inheritedHandExceedsWinning;

  /// Bouton pour refuser la main héritée et repartir avec une main pleine (joueur humain).
  ///
  /// In fr, this message translates to:
  /// **'Recommencer avec 5 dés neufs'**
  String get restartWithFreshDiceButton;

  /// Libellé du bouton unique de l'IA quand elle décide de reprendre la main héritée.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre avec {count, plural, one{{count} dé} other{{count} dés}}'**
  String aiContinueWithDiceButton(int count);

  /// Libellé du bouton unique de l'IA quand elle décide de repartir avec une main pleine.
  ///
  /// In fr, this message translates to:
  /// **'Repartir avec 5 dés neufs'**
  String get aiRestartWithFreshDiceLabel;

  /// Bouton pour valider la garde des dés d'un lancer.
  ///
  /// In fr, this message translates to:
  /// **'Garder les dés'**
  String get keepDiceButton;

  /// Bouton pour relancer quand tous les dés ont scoré (main pleine, relance obligatoire).
  ///
  /// In fr, this message translates to:
  /// **'Relancer (main pleine)'**
  String get reRollFullHandButton;

  /// Bouton pour arrêter son tour et banquer le score.
  ///
  /// In fr, this message translates to:
  /// **'S\'arrêter'**
  String get stopButton;

  /// Bouton pour lancer les dés.
  ///
  /// In fr, this message translates to:
  /// **'Lancer les dés'**
  String get rollDiceButton;

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

  /// Bouton pour passer la main après un craque.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// Score que rapporterait le lancer en attente selon la sélection actuelle.
  ///
  /// In fr, this message translates to:
  /// **'Score de ce lancer : {score}'**
  String thisRollScoreLabel(int score);

  /// Question posée quand le joueur peut choisir combien de 5 garder sur un lancer.
  ///
  /// In fr, this message translates to:
  /// **'Combien de 5 garder ?'**
  String get howManyFivesToKeep;

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

  /// Bouton pour revenir à l'écran de configuration après une partie.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie'**
  String get newGameButton;

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

  /// Infobulle sur la fraction de probabilité de marquer avec les dés restants.
  ///
  /// In fr, this message translates to:
  /// **'Probabilité de marquer sur {count, plural, one{{count} dé} other{{count} dés}}'**
  String scoreProbabilityTooltip(int count);
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
