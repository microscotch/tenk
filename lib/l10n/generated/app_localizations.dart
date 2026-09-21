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

  /// Bouton de l'écran d'accueil ouvrant la création d'une partie, et titre de cet écran de création.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie'**
  String get newGameSectionLabel;

  /// Bouton de l'écran d'accueil ouvrant la liste des parties interrompues ; inerte tant qu'il n'y en a aucune.
  ///
  /// In fr, this message translates to:
  /// **'Reprise de parties'**
  String get resumeGamesButton;

  /// Bouton de l'écran d'accueil ouvrant la base des joueurs humains (création, édition, suppression).
  ///
  /// In fr, this message translates to:
  /// **'Gestion des joueurs'**
  String get managePlayersButton;

  /// Bouton de l'écran d'accueil ouvrant la liste des parties terminées, rejouables en mode spectateur.
  ///
  /// In fr, this message translates to:
  /// **'Dernières parties terminées'**
  String get finishedGamesButton;

  /// Bouton de l'écran d'accueil ouvrant la consultation des statistiques des joueurs.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statisticsButton;

  /// Titre de l'écran de gestion des joueurs, avec le nombre de fiches en base.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs ({count})'**
  String playersScreenTitle(int count);

  /// Infobulle du bouton de création d'une fiche joueur.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get addPlayerTooltip;

  /// Message affiché quand la base de joueurs est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur enregistré pour l\'instant.'**
  String get noPlayersMessage;

  /// Titre de l'écran de création d'une fiche joueur.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau joueur'**
  String get newPlayerTitle;

  /// Titre de l'écran d'édition d'une fiche joueur existante.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le joueur'**
  String get editPlayerTitle;

  /// Libellé du champ de nom d'une fiche joueur (obligatoire, unique).
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get playerNameLabel;

  /// Libellé du champ de surnom d'une fiche joueur.
  ///
  /// In fr, this message translates to:
  /// **'Surnom (facultatif)'**
  String get playerNicknameLabel;

  /// Erreur affichée quand le champ de nom d'une fiche joueur est vide.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get playerNameRequiredError;

  /// Erreur affichée quand le nom saisi correspond à une fiche existante (casse et accents ignorés).
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est déjà utilisé par un autre joueur.'**
  String get playerNameTakenError;

  /// Titre de la boîte de dialogue confirmant la suppression d'une fiche joueur.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce joueur ?'**
  String get deletePlayerConfirmTitle;

  /// Message de la boîte de dialogue confirmant la suppression d'une fiche joueur.
  ///
  /// In fr, this message translates to:
  /// **'La fiche de « {name} » et ses statistiques seront définitivement supprimées. Les parties déjà jouées, elles, sont conservées.'**
  String deletePlayerConfirmMessage(String name);

  /// Titre de la section des statistiques de durée.
  ///
  /// In fr, this message translates to:
  /// **'Temps de jeu'**
  String get statsSectionTime;

  /// Titre de la section des statistiques de parties jouées, gagnées, perdues.
  ///
  /// In fr, this message translates to:
  /// **'Parties'**
  String get statsSectionGames;

  /// Titre de la section des statistiques de combinaisons (brelans, carrés, quintes, suites).
  ///
  /// In fr, this message translates to:
  /// **'Figures'**
  String get statsSectionFigures;

  /// Titre de la section des statistiques de volume de jeu : tours joués, lancers, lancers par tour.
  ///
  /// In fr, this message translates to:
  /// **'Tours et lancers'**
  String get statsSectionRolls;

  /// Nombre de tours joués, banqués comme craqués. Pour un joueur, ou au total pour une partie.
  ///
  /// In fr, this message translates to:
  /// **'Tours joués'**
  String get statsTurns;

  /// Nombre de lancers de dés, y compris celui qui fait craquer et les relances de main pleine.
  ///
  /// In fr, this message translates to:
  /// **'Lancers'**
  String get statsRolls;

  /// Nombre moyen de lancers par tour : le total des lancers rapporté au total des tours.
  ///
  /// In fr, this message translates to:
  /// **'Lancers par tour'**
  String get statsRollsPerTurn;

  /// Titre de la section des statistiques diverses : meilleur tour, mains pleines, craquages, barrés.
  ///
  /// In fr, this message translates to:
  /// **'Faits d\'armes'**
  String get statsSectionMisc;

  /// Libellé du temps de jeu cumulé.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get statsTotalTime;

  /// Libellé de la durée moyenne d'une partie.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne par partie'**
  String get statsAverageTime;

  /// Libellé de la partie la plus courte.
  ///
  /// In fr, this message translates to:
  /// **'La plus courte'**
  String get statsShortestTime;

  /// Libellé de la partie la plus longue.
  ///
  /// In fr, this message translates to:
  /// **'La plus longue'**
  String get statsLongestTime;

  /// Libellé du nombre de parties jouées.
  ///
  /// In fr, this message translates to:
  /// **'Jouées'**
  String get statsGamesPlayed;

  /// Libellé du nombre de parties gagnées.
  ///
  /// In fr, this message translates to:
  /// **'Gagnées'**
  String get statsGamesWon;

  /// Libellé du nombre de parties perdues.
  ///
  /// In fr, this message translates to:
  /// **'Perdues'**
  String get statsGamesLost;

  /// Libellé du nombre d'as isolés gardés.
  ///
  /// In fr, this message translates to:
  /// **'As isolés gardés'**
  String get statsLoneAces;

  /// Libellé du nombre de 5 isolés gardés.
  ///
  /// In fr, this message translates to:
  /// **'5 isolés gardés'**
  String get statsLoneFives;

  /// Libellé du nombre de brelans.
  ///
  /// In fr, this message translates to:
  /// **'Brelans'**
  String get statsBrelans;

  /// Libellé du nombre de carrés.
  ///
  /// In fr, this message translates to:
  /// **'Carrés'**
  String get statsCarres;

  /// Libellé du nombre de quintes.
  ///
  /// In fr, this message translates to:
  /// **'Quintes'**
  String get statsQuintes;

  /// Libellé du nombre de suites (petites et grandes).
  ///
  /// In fr, this message translates to:
  /// **'Suites'**
  String get statsSuites;

  /// Libellé du nombre de petites suites (1-2-3-4-5).
  ///
  /// In fr, this message translates to:
  /// **'dont petites'**
  String get statsSmallSuites;

  /// Libellé du nombre de grandes suites (2-3-4-5-6).
  ///
  /// In fr, this message translates to:
  /// **'dont grandes'**
  String get statsBigSuites;

  /// Libellé du nombre de quintes d'as (10000 d'un coup).
  ///
  /// In fr, this message translates to:
  /// **'Quintes d\'as'**
  String get statsAceQuints;

  /// Libellé du nombre de quintes d'as tombées pile sur la cible.
  ///
  /// In fr, this message translates to:
  /// **'dont gagnantes'**
  String get statsAceQuintsWon;

  /// Libellé du meilleur score banqué en un tour.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur tour'**
  String get statsBestTurn;

  /// Libellé de la plus longue série de mains pleines dans un tour.
  ///
  /// In fr, this message translates to:
  /// **'Mains pleines d\'affilée'**
  String get statsHotDiceRun;

  /// Libellé du nombre total de craquages.
  ///
  /// In fr, this message translates to:
  /// **'Craquages'**
  String get statsBusts;

  /// Libellé de la plus longue série de craquages consécutifs.
  ///
  /// In fr, this message translates to:
  /// **'dont série la plus longue'**
  String get statsLongestBustStreak;

  /// Libellé du nombre de lignes barrées par son propre second craque consécutif.
  ///
  /// In fr, this message translates to:
  /// **'Auto-barrés'**
  String get statsSelfBars;

  /// Libellé du nombre de lignes barrées chez un adversaire par collision de score.
  ///
  /// In fr, this message translates to:
  /// **'Barrés infligés'**
  String get statsBarsInflicted;

  /// Titre de l'écran montrant la courbe des scores de chaque joueur, et infobulle de l'icône qui l'ouvre depuis l'écran de jeu.
  ///
  /// In fr, this message translates to:
  /// **'Évolution des scores'**
  String get scoreChartTitle;

  /// Titre de l'écran des statistiques d'UNE partie terminée, et libellé du bouton qui l'ouvre depuis l'écran de fin de partie.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques de la partie'**
  String get gameStatsTitle;

  /// Titre de la section, en tête des statistiques d'une partie, qui donne ce qui vaut pour toute la table : durée, nombre de tours.
  ///
  /// In fr, this message translates to:
  /// **'Partie'**
  String get gameStatsGameSection;

  /// Titre de la section, en tête des statistiques d'une partie, qui totalise les figures sorties chez tous les joueurs.
  ///
  /// In fr, this message translates to:
  /// **'Figures de la partie'**
  String get gameStatsFiguresSection;

  /// Durée active de la partie terminée, hors temps passé en pause.
  ///
  /// In fr, this message translates to:
  /// **'Durée de jeu'**
  String get gameStatsDuration;

  /// Résumé sous le nom d'un joueur dans les statistiques d'une partie, lisible sans déplier son détail : ses tours joués, son meilleur tour banqué, ses craques.
  ///
  /// In fr, this message translates to:
  /// **'{turns, plural, one{{turns} tour} other{{turns} tours}} · meilleur {best} · {busts, plural, one{{busts} craque} other{{busts} craques}}'**
  String gameStatsPlayerSummary(int turns, int best, int busts);

  /// Résumé sous le nom d'un joueur dans les statistiques générales, lisible sans déplier son détail : ses parties jouées et gagnées, son meilleur tour banqué, tous cumulés.
  ///
  /// In fr, this message translates to:
  /// **'{games, plural, one{{games} partie} other{{games} parties}} · {won, plural, one{{won} gagnée} other{{won} gagnées}} · meilleur {best}'**
  String statsPlayerSummary(int games, int won, int best);

  /// Message affiché quand la courbe des scores n'a aucun point, faute de tour achevé.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tour terminé pour l\'instant : il n\'y a encore rien à tracer.'**
  String get scoreChartEmpty;

  /// Légende de l'axe horizontal de la courbe des scores : le numéro de tour de chaque joueur.
  ///
  /// In fr, this message translates to:
  /// **'Tours joués'**
  String get scoreChartXAxis;

  /// Préfixe d'une ligne de ventilation d'une figure par valeur de dé, suivi du dé concerné (ex. « dont ⚃ »).
  ///
  /// In fr, this message translates to:
  /// **'dont'**
  String get statsBreakdownRow;

  /// Titre de la section listant les meilleures performances tous joueurs confondus.
  ///
  /// In fr, this message translates to:
  /// **'Records'**
  String get statsRecordsTitle;

  /// Message affiché quand aucune partie n'a encore été jouée.
  ///
  /// In fr, this message translates to:
  /// **'Aucun record pour l\'instant.'**
  String get statsNoRecordYet;

  /// Une ligne de record : la valeur, puis le ou les joueurs qui la détiennent.
  ///
  /// In fr, this message translates to:
  /// **'{value} — {holders}'**
  String statsValueWithHolder(String value, String holders);

  /// Titre de l'écran de sélection multiple de joueurs pour une nouvelle partie.
  ///
  /// In fr, this message translates to:
  /// **'Choisir des joueurs'**
  String get pickPlayersTitle;

  /// Infobulle de l'icône ajoutant des joueurs humains à la partie en préparation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get addHumanTooltip;

  /// Infobulle de l'icône ajoutant un adversaire IA à la partie en préparation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un bot'**
  String get addBotTooltip;

  /// Bouton de l'écran de sélection ouvrant la création d'une fiche, pour un joueur absent de la base.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau joueur'**
  String get createPlayerButton;

  /// Message de l'écran de sélection quand la base de joueurs est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun joueur en base. Créez-en un pour commencer.'**
  String get noPlayersToPickMessage;

  /// Étiquette d'un adversaire IA dans la liste des joueurs d'une partie en préparation.
  ///
  /// In fr, this message translates to:
  /// **'Bot'**
  String get botLabel;

  /// Infobulle du bouton retirant un joueur de la partie en préparation.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la partie'**
  String get removeSeatTooltip;

  /// Message affiché quand on tente de démarrer une partie à moins de deux joueurs.
  ///
  /// In fr, this message translates to:
  /// **'Il faut au moins deux joueurs.'**
  String get notEnoughPlayersMessage;

  /// Résumé sous le nom d'un joueur dans la liste : son nombre de parties jouées.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune partie jouée} one{{count} partie jouée} other{{count} parties jouées}}'**
  String playerGamesSummary(int count);

  /// Libellé de la zone de l'écran d'accueil listant les parties en pause reprenables, avec leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Runs interrompues ({count})'**
  String pausedGamesSectionLabel(int count);

  /// Libellé de la zone de l'écran d'accueil listant les runs terminés, rejouables en mode spectateur, avec leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Runs terminées ({count})'**
  String finishedRunsSectionLabel(int count);

  /// Message affiché quand la liste des parties en pause est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune partie en pause pour l\'instant.'**
  String get noPausedGamesMessage;

  /// Message affiché quand la liste des runs terminés est vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune run terminée pour l\'instant.'**
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

  /// Bouton de l'écran de fin de partie qui relance le rejeu spectateur de la partie, départage compris.
  ///
  /// In fr, this message translates to:
  /// **'Revoir la partie'**
  String get gameOverReplayButton;

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

  /// Entrée du journal de partie résumant un lancer résolu : dés gardés, points marqués sur ce lancer, dés restant à relancer, puis total de la main en cours.
  ///
  /// In fr, this message translates to:
  /// **'{kept} : {gain}, {count, plural, one{{count} dé} other{{count} dés}} => {total} pts'**
  String logRollGainMessage(String kept, int gain, int count, int total);

  /// Variante de logRollGainMessage quand le lancer complète la main (tous les dés scorent) : la main repart pleine au lieu d'annoncer des dés restants.
  ///
  /// In fr, this message translates to:
  /// **'{kept} : {gain}, main pleine => {total} pts'**
  String logRollGainHotDiceMessage(String kept, int gain, int total);

  /// Entrée du journal de partie quand le joueur prend la mise (banque sa main) : score encaissé, puis son nouveau score total.
  ///
  /// In fr, this message translates to:
  /// **'{score} pts sont pris => {total} pts'**
  String logBankedMessage(int score, int total);

  /// Entrée du journal de partie quand le joueur reprend la main laissée par le joueur précédent, avec le score déjà acquis dessus qui lui sert de base.
  ///
  /// In fr, this message translates to:
  /// **'{score} pts sont repris'**
  String logResumedHandMessage(int score);

  /// Entrée du journal pour un craque qui marque un petit trait (tiret) sur la ligne courante : le score acquis ne bouge pas.
  ///
  /// In fr, this message translates to:
  /// **'Craqué ! => {score} petit trait'**
  String logBustTiretMessage(int score);

  /// Début de l'entrée du journal pour un craque qui barre la ligne courante ; suivi du score barré, puis de logBustBarredReturnMessage.
  ///
  /// In fr, this message translates to:
  /// **'Craqué ! =>'**
  String get logBustBarredPrefix;

  /// Fin de l'entrée du journal pour un craque qui barre la ligne courante : score sur lequel le joueur retombe.
  ///
  /// In fr, this message translates to:
  /// **'retour à {score}'**
  String logBustBarredReturnMessage(int score);

  /// Message expliquant pourquoi la main héritée ne peut pas être reprise.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre cette main atteindrait déjà 10000 : impossible de banquer.'**
  String get inheritedHandExceedsWinning;

  /// Bouton pour refuser la main héritée et repartir avec une main pleine (joueur humain).
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get declineInheritedHandButton;

  /// Bouton pour lancer les dés, quand l'affichage des probabilités est désactivé (sinon le bouton porte le pourcentage).
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get rollButton;

  /// Réglage activant l'affichage du pourcentage de chance de marquer sur les boutons de lancer.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les probabilités'**
  String get showProbabilitiesSetting;

  /// Explication du réglage d'affichage des probabilités.
  ///
  /// In fr, this message translates to:
  /// **'Affiche sur le bouton \"Lancer\" la chance de marquer au moins un point'**
  String get showProbabilitiesSettingSubtitle;

  /// Bouton pour arrêter son tour et banquer le score.
  ///
  /// In fr, this message translates to:
  /// **'S\'arrêter'**
  String get stopButton;

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

  /// Explique un craque déclenché par une main pleine tombant pile sur 10000 : la main pleine oblige à relancer, et tout relancer marquant dépasserait la cible.
  ///
  /// In fr, this message translates to:
  /// **'Main pleine à 10000 : impossible de s\'arrêter, et tout relancer dépasserait.'**
  String get bustFullHandAtTarget;

  /// Bouton de la popup de craque pour l'acquitter et passer la main.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get bustContinueButton;

  /// Titre de la popup proposant de reprendre ou non la main laissée par le joueur précédent : posé en question, les deux réponses étant les icônes valider/refuser qu'elle affiche.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre ?'**
  String get inheritedHandDialogTitle;

  /// Message de la popup de main héritée : score déjà acquis sur cette main, suivi du nombre de dés hérités.
  ///
  /// In fr, this message translates to:
  /// **'{score}, {count, plural, one{{count} dé} other{{count} dés}}'**
  String inheritedHandDialogMessage(int score, int count);

  /// Infobulle de l'icône "valider" de la popup de main héritée, qui reprend la main du joueur précédent.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la main'**
  String get resumeHandButton;

  /// Infobulle de l'icône "refuser" de la popup de main héritée, qui repart avec 5 dés neufs.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle main'**
  String get newHandButton;

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

  /// Réglage choisissant de quel côté se placent les commandes Stop et échange des 5, autour du bouton Lancer.
  ///
  /// In fr, this message translates to:
  /// **'Disposition des boutons'**
  String get settingsHandednessLabel;

  /// Disposition pour droitier : échange des 5 à gauche, Stop à droite.
  ///
  /// In fr, this message translates to:
  /// **'Droitier'**
  String get settingsHandednessRight;

  /// Disposition pour gaucher : Stop à gauche, échange des 5 à droite.
  ///
  /// In fr, this message translates to:
  /// **'Gaucher'**
  String get settingsHandednessLeft;

  /// Titre de la section réglages consacrée aux contrôles de jeu (au-delà des boutons à l'écran).
  ///
  /// In fr, this message translates to:
  /// **'Contrôles'**
  String get settingsControlsTitle;

  /// Interrupteur activant/désactivant le lancer de dés en secouant le téléphone, en plus du bouton Lancer.
  ///
  /// In fr, this message translates to:
  /// **'Secouer pour lancer les dés'**
  String get settingsShakeToRollLabel;

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
