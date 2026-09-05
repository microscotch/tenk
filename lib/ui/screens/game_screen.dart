import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../game/combination.dart';
import '../../game/game_engine.dart';
import '../../game/game_recording.dart';
import '../../game/player.dart';
import '../../game/turn_result.dart';
import '../../game/turn_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/replay_speed_provider.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import '../navigation.dart';
import '../shake_detector.dart';
import '../sound_effects.dart';
import '../widgets/app_title.dart';
import '../widgets/bordered_section.dart';
import '../widgets/die_widget.dart';
import '../widgets/player_avatar.dart';
import '../widgets/replay_speed_control.dart';
import '../widgets/score_sheet.dart';
import 'game_over_screen.dart';
import 'pass_device_screen.dart';
import 'score_grid_screen.dart';

/// Détermine l'état visuel de chaque dé d'un lancer, en tenant compte du
/// nombre de 5 que le joueur envisage de garder (aperçu avant validation).
List<DieVisualState> _classifyDiceForDisplay(
  RollAnalysis analysis,
  int selectedKeepCount,
) {
  if (analysis.groups.any((g) => g.isSuite)) {
    return List.filled(analysis.faces.length, DieVisualState.kept);
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] =
        (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }

  final fives = analysis.declinableFives;
  var keepRemaining = selectedKeepCount;

  return [
    for (final v in analysis.faces)
      if ((mandatoryRemaining[v] ?? 0) > 0)
        _consume(mandatoryRemaining, v, _mandatoryVisualState(analysis, v))
      else if (fives != null && v == 5)
        (() {
          if (keepRemaining > 0) {
            keepRemaining--;
            final perDie = fives.points ~/ fives.diceCount;
            return perDie == 100
                ? DieVisualState.extended
                : DieVisualState.kept;
          }
          return DieVisualState.declined;
        })()
      else
        DieVisualState.junk,
  ];
}

DieVisualState _mandatoryVisualState(RollAnalysis analysis, int value) {
  final g = analysis.mandatoryGroups.firstWhere((g) => g.value == value);
  // Un groupe obligatoire isolé (moins de 3 dés) de valeur non-as ne peut
  // exister que via la règle d'extension : ses points sont "temporaires".
  final isExtended = g.diceCount < 3 && g.value != 1;
  return isExtended ? DieVisualState.extended : DieVisualState.kept;
}

DieVisualState _consume(
  Map<int, int> remaining,
  int value,
  DieVisualState result,
) {
  remaining[value] = remaining[value]! - 1;
  return result;
}

/// Vrai s'il existe un choix réel sur le nombre de 5 à garder (plusieurs
/// valeurs possibles), pas juste une case techniquement "déclinable" dont la
/// seule valeur légale serait de tout garder.
/// Vrai s'il reste un vrai choix à faire sur les 5 : au moins deux nombres
/// de 5 gardables sont légaux, une fois retirés ceux qui feraient dépasser
/// 10000 (voir [maxKeepableFives]).
bool _hasRealChoice(TurnState turn, RollAnalysis analysis, {required int currentTotal}) {
  final fives = analysis.declinableFives;
  if (fives == null || !analysis.canDeclineFives) return false;
  return maxKeepableFives(turn, analysis, currentTotal: currentTotal) > minKeepableFives(analysis);
}

/// Détermine, parmi les choix légaux de nombre de 5 à garder, le meilleur
/// par défaut : le score de tour résultant le plus élevé, en évitant si
/// possible qu'il ne finisse par 50 (score sur lequel il est interdit de
/// s'arrêter volontairement) — le joueur reste libre d'ajuster ensuite via
/// les ChoiceChip (certains préfèrent délibérément garder moins de 5).
/// Repli sur le score le plus élevé si toutes les options finissent par 50
/// (possible seulement via la règle d'extension, où chaque 5 vaut 100 : le
/// dernier chiffre ne varie alors jamais avec le nombre gardé).
int _defaultKeepCount(TurnState turn, RollAnalysis analysis, {required int currentTotal}) {
  final fives = analysis.declinableFives;
  if (fives == null) return 0;
  // Borne haute légale plutôt que "tous les 5" : garder au-delà ferait
  // dépasser 10000, ce qui n'est jamais proposé au joueur.
  final maxKeep = maxKeepableFives(turn, analysis, currentTotal: currentTotal);
  // Décliner un 5 n'est physiquement possible que s'il reste un dé "junk"
  // pour l'accompagner au relancer (voir RollAnalysis.canDeclineFives) :
  // sans ça, tout garder est la SEULE option légale, quel que soit le score
  // résultant (même s'il finit par 50) — tenter quand même un
  // declineFivesCount > 0 ferait planter applyKeepDecision plus bas (bug
  // vécu en jeu réel : un lancer de deux 5 sans aucun autre dé, où garder
  // les deux finissait sur un total en 50, faisait planter cette recherche
  // de repli en tentant d'en décliner un).
  if (!analysis.canDeclineFives) return maxKeep;
  final minKeep = minKeepableFives(analysis);
  for (var keep = maxKeep; keep >= minKeep; keep--) {
    final hypothetical = applyKeepDecision(
      turn,
      declineFivesCount: maxKeep - keep,
    );
    if (hypothetical.bankedScore % 100 != 50) return keep;
  }
  return maxKeep;
}

/// Points que rapporterait ce lancer si le joueur valide sa sélection
/// actuelle (combien de 5 garder).
int _previewPoints(RollAnalysis analysis, int selectedKeepCount) {
  var points = analysis.mandatoryGroups.fold<int>(
    0,
    (sum, g) => sum + g.points,
  );
  final fives = analysis.declinableFives;
  if (fives != null) {
    final perDie = fives.points ~/ fives.diceCount;
    points += selectedKeepCount * perDie;
  }
  return points;
}

/// Libellé "icône dé + pourcentage" (ex. "76 %") pour un bouton "Lancer" :
/// remplace le nombre de dés ou un texte fixe par la probabilité réelle de
/// marquer au moins un point sur ce lancer, cf. [scoreProbabilityFraction].
String _scorePercentLabel(int diceCount, Set<int> extendedValues) {
  final (num, den) = scoreProbabilityFraction(diceCount, extendedValues);
  final p = den == 0 ? 0.0 : num / den;
  return '${(p * 100).round()} %';
}

/// Bouton "Lancer" (icône dé + libellé), partagé entre la ligne de contrôle
/// humaine et le choix de main héritée.
/// [onPressed] null laisse le bouton visible mais inerte : c'est ainsi qu'un
/// tour IA montre un lancer possible qu'elle ne prend pas (elle s'arrête),
/// sans que la ligne de contrôle change de forme pour autant.
Widget _rollButton({required VoidCallback? onPressed, required String label}) {
  return FilledButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.casino, size: 18),
        const SizedBox(width: 8),
        // Flexible + ellipsis : ce bouton est parfois contraint à une
        // largeur fixe (voir _controlButtonWidth dans game_screen.dart), qui
        // doit rester identique que le libellé soit un court pourcentage ou
        // "Main pleine !" — un Text nu débordant plutôt que de rétrécir.
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, softWrap: false),
        ),
      ],
    ),
  );
}

/// Décrit en français un groupe scorant pour le journal de partie (ex.
/// "brelan de 3", "2 as", "suite"). Les 1 et 5 isolés se nomment "as"/"cinq" ;
/// un groupe isolé d'une autre valeur (2/3/4/6) ne peut exister que via la
/// règle d'extension — rare, décrit par sa valeur brute en repli.
String _describeGroup(ScoringGroup g) {
  if (g.isSuite) return 'suite';
  if (g.diceCount >= 3) {
    final name = switch (g.diceCount) {
      3 => 'brelan',
      4 => 'carré',
      _ => 'quinte',
    };
    return g.value == 1 ? "$name d'as" : '$name de ${g.value}';
  }
  final noun = switch (g.value) {
    1 => 'as',
    5 => 'cinq',
    _ => '${g.value}',
  };
  return '${g.diceCount} $noun';
}

/// Reconstruit l'énumération des dés effectivement gardés sur un lancer
/// résolu (ex. "2 as et brelan de 3") à partir de son analyse et des points
/// marqués — sans rejouer la décision de garde : le nombre de 5 gardés se
/// déduit par arithmétique (roundPoints moins les groupes obligatoires,
/// divisé par la valeur d'un 5), pas besoin de connaître
/// `declineFivesCount`. Fonctionne donc identiquement pour un humain, une
/// IA, et le mode rejeu.
String _describeKeptDice(RollAnalysis analysis, int roundPoints) {
  final parts = [for (final g in analysis.mandatoryGroups) _describeGroup(g)];
  final fives = analysis.declinableFives;
  if (fives != null) {
    final mandatoryPoints = analysis.mandatoryGroups.fold<int>(
      0,
      (sum, g) => sum + g.points,
    );
    final perDie = fives.points ~/ fives.diceCount;
    final keptFives = (roundPoints - mandatoryPoints) ~/ perDie;
    if (keptFives > 0) {
      parts.add(
        _describeGroup(
          ScoringGroup(
            value: 5,
            diceCount: keptFives,
            points: keptFives * perDie,
          ),
        ),
      );
    }
  }
  return parts.join(' et ');
}

/// Une entrée horodatée du journal de partie (voir [_GameScreenState._log]),
/// rattachée au joueur concerné (pour son blason, voir [PlayerAvatarWidget]).
///
/// [barredScore] n'est renseigné que pour les entrées qui barrent une ligne
/// de grille — collision de score, ou craque qui barre la ligne courante :
/// ce score s'affiche alors biffé au milieu du message (voir
/// [_GameScreenState._buildLogWhatCell]), encadré par [text] devant et, selon
/// le cas, le blason du joueur barré ([barredPlayerName]) ou le repli de
/// score ([textAfterBarredScore]) derrière.
class _LogEntry {
  final DateTime timestamp;
  final String playerName;
  final String text;
  final int? barredScore;
  final String? barredPlayerName;
  final String? textAfterBarredScore;

  const _LogEntry(this.timestamp, this.playerName, this.text)
    : barredScore = null,
      barredPlayerName = null,
      textAfterBarredScore = null;

  const _LogEntry.scoreBarred(
    this.timestamp,
    this.playerName,
    this.text,
    this.barredPlayerName,
    this.barredScore,
  ) : textAfterBarredScore = null;

  const _LogEntry.bustBarred(
    this.timestamp,
    this.playerName,
    this.text,
    this.barredScore,
    this.textAfterBarredScore,
  ) : barredPlayerName = null;
}

/// Résumé d'un lancer résolu tel qu'affiché dans le journal, à partir de son
/// analyse et de l'état de tour obtenu APRÈS la décision de garde. Partagé
/// entre les deux moments où ce résumé peut être produit (voir
/// [_GameScreenState._maybeLogGainEarly] et [_logEntriesForStep]) : il doit
/// être écrit exactement pareil dans les deux cas.
String _describeRollGain(
  AppLocalizations l10n,
  RollAnalysis analysis, {
  required int bankedScoreBefore,
  required TurnState afterKeep,
}) {
  final roundPoints = afterKeep.bankedScore - bankedScoreBefore;
  final kept = _describeKeptDice(analysis, roundPoints);
  return afterKeep.mustContinue
      ? l10n.logRollGainHotDiceMessage(kept, roundPoints, afterKeep.bankedScore)
      : l10n.logRollGainMessage(
          kept,
          roundPoints,
          afterKeep.diceToRoll,
          afterKeep.bankedScore,
        );
}

/// Entrées de journal annonçant un craque et sa conséquence réelle sur la
/// grille : un petit trait sur la ligne courante, son barrage avec repli sur
/// le score précédent, ou rien du tout à 0 (rien à sanctionner sous le
/// plancher). [Player.applyBust] étant pure, cette conséquence se calcule
/// d'avance, avant même que le moteur ne l'applique — ce qu'il ne fait qu'une
/// fois le craque acquitté (voir [GameEngine.endBustedTurn]), bien après que
/// le message doive s'afficher.
List<_LogEntry> _bustLogEntries(
  GameEngine engine,
  TurnState turn, {
  required AppLocalizations l10n,
  required DateTime at,
}) {
  final before = engine.currentPlayer;
  final after = before.applyBust();
  final entries = <_LogEntry>[
    if (identical(after, before))
      _LogEntry(at, before.name, l10n.bustedTitle)
    else if (after.hasTiret && !before.hasTiret)
      _LogEntry(at, before.name, l10n.logBustTiretMessage(before.totalScore))
    else
      _LogEntry.bustBarred(
        at,
        before.name,
        l10n.logBustBarredPrefix,
        before.totalScore,
        l10n.logBustBarredReturnMessage(after.totalScore),
      ),
  ];
  final explanation = _bustReasonExplanation(l10n, turn.bustReason);
  if (explanation != null) {
    entries.add(_LogEntry(at, before.name, explanation));
  }
  return entries;
}

/// Phrase expliquant pourquoi le tour a craqué, quand la cause n'est pas le
/// craque ordinaire (aucun dé marquant) qui se passe de commentaire.
String? _bustReasonExplanation(AppLocalizations l10n, BustReason? reason) {
  return switch (reason) {
    BustReason.exceedsTarget => l10n.bustExceedsTarget,
    BustReason.fullHandAtTarget => l10n.bustFullHandAtTarget,
    BustReason.noScore || null => null,
  };
}

String _formatLogTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

/// Dérive 0 à N entrées de journal pour la transition [previous] -> [next]
/// (un pas de la partie principale, humain, IA ou rejoué) : pure fonction
/// d'état, sans dépendance à comment cette transition a été obtenue — utilisée
/// aussi bien pour le suivi en direct (voir `ref.listen` dans `build()`) que
/// pour reconstruire tout l'historique d'une partie reprise (voir
/// `_seedLogFromHistory`, qui rejoue `GameNotifier.actions` depuis zéro).
///
/// [includeBust] contrôle si un craque fraîchement détecté génère lui-même
/// son entrée ici : en direct, le craque est plutôt logué au moment de sa
/// révélation visuelle (voir `_scheduleBustRevealIfNeeded`), pour rester
/// synchrone avec le suspense déjà à l'écran — mais lors d'une reconstruction
/// d'historique, il n'y a pas d'animation à attendre, donc `true`.
///
/// [includeGain] joue le même rôle pour le résumé du lancer : quand le joueur
/// n'avait aucune décision à prendre dessus, il a déjà été ajouté au journal
/// dès l'immobilisation des dés (voir
/// `_GameScreenState._maybeLogGainEarly`), bien avant la transition qui
/// applique enfin la garde — il ne faut alors pas l'ajouter une seconde fois.
List<_LogEntry> _logEntriesForStep(
  GameEngine? previous,
  GameEngine next, {
  required AppLocalizations l10n,
  required DateTime at,
  required bool includeBust,
  required bool includeGain,
}) {
  final entries = <_LogEntry>[];

  // Prise de mise (bank() réussi) : GameEngine.activeTurn ne devient jamais
  // null en dehors de bank()/endBustedTurn() (les deux seuls appelants de
  // _advance(..., clearActiveTurn: true)) — et `!prevActiveTurn.busted`
  // exclut le second (endBustedTurn() exige toujours un tour déjà craqué en
  // entrée). Un tour sain qui se termine ainsi ne peut donc être qu'une mise
  // prise avec succès. Détecté avant la collision de score ci-dessous, pour
  // que le message apparaisse en premier dans le journal (la collision en
  // est une conséquence directe).
  final prevActiveTurn = previous?.activeTurn;
  if (prevActiveTurn != null && !prevActiveTurn.busted && next.activeTurn == null) {
    entries.add(
      _LogEntry(
        at,
        previous!.currentPlayer.name,
        l10n.logBankedMessage(
          prevActiveTurn.bankedScore,
          // Grille déjà à jour dans `next` : le joueur qui vient de banquer
          // reste à son index (une fin de partie ne fait pas tourner la
          // main, voir GameEngine._advance).
          next.players[previous.currentPlayerIndex].totalScore,
        ),
      ),
    );
  }

  // Collision de score (voir GameEngine.bank()) : un autre joueur que celui
  // qui vient de banquer se retrouve barré si son score égalait exactement
  // le nouveau total. bank() ne fait rien d'autre à la grille des AUTRES
  // joueurs (aucune ligne ajoutée/retirée) : une ligne qui passe de
  // non-barrée à barrée au même indice ne peut être que cette collision.
  // Indépendant de l'état du tour suivant (nextTurn), donc détecté avant le
  // guard ci-dessous.
  if (previous != null) {
    for (var i = 0; i < next.players.length; i++) {
      final prevGrid = previous.players[i].grid;
      final nextGrid = next.players[i].grid;
      for (var idx = 0; idx < prevGrid.length && idx < nextGrid.length; idx++) {
        if (!prevGrid[idx].isBarred && nextGrid[idx].isBarred) {
          entries.add(
            _LogEntry.scoreBarred(
              at,
              previous.currentPlayer.name,
              l10n.logScoreCollisionMessage,
              next.players[i].name,
              nextGrid[idx].value,
            ),
          );
        }
      }
    }
  }

  final nextTurn = next.activeTurn;
  if (nextTurn == null) return entries;
  final prevTurn = previous?.activeTurn;
  final playerName = next.currentPlayer.name;

  // Reprise de la main laissée par le joueur précédent : un tour qui démarre
  // avec un score déjà acquis ne peut venir que de là (voir
  // GameEngine.startTurn, où une main neuve part toujours de zéro, et bank(),
  // seule à transmettre un inheritedScore — toujours non nul, puisqu'il faut
  // au moins 200 pour banquer).
  if (previous != null && prevTurn == null && nextTurn.bankedScore > 0) {
    entries.add(
      _LogEntry(at, playerName, l10n.logResumedHandMessage(nextTurn.bankedScore)),
    );
  }

  // Une décision de garde vient d'être appliquée sur le lancer précédent
  // (`prevTurn!.busted` exclut un `prevTurn` qui serait un craque déjà
  // révolu dont le `pendingRoll` traînerait encore — jamais un vrai choix).
  // Une seule entrée résume tout le lancer : dés gardés, points marqués, ce
  // qu'il reste à relancer (ou "main pleine"), et le total de la main — pas
  // d'entrée séparée pour le nombre de dés à lancer ni pour la main pleine,
  // qui feraient double emploi avec celle-ci.
  if (includeGain &&
      prevTurn?.pendingRoll != null &&
      !prevTurn!.busted &&
      nextTurn.pendingRoll == null &&
      !nextTurn.busted) {
    entries.add(
      _LogEntry(
        at,
        playerName,
        _describeRollGain(
          l10n,
          prevTurn.pendingRoll!,
          bankedScoreBefore: prevTurn.bankedScore,
          afterKeep: nextTurn,
        ),
      ),
    );
  }

  if (includeBust && nextTurn.busted && !(prevTurn?.busted ?? false)) {
    entries.addAll(_bustLogEntries(next, nextTurn, l10n: l10n, at: at));
  }

  return entries;
}

/// [replayMode] : rejeu spectateur d'un run archivé (voir
/// `GameNotifier.startGameReplay`) — écran entièrement inerte
/// (`AbsorbPointer`), avance seul (vitesse x1/x2/x4, [ReplaySpeedControl])
/// au lieu d'attendre une décision IA/humaine, jusqu'à l'écran de victoire.
class GameScreen extends ConsumerStatefulWidget {
  final bool replayMode;

  const GameScreen({super.key, this.replayMode = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  /// Combien de 5 déclinables le joueur choisit de garder (par défaut, tous).
  int _selectedKeep = 0;

  Timer? _pendingTimer;
  VoidCallback? _pendingAction;

  /// Les scores affichés dans les libellés (zone "Piste" et zone "Main
  /// courante") ne doivent se rafraîchir qu'une fois les dés du lancer en
  /// attente immobilisés (fin de l'animation de lancer, voir
  /// [DieWidget.rollAnimationDuration]), pas dès que le lancer est connu côté
  /// moteur — sinon le score apparaît avant que le joueur ait vu le résultat.
  /// `true` par défaut : un lancer déjà en attente au montage de l'écran
  /// (partie reprise) n'a pas d'animation à attendre.
  bool _rollSettled = true;
  Timer? _rollSettleTimer;

  /// Une fois le lancer immobilisé, encore un délai avant que les dés
  /// retenus par défaut (groupes obligatoires + nombre de 5 par défaut, voir
  /// [_defaultKeepCount]) ne migrent en fondu de la zone "Piste" vers la zone
  /// "Main courante" — purement visuel : la décision réelle n'est appliquée
  /// qu'au clic sur Lancer/Arrêter, comme avant. `true` par défaut, même
  /// raison que [_rollSettled].
  bool _previewMoveRevealed = true;
  Timer? _previewMoveTimer;

  /// Journal de partie : horodaté, affiché du plus récent au plus ancien
  /// (voir [_buildGameLog]). Rempli au montage par rejeu de l'historique déjà
  /// persisté (voir [_seedLogFromHistory]), puis tenu à jour en direct par
  /// comparaison d'état (voir [_logEntriesForStep], appelée depuis
  /// `ref.listen` dans `build()`) — état local à l'écran, jamais écrit dans
  /// [GameNotifier] : dérivé du même journal d'actions que celui déjà
  /// persisté dans le `.run`, pas dupliqué.
  final List<_LogEntry> _log = [];
  final ScrollController _logScrollController = ScrollController();

  /// Le message "Craqué !" ne doit apparaître qu'une fois que l'animation de
  /// lancer des dés est terminée (résultat visible), pas dès que le craque
  /// est connu côté moteur : sinon le suspense du lancer est gâché.
  static const _bustRevealDelay = Duration(milliseconds: 700);
  Object? _bustKeyBeingRevealed;
  bool _bustRevealed = false;
  Timer? _bustRevealTimer;

  /// Dernier [GameEngine] pour lequel la popup de main héritée a déjà été
  /// ouverte (voir [_maybeShowInheritedHandDialog]) : évite de la rouvrir à
  /// chaque rebuild tant que le joueur n'a pas encore décidé.
  Object? _inheritedHandDialogShownFor;

  /// Lancer dont le résumé a déjà été ajouté au journal dès l'immobilisation
  /// des dés (voir [_maybeLogGainEarly]) : la transition qui appliquera
  /// vraiment la décision de garde ne doit alors plus le rajouter.
  RollAnalysis? _gainLoggedForRoll;

  /// Déclencheur "secouer pour lancer" (réglage [AppSettings.shakeToRollEnabled]) :
  /// une seule instance pour toute la durée de l'écran, démarrée/arrêtée
  /// selon le réglage et le cycle de vie de l'app (voir [initState],
  /// `ref.listen` dans [build] et [didChangeAppLifecycleState]), jamais en
  /// mode rejeu (écran spectateur inerte).
  late final ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeDetector = ShakeDetector(onShake: _handleShake);
    if (!widget.replayMode && ref.read(settingsProvider).shakeToRollEnabled) {
      _shakeDetector.start();
    }
    final initialEngine = ref.read(gameProvider);
    final initialTurn = initialEngine?.activeTurn;
    final initialPendingRoll = initialTurn?.pendingRoll;
    _selectedKeep = initialPendingRoll != null
        ? _defaultKeepCount(
            initialTurn!,
            initialPendingRoll,
            currentTotal: initialEngine!.currentPlayer.totalScore,
          )
        : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedLogFromHistory();
      // Partie reprise sur un lancer déjà affiché (donc déjà immobilisé, cf.
      // _rollSettled) : son résumé doit suivre la même règle que si les dés
      // venaient de s'arrêter sous les yeux du joueur.
      if (initialPendingRoll != null) _maybeLogGainEarly(initialPendingRoll);
      _scheduleAutoProgressIfNeeded();
      _scheduleBustRevealIfNeeded(initialEngine);
    });
  }

  /// (Re)programme l'avancement automatique du tour — IA, ou humain en mode
  /// auto — après un changement d'état, ou après un retour au premier plan
  /// (voir [didChangeAppLifecycleState]). Un seul point d'entrée pour ne pas
  /// dupliquer le dispatch rejeu/IA/humain entre `initState` et le retour de
  /// premier plan.
  void _scheduleAutoProgressIfNeeded() {
    if (widget.replayMode) {
      _scheduleReplayStep();
    } else {
      _scheduleAiIfNeeded();
      _scheduleAutoAdvanceIfNeeded();
    }
  }

  /// Le jeu ne doit pas continuer à avancer seul (IA, auto-jeu — et donc les
  /// sons qui vont avec) pendant que l'app est en arrière-plan (bouton
  /// d'accueil, autre app au premier plan...) : coupe la temporisation en
  /// cours dès que l'app quitte l'état "resumed", la reprogramme à son
  /// retour. La musique/les effets sonores se coupent séparément (voir
  /// `SoundEffects`, qui observe le cycle de vie indépendamment de cet
  /// écran).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleAutoProgressIfNeeded();
      if (!widget.replayMode && ref.read(settingsProvider).shakeToRollEnabled) {
        _shakeDetector.start();
      }
    } else {
      _cancelAutoAction();
      _shakeDetector.stop();
    }
  }

  /// Programme puis applique le pas suivant du rejeu spectateur (partie
  /// principale), et se reprogramme lui-même jusqu'à épuisement du journal
  /// (l'écran de victoire se déclenche alors normalement via le `ref.listen`
  /// existant dès que `gameOver` devient vrai). Délai = `aiMessageDelay`
  /// (réglages) divisé par [replaySpeedProvider] (x1/x2/x4).
  void _scheduleReplayStep() {
    final notifier = ref.read(gameProvider.notifier);
    final engine = ref.read(gameProvider);
    if (engine == null || engine.gameOver || !notifier.hasNextReplayAction) {
      return;
    }
    final baseDelay = ref.read(settingsProvider).aiMessageDelay;
    final speed = ref.read(replaySpeedProvider);
    final delay = Duration(microseconds: baseDelay.inMicroseconds ~/ speed);
    _pendingTimer?.cancel();
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(gameProvider.notifier).applyNextReplayAction();
      _scheduleReplayStep();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector.stop();
    _pendingTimer?.cancel();
    _bustRevealTimer?.cancel();
    _rollSettleTimer?.cancel();
    _previewMoveTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  /// Ajoute une entrée au journal (le plus récent apparaît en premier, voir
  /// [_buildGameLog] — pas d'auto-scroll nécessaire, une nouvelle entrée
  /// apparaît directement en haut, déjà visible).
  void _appendLog(_LogEntry entry) => setState(() => _log.add(entry));

  /// Reconstruit tout l'historique du journal en rejouant le journal
  /// d'actions déjà persisté par [GameNotifier] (même source que le `.run` —
  /// rien n'est dupliqué), au montage de l'écran : couvre aussi bien une
  /// partie qui vient de démarrer (un seul `startTurn` à rejouer) qu'une
  /// partie reprise (tout son historique). Sans effet si la partie n'est pas
  /// persistée (`debugLoadState` en test, ou mode rejeu — ce dernier peuple
  /// son propre journal en direct au fil de la lecture, voir `ref.listen`).
  void _seedLogFromHistory() {
    final notifier = ref.read(gameProvider.notifier);
    final seed = notifier.seed;
    final originalSetup = notifier.originalSetup;
    final actions = notifier.actions;
    if (seed == null || originalSetup == null || actions.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final entries = <_LogEntry>[];
    replayGame(
      originalSetup,
      seed,
      actions,
      onGameAction: (previous, next, action) {
        entries.addAll(
          _logEntriesForStep(
            previous,
            next,
            l10n: l10n,
            at: action.at,
            includeBust: true,
            includeGain: true,
          ),
        );
      },
    );
    if (entries.isEmpty) return;
    setState(() => _log.addAll(entries));
  }

  /// Programme, pour un [pendingRoll] fraîchement apparu (null = décision
  /// déjà appliquée, rien à programmer), la révélation du score dans les
  /// libellés une fois les dés immobilisés, puis — encore un peu plus tard —
  /// le fondu des dés retenus par défaut vers la zone "Main courante" (voir
  /// [_rollSettled]/[_previewMoveRevealed]). Appelé uniquement quand le
  /// lancer en attente change réellement (voir `ref.listen`).
  void _scheduleRollSettleAndPreviewMove(RollAnalysis? pendingRoll) {
    _rollSettleTimer?.cancel();
    _previewMoveTimer?.cancel();
    if (pendingRoll == null) {
      _rollSettled = true;
      _previewMoveRevealed = true;
      return;
    }
    _rollSettled = false;
    _previewMoveRevealed = false;
    _rollSettleTimer = Timer(DieWidget.rollAnimationDuration, () {
      if (!mounted) return;
      setState(() => _rollSettled = true);
      _maybeLogGainEarly(pendingRoll);
      _previewMoveTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        // Le lancer a peut-être déjà été décidé (ou remplacé) entre-temps :
        // rien à révéler dans ce cas, la zone "Piste" ne l'affiche plus.
        if (ref.read(gameProvider)?.activeTurn?.pendingRoll != pendingRoll) {
          return;
        }
        setState(() => _previewMoveRevealed = true);
      });
    });
  }

  /// Ajoute le résumé du lancer au journal dès que les dés sont immobilisés,
  /// mais seulement quand le joueur n'a AUCUNE décision à prendre dessus :
  /// aucun choix de 5 à garder, et s'arrêter est de toute façon illégal, donc
  /// relancer est le seul geste possible. Le résumé est alors entièrement
  /// déterminé au moment où le résultat s'affiche : attendre le clic (ou le
  /// délai du mode auto) ne ferait que le retarder sans rien apprendre de
  /// plus. Dans le cas contraire, il reste ajouté au moment de l'action, une
  /// fois le choix tranché (voir [_logEntriesForStep]).
  void _maybeLogGainEarly(RollAnalysis pendingRoll) {
    final engine = ref.read(gameProvider);
    final turn = engine?.activeTurn;
    // Le lancer a pu être décidé (ou remplacé) pendant l'animation : son
    // résumé passe alors par le chemin normal, avec l'état réellement obtenu.
    if (engine == null || turn == null || turn.busted) return;
    if (!identical(turn.pendingRoll, pendingRoll)) return;

    final currentTotal = engine.currentPlayer.totalScore;
    if (_hasRealChoice(turn, pendingRoll, currentTotal: currentTotal)) return;
    final afterKeep = applyKeepDecision(turn, declineFivesCount: 0);
    final attempt = tryBank(
      afterKeep,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: currentTotal,
    );
    if (attempt.success) return; // s'arrêter reste un choix ouvert

    _gainLoggedForRoll = pendingRoll;
    _appendLog(
      _LogEntry(
        DateTime.now(),
        engine.currentPlayer.name,
        _describeRollGain(
          AppLocalizations.of(context),
          pendingRoll,
          bankedScoreBefore: turn.bankedScore,
          afterKeep: afterKeep,
        ),
      ),
    );
  }

  /// Programme la révélation du message "Craqué !" une fois l'animation de
  /// lancer des dés terminée pour ce lancer précis. Cas particulier : un
  /// craque par dépassement de 10000 (déclenché dans [GameEngine.applyKeep]
  /// après une décision de garde déjà appliquée) n'a plus de lancer en
  /// attente à animer — rien à cacher, la révélation est immédiate.
  void _scheduleBustRevealIfNeeded(GameEngine? engine) {
    final turn = engine?.activeTurn;
    if (turn == null || !turn.busted) return;

    // Clé d'identité du craque en cours : le lancer en attente s'il y en a
    // un, sinon l'état de tour lui-même (craque par dépassement de 10000,
    // déclenché dans [GameEngine.applyKeep] après une décision de garde déjà
    // appliquée — pas de lancer à animer, donc rien à cacher).
    final key = turn.pendingRoll ?? turn;
    if (_bustKeyBeingRevealed == key) return;
    _bustKeyBeingRevealed = key;
    _bustRevealed = false;
    _bustRevealTimer?.cancel();

    if (turn.pendingRoll == null) {
      SoundEffects.instance.playBust();
      _logBust(engine!, turn);
      setState(() => _bustRevealed = true);
      _showBustDialog(engine, turn);
      return;
    }

    _bustRevealTimer = Timer(_bustRevealDelay, () {
      if (!mounted) return;
      SoundEffects.instance.playBust();
      _logBust(engine!, turn);
      setState(() => _bustRevealed = true);
      _showBustDialog(engine, turn);
    });
  }

  /// Popup dédiée annonçant le craque au joueur humain, avec pour seule
  /// action de reconnaître et passer la main (voir [GameEngine.endBustedTurn]).
  /// Sans effet en mode rejeu (spectateur, jamais d'interaction) ni pour un
  /// tour IA (déjà géré tout seul par [GameNotifier.playAiTurnStep], sans
  /// attendre de clic) : dans ces deux cas, [_buildBustedView] garde
  /// l'ancien bouton en ligne, purement informatif.
  void _showBustDialog(GameEngine engine, TurnState turn) {
    if (!mounted || widget.replayMode) return;
    if (ref.read(gameProvider.notifier).isAiPlayer(engine.currentPlayerIndex)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bustedTitle),
        content: switch (_bustReasonExplanation(l10n, turn.bustReason)) {
          final explanation? => Text(explanation),
          null => null,
        },
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(gameProvider.notifier).endBustedTurn();
            },
            child: Text(l10n.bustContinueButton),
          ),
        ],
      ),
    );
  }

  /// Journalise un craque : le titre "Craqué !" toujours, suivi du détail
  /// "dépasserait 10000" quand c'est la cause précise (voir [BustReason]) —
  /// remplace l'ancien bandeau orange au-dessus des boutons (voir
  /// [_buildBustedView]), dont la présence changeait la forme de l'écran
  /// selon la raison du craque.
  void _logBust(GameEngine engine, TurnState turn) {
    for (final entry in _bustLogEntries(
      engine,
      turn,
      l10n: AppLocalizations.of(context),
      at: DateTime.now(),
    )) {
      _appendLog(entry);
    }
  }

  /// Programme [action] pour s'exécuter seule après [delay] (réglable dans
  /// les préférences ; 0 = quasi immédiat), sauf si l'utilisateur clique
  /// entre-temps n'importe où sur l'écran (voir [_skipPendingAction]),
  /// auquel cas elle s'exécute immédiatement.
  void _scheduleAutoAction(VoidCallback action, Duration delay) {
    _pendingTimer?.cancel();
    _pendingAction = action;
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      _pendingAction = null;
      action();
    });
  }

  void _cancelAutoAction() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
  }

  /// Exécute immédiatement l'action automatique en attente, si il y en a
  /// une : appelé quand l'utilisateur clique sur l'écran pour sauter le
  /// délai de temporisation.
  void _skipPendingAction() {
    final action = _pendingAction;
    if (action == null) return;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
    action();
  }

  /// Programme (ou annule) l'auto-validation d'[action] selon le mode auto
  /// du joueur [playerIndex] et le délai [delay] réglé dans les préférences :
  /// un bouton explicite reste toujours affiché et cliquable (voir les
  /// méthodes `_build*View`), mais ne se déclenche seul que si les deux
  /// conditions sont réunies (délai > 0 requis, sinon "désactivé").
  void _scheduleIfAuto(int playerIndex, VoidCallback action, Duration delay) {
    final notifier = ref.read(gameProvider.notifier);
    if (notifier.isAutoPlayer(playerIndex) && delay > Duration.zero) {
      _scheduleAutoAction(action, delay);
    } else {
      _cancelAutoAction();
    }
  }

  void _scheduleAiIfNeeded() {
    final engine = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (engine == null || engine.gameOver) return;
    if (!notifier.isAiPlayer(engine.currentPlayerIndex)) return;
    _scheduleIfAuto(
      engine.currentPlayerIndex,
      () => ref.read(gameProvider.notifier).playAiTurnStep(),
      ref.read(settingsProvider).aiMessageDelay,
    );
  }

  /// Programme l'auto-validation du tour d'un joueur humain (en mode auto)
  /// quand il n'y a aucune décision réelle à prendre : pas de choix possible
  /// sur les 5 à garder (on garde tout d'office), ou score insuffisant/50
  /// interdit/dés chauds obligeant de toute façon à relancer. Un bouton
  /// explicite est affiché dans tous les cas par les méthodes `_build*View`.
  void _scheduleAutoAdvanceIfNeeded() {
    final engine = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (engine == null || engine.gameOver) return;
    if (notifier.isAiPlayer(engine.currentPlayerIndex)) {
      return; // géré par _scheduleAiIfNeeded
    }
    final turn = engine.activeTurn;
    if (turn == null || turn.busted) {
      _cancelAutoAction();
      return;
    }

    if (turn.pendingRoll != null) {
      final analysis = turn.pendingRoll!;
      if (_hasRealChoice(turn, analysis, currentTotal: engine.currentPlayer.totalScore)) {
        _cancelAutoAction();
        return;
      }
      _scheduleIfAuto(engine.currentPlayerIndex, () {
        if (ref.read(gameProvider)?.activeTurn?.pendingRoll != analysis) return;
        ref.read(gameProvider.notifier).applyKeep(declineFivesCount: 0);
      }, ref.read(settingsProvider).autoActionDelay);
      return;
    }

    final attempt = tryBank(
      turn,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
    );
    if (attempt.success) {
      _cancelAutoAction();
      return;
    }
    _scheduleIfAuto(engine.currentPlayerIndex, () {
      final currentTurn = ref.read(gameProvider)?.activeTurn;
      if (currentTurn != turn) return;
      ref.read(gameProvider.notifier).roll();
    }, ref.read(settingsProvider).autoActionDelay);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(settingsProvider.select((s) => s.shakeToRollEnabled), (previous, enabled) {
      if (widget.replayMode) return;
      if (enabled) {
        _shakeDetector.start();
      } else {
        _shakeDetector.stop();
      }
    });
    ref.listen<GameEngine?>(gameProvider, (previous, next) {
      if (next == null) return;
      if (next.gameOver) {
        SoundEffects.instance.playVictory();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              players: next.players,
              winnerIndex: next.winnerIndex!,
            ),
          ),
        );
        return;
      }
      if (!widget.replayMode &&
          previous != null &&
          next.currentPlayerIndex != previous.currentPlayerIndex &&
          ref
              .read(gameProvider.notifier)
              .shouldShowPassDevice(next.currentPlayerIndex)) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) =>
                    PassDeviceScreen(nextPlayerName: next.currentPlayer.name),
              ),
            )
            .then((_) {
              _scheduleAiIfNeeded();
              _maybeShowInheritedHandDialog();
            });
      }
      // Le résumé de ce lancer a-t-il déjà été ajouté au journal dès
      // l'immobilisation des dés (voir _maybeLogGainEarly) ? Comparaison
      // d'identité : deux lancers successifs peuvent très bien tomber sur les
      // mêmes faces sans être le même lancer.
      final gainAlreadyLogged =
          _gainLoggedForRoll != null &&
          identical(previous?.activeTurn?.pendingRoll, _gainLoggedForRoll);
      for (final entry in _logEntriesForStep(
        previous,
        next,
        l10n: AppLocalizations.of(context),
        at: DateTime.now(),
        includeBust: false,
        includeGain: !gainAlreadyLogged,
      )) {
        _appendLog(entry);
      }
      if (gainAlreadyLogged) _gainLoggedForRoll = null;
      final newPendingRoll = next.activeTurn?.pendingRoll;
      if (previous?.activeTurn?.pendingRoll != newPendingRoll) {
        if (newPendingRoll != null) SoundEffects.instance.playDiceRoll();
        // Par défaut, on tend vers le score optimal (voir _defaultKeepCount).
        _selectedKeep = newPendingRoll != null
            ? _defaultKeepCount(
                next.activeTurn!,
                newPendingRoll,
                currentTotal: next.currentPlayer.totalScore,
              )
            : 0;
        _scheduleRollSettleAndPreviewMove(newPendingRoll);
      }
      // En mode rejeu, _scheduleReplayStep s'auto-reprogramme lui-même
      // (voir initState) : pas besoin de le redéclencher ici, et surtout pas
      // la logique de décision IA/auto normale, qui ne s'applique pas.
      if (!widget.replayMode) {
        _scheduleAiIfNeeded();
        _scheduleAutoAdvanceIfNeeded();
      }
      _scheduleBustRevealIfNeeded(next);
    });

    final engine = ref.watch(gameProvider);
    if (engine == null || engine.gameOver) {
      // Partie terminée : l'écran de fin de partie est poussé par le
      // ref.listen ci-dessus, activeTurn est déjà nettoyé côté moteur.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notifier = ref.read(gameProvider.notifier);
    final isAiTurn = notifier.isAiPlayer(engine.currentPlayerIndex);

    // Dés hérités d'un tour précédent, en attente du choix du joueur (les
    // garder ou repartir avec une main pleine) : pas encore de vrai
    // TurnState côté moteur. Un TurnState de substitution (jamais commité)
    // permet de réutiliser tel quel tout le reste de cet écran (zones
    // "Piste"/"Main courante", ScoreSheet) au lieu d'un écran séparé — seul
    // le widget de contrôle en bas change (voir plus bas).
    final isInheritedChoice = engine.activeTurn == null;
    if (isInheritedChoice && !isAiTurn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowInheritedHandDialog());
    }
    final turn =
        engine.activeTurn ??
        TurnState(
          diceToRoll: engine.nextTurnDice,
          bankedScore: engine.inheritedScore,
          extendedValues: engine.inheritedExtendedValues,
          keptDiceThisTurn: engine.inheritedKeptDice,
        );
    final l10n = AppLocalizations.of(context);

    // Score "live" : score du tour déjà banqué + aperçu de la sélection de 5
    // en cours si un choix humain est en attente ET que les dés du lancer se
    // sont immobilisés (voir _rollSettled) — pas avant, sinon le score
    // apparaît avant que le joueur ait vu le résultat du lancer.
    final showRollPreview =
        !isAiTurn && turn.pendingRoll != null && _rollSettled;
    final liveScore = showRollPreview
        ? turn.bankedScore + _previewPoints(turn.pendingRoll!, _selectedKeep)
        : turn.bankedScore;
    final minimum = engine.minimumForCurrentPlayer;
    final belowMinimum = liveScore < minimum;
    final scoreColor = belowMinimum
        ? Colors.redAccent
        : (liveScore % 100 == 50 ? Colors.orange : Colors.lightGreenAccent);
    final minimumColor = belowMinimum
        ? Colors.redAccent
        : Colors.lightGreenAccent;
    // Aperçu (ChoiceChip) seulement pertinent pour un lancer humain en
    // attente de décision ; sinon (IA, craque, idle) les dés du lancer, s'il
    // y en a un à afficher, sont montrés "tels quels" (rien n'est encore
    // décidé côté joueur).
    final rollZoneSelectedKeep =
        (!turn.busted && !isAiTurn && turn.pendingRoll != null)
        ? _selectedKeep
        : 0;

    // Dés à faire migrer en fondu de "Piste" vers "Main courante" une fois
    // _previewMoveRevealed : pour un choix humain interactif, suit
    // _selectedKeep EN DIRECT (se recalcule à chaque tap sur les boutons
    // radio, voir _buildHumanControlRow) ; pour l'IA ou un craque (aucune
    // sélection modifiable), reste sur le choix par défaut. Recalculé à
    // chaque build (pur), seule la temporisation de la révélation est un
    // vrai état (voir _scheduleRollSettleAndPreviewMove).
    final pendingAnalysis = turn.pendingRoll;
    var previewIndices = const <int>{};
    List<DieVisualState>? previewStates;
    if (pendingAnalysis != null) {
      final previewKeep = (!turn.busted && !isAiTurn)
          ? _selectedKeep
          : _defaultKeepCount(turn, pendingAnalysis, currentTotal: engine.currentPlayer.totalScore);
      previewStates = _classifyDiceForDisplay(pendingAnalysis, previewKeep);
      previewIndices = {
        for (var i = 0; i < previewStates.length; i++)
          if (previewStates[i] == DieVisualState.kept ||
              previewStates[i] == DieVisualState.extended)
            i,
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(),
        actions: _scoreGridAction(engine.players),
      ),
      body: AbsorbPointer(
        absorbing: widget.replayMode,
        child: GestureDetector(
          onTap: _skipPendingAction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              // Le contenu (liste des joueurs + score + 2 zones bordurées +
              // boutons + journal) peut dépasser la hauteur disponible sur un
              // petit écran (ou un choix de 5 avec beaucoup de ChoiceChip) :
              // tout défile ensemble, le journal gardant une hauteur fixe
              // plutôt que de se répartir l'espace restant, pour qu'il reste
              // toujours visible sans avoir à tout faire défiler.
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScoreSheet(
                      players: engine.players,
                      currentPlayerIndex: engine.currentPlayerIndex,
                      onTapPlayer: _openPlayerGrid,
                    ),
                    const SizedBox(height: 12),
                    if (engine.isInFinalRound)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.finalRoundBanner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    _buildRollZone(
                      turn,
                      rollZoneSelectedKeep,
                      showScore: pendingAnalysis != null && _rollSettled,
                      previewIndices: previewIndices,
                      previewRevealed: _previewMoveRevealed,
                    ),
                    const SizedBox(height: 12),
                    _buildHandZone(
                      turn,
                      liveScore: liveScore,
                      minimum: minimum,
                      scoreColor: scoreColor,
                      minimumColor: minimumColor,
                      pendingAnalysis: pendingAnalysis,
                      previewIndices: previewIndices,
                      previewStates: previewStates,
                      previewRevealed: _previewMoveRevealed,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: turn.busted
                          ? _buildBustedView(turn, isAiTurn: isAiTurn)
                          : (isAiTurn
                                ? _buildAiTurnView(engine)
                                : (isInheritedChoice
                                      // Popup dédiée hors rejeu (voir
                                      // _maybeShowInheritedHandDialog) : rien
                                      // à montrer ici en attendant, sauf en
                                      // rejeu où elle reste l'unique rendu
                                      // (spectateur, jamais de popup).
                                      ? (widget.replayMode
                                            ? _buildInheritedChoiceRow(engine)
                                            : const SizedBox.shrink())
                                      : _buildHumanControlRow(engine, turn))),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: _buildGameLog(assignAvatarColors(engine.players.map((p) => p.name))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _scoreGridAction(List<Player> players) {
    // En mode rejeu, seul le retour compte (flèche standard de l'AppBar) :
    // pas d'icône grille de score ni "quitter", juste le sélecteur de
    // vitesse x1/x2/x4.
    if (widget.replayMode) return const [ReplaySpeedControl()];

    final l10n = AppLocalizations.of(context);
    return [
      IconButton(
        icon: const Icon(Icons.grid_on),
        tooltip: l10n.scoreGridLabel,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScoreGridScreen(players: players)),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        tooltip: l10n.leaveGameTooltip,
        // La partie est déjà sauvegardée en continu après chaque transition
        // (voir GameNotifier) : quitter ne nécessite aucune action explicite
        // de sauvegarde, juste revenir à l'écran d'accueil.
        onPressed: () => popToHome(context),
      ),
    ];
  }

  /// Ouvre la grille de score filtrée sur un seul joueur (clic sur sa ligne
  /// dans le [ScoreSheet]) : son nom complet sert alors de libellé de
  /// colonne plutôt que des initiales.
  void _openPlayerGrid(Player player) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScoreGridScreen(players: [player])),
    );
  }

  /// Déclenche [_showInheritedHandDialog] quand c'est pertinent — tour
  /// humain hors rejeu en attente d'un choix de main héritée — et au plus
  /// une fois par occasion de choix : l'[GameEngine] courant reste la MÊME
  /// instance (égalité de référence) tant que le joueur n'a pas décidé
  /// (aucune transition d'état tant que [GameEngine.activeTurn] reste null),
  /// donc comparer à la dernière instance pour laquelle la popup a déjà été
  /// ouverte suffit à éviter les doublons sur les rebuilds répétés — même
  /// mécanisme que [_bustKeyBeingRevealed] pour le craque.
  ///
  /// Ne fait rien tant que cet écran n'est pas la route active : sinon, un
  /// appel programmé dans le même passage de `build()` qui vient de pousser
  /// [PassDeviceScreen] ouvrirait la popup PAR-DESSUS cet écran de
  /// transition. Appelé à la fois depuis `build()` (cas sans écran de
  /// transition) et depuis le `.then()` du push de [PassDeviceScreen] (une
  /// fois cet écran dépilé), donc pas besoin d'attendre un rebuild
  /// supplémentaire dans ce second cas.
  void _maybeShowInheritedHandDialog() {
    if (!mounted || widget.replayMode) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final engine = ref.read(gameProvider);
    if (engine == null || engine.activeTurn != null) return;
    if (ref.read(gameProvider.notifier).isAiPlayer(engine.currentPlayerIndex)) {
      return;
    }
    if (_inheritedHandDialogShownFor == engine) return;
    _inheritedHandDialogShownFor = engine;
    _showInheritedHandDialog(engine);
  }

  /// Popup dédiée proposant de reprendre la main laissée par le joueur
  /// précédent ou d'en repartir une neuve : annonce le score déjà acquis et
  /// le nombre de dés hérités, et suffixe chaque bouton du pourcentage de
  /// chance de marquer sur le tout premier lancer de cette option — même
  /// calcul que le reste de l'écran (voir [_scorePercentLabel]), pour rester
  /// cohérent avec le pourcentage déjà affiché sur le bouton "Lancer"
  /// partout ailleurs.
  void _showInheritedHandDialog(GameEngine engine) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gameProvider.notifier);
    final canResume = !engine.inheritedHandExceedsWinningScore;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inheritedHandDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.inheritedHandDialogMessage(engine.inheritedScore, engine.nextTurnDice)),
            if (!canResume) ...[
              const SizedBox(height: 8),
              Text(
                l10n.inheritedHandExceedsWinning,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          if (canResume)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                notifier.startTurn(useFullHand: false);
                notifier.roll();
              },
              child: Text(
                '${l10n.resumeHandButton} '
                '(${_scorePercentLabel(engine.nextTurnDice, engine.inheritedExtendedValues)})',
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.startTurn(useFullHand: true);
              notifier.roll();
            },
            child: Text('${l10n.newHandButton} (${_scorePercentLabel(5, const {})})'),
          ),
        ],
      ),
    );
  }

  /// Choix de main héritée (dés d'un tour précédent) pour un joueur humain,
  /// en mode rejeu seulement (spectateur, jamais de popup — voir
  /// [_showInheritedHandDialog] pour le cas interactif) : même ligne de
  /// contrôle compacte que le reste du tour (bouton "Lancer" au pourcentage
  /// de chance de marquer, qui reprend la main héritée ET lance en un seul
  /// geste), avec "Refuser" à la place de "Stop" pour repartir à 5 dés
  /// neufs à la place.
  Widget _buildInheritedChoiceRow(GameEngine engine) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gameProvider.notifier);
    final canContinue = !engine.inheritedHandExceedsWinningScore;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canContinue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.inheritedHandExceedsWinning,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canContinue) ...[
              _rollButton(
                onPressed: () {
                  notifier.startTurn(useFullHand: false);
                  notifier.roll();
                },
                label: _scorePercentLabel(
                  engine.nextTurnDice,
                  engine.inheritedExtendedValues,
                ),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton(
              onPressed: () {
                notifier.startTurn(useFullHand: true);
                notifier.roll();
              },
              child: Text(l10n.declineInheritedHandButton),
            ),
          ],
        ),
      ],
    );
  }

  /// Hauteur fixe des zones "Piste" et "Main courante" : une seule rangée de
  /// dés à leur taille par défaut, quel que soit le contenu (dés, vide, ou
  /// texte de substitution) — évite que les zones changent de hauteur.
  /// Marge réduite au minimum (le DieWidget a déjà 4px de marge propre de
  /// chaque côté) pour des zones aussi compactes que possible.
  static const double _diceZoneHeight = DieWidget.defaultSize + 8;

  /// Marge interne réduite des zones "Piste"/"Main courante" (contrairement
  /// au défaut de [BorderedSection], pensé pour les zones plus hautes de
  /// l'écran d'accueil).
  static const _diceZonePadding = EdgeInsets.fromLTRB(16, 14, 16, 6);

  static const _previewFadeDuration = Duration(milliseconds: 300);

  /// Largeur fixe et identique des boutons "Lancer" et "Stop" (voir
  /// [_buildHumanControlRow]) : évite que le bouton Lancer change de
  /// taille/position selon la longueur de son libellé ("100 %" contre "Main
  /// pleine !") ou selon que Stop soit affiché à côté ou non. Assez large
  /// pour le plus long des deux libellés (icône dé + "Main pleine !").
  static const double _controlButtonWidth = 164.0;

  /// Zone bordurée "Piste" : uniquement les dés du lancer en attente de
  /// décision (ou rien, zone vide, s'il n'y en a aucun) — son score va dans
  /// le libellé lui-même, entre parenthèses, une fois [showScore] (les dés
  /// immobilisés, voir `_rollSettled`). `selectedKeep` ne pèse que sur
  /// l'aperçu visuel (voir `_classifyDiceForDisplay`) : 0 pour l'IA/un
  /// craque (rien n'est encore "décidé" à afficher), la sélection réelle du
  /// joueur sinon. Les dés d'indice dans [previewIndices] s'effacent en
  /// fondu une fois [previewRevealed] (migration visuelle vers "Main
  /// courante", voir `_scheduleRollSettleAndPreviewMove`).
  Widget _buildRollZone(
    TurnState turn,
    int selectedKeep, {
    required bool showScore,
    required Set<int> previewIndices,
    required bool previewRevealed,
  }) {
    final l10n = AppLocalizations.of(context);
    final analysis = turn.pendingRoll;
    final label = showScore
        ? l10n.currentRollZoneLabelWithScore(
            _previewPoints(analysis!, selectedKeep),
          )
        : l10n.currentRollZoneLabel;
    return BorderedSection(
      label: label,
      fillAvailableSpace: false,
      padding: _diceZonePadding,
      child: SizedBox(
        height: _diceZoneHeight,
        child: Center(
          child: analysis == null
              ? const SizedBox.shrink()
              // Chaque dé du lancer est TOUJOURS rendu ici (composition
              // fixe) : seule son opacité varie selon previewIndices, pour
              // un fondu propre dans les deux sens (garder <-> redonner —
              // voir aussi _buildHandZone) plutôt qu'une apparition/
              // disparition instantanée si le widget était conditionnel.
              : _fittedDiceRow(analysis.faces.length, (i, size) {
                  final states = _classifyDiceForDisplay(
                    analysis,
                    selectedKeep,
                  );
                  final die = DieWidget(
                    value: analysis.faces[i],
                    state: states[i],
                    rollToken: analysis,
                    bodyColor: _diceColor(i),
                    size: size,
                  );
                  final opacity =
                      (previewRevealed && previewIndices.contains(i))
                      ? 0.0
                      : 1.0;
                  return AnimatedOpacity(
                    opacity: opacity,
                    duration: _previewFadeDuration,
                    child: die,
                  );
                }),
        ),
      ),
    );
  }

  /// Zone bordurée "Main courante" : les dés gardés ce tour, avec le score du
  /// tour (et le minimum requis) dans le libellé, coloré comme avant cette
  /// refonte (juste déplacé depuis sa propre ligne). Affiche en plus, en
  /// fondu, les dés du lancer en attente d'indice dans [previewIndices] une
  /// fois [previewRevealed] : une prévisualisation de ce que "garder par
  /// défaut" donnerait, purement visuelle (la décision réelle n'est
  /// appliquée qu'au clic sur Lancer/Arrêter).
  Widget _buildHandZone(
    TurnState turn, {
    required int liveScore,
    required int minimum,
    required Color scoreColor,
    required Color minimumColor,
    required RollAnalysis? pendingAnalysis,
    required Set<int> previewIndices,
    required List<DieVisualState>? previewStates,
    required bool previewRevealed,
  }) {
    final l10n = AppLocalizations.of(context);
    final kept = turn.keptDiceThisTurn;
    // Composition fixe, symétrique à _buildRollZone : une place est TOUJOURS
    // réservée pour chaque dé du lancer en attente (pas seulement ceux
    // actuellement dans previewIndices), invisible par défaut — sans ça, le
    // nombre de dés affichés changerait avec la sélection et un dé qui
    // quitte previewIndices disparaîtrait instantanément plutôt qu'en
    // fondu. kept.length + pendingCount ne dépasse jamais 5 (partition des
    // dés du tour entre déjà-gardés et en-attente).
    final pendingCount = pendingAnalysis?.faces.length ?? 0;
    final totalCount = kept.length + pendingCount;
    return BorderedSection(
      label: l10n.currentHandZoneLabel,
      fillAvailableSpace: false,
      padding: _diceZonePadding,
      labelSuffix: [
        const TextSpan(text: ' '),
        TextSpan(
          text: '$liveScore',
          style: TextStyle(color: scoreColor),
        ),
        TextSpan(
          text: ' (>$minimum)',
          style: TextStyle(color: minimumColor),
        ),
      ],
      child: SizedBox(
        height: _diceZoneHeight,
        child: Center(
          child: totalCount == 0
              ? const SizedBox.shrink()
              : _fittedDiceRow(totalCount, (i, size) {
                  if (i < kept.length) {
                    final d = kept[i];
                    return DieWidget(
                      value: d.value,
                      state: d.isExtended
                          ? DieVisualState.extended
                          : DieVisualState.kept,
                      bodyColor: _diceColor(i),
                      size: size,
                    );
                  }
                  final faceIndex = i - kept.length;
                  final visible =
                      previewRevealed && previewIndices.contains(faceIndex);
                  return AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: _previewFadeDuration,
                    child: DieWidget(
                      value: pendingAnalysis!.faces[faceIndex],
                      state: previewStates![faceIndex],
                      bodyColor: _diceColor(i),
                      size: size,
                    ),
                  );
                }),
        ),
      ),
    );
  }

  /// Journal de partie : lecture seule, horodaté, du plus récent (en haut) au
  /// plus ancien — pas besoin de gérer le défilement, une nouvelle entrée
  /// apparaît directement en haut, déjà dans la zone visible.
  /// Colonnes "qui / quand / quoi" (voir [_buildGameLog]) : largeurs fixes
  /// pour "qui" (blason) et "quand" (heure), le reste à "quoi" (message, qui
  /// enchaîne sur plusieurs lignes si besoin plutôt que d'être tronqué).
  static const _logWhoColumnWidth = 26.0;
  static const _logWhenColumnWidth = 52.0;

  /// Cellule "quoi" d'une ligne de journal : texte simple, sauf pour une
  /// entrée de collision de score ([_LogEntry.scoreBarred]), qui affiche en
  /// plus le score barré (barré visuellement) suivi du blason du joueur
  /// concerné.
  Widget _buildLogWhatCell(_LogEntry entry, Map<String, Color> avatarColors) {
    if (entry.barredScore == null) {
      return Text(': ${entry.text}', style: const TextStyle(fontSize: 13));
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.white),
        children: [
          TextSpan(text: ': ${entry.text} '),
          TextSpan(
            text: '${entry.barredScore}',
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          if (entry.barredPlayerName != null) ...[
            const WidgetSpan(child: SizedBox(width: 4)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: PlayerAvatarWidget(
                name: entry.barredPlayerName!,
                size: 16,
                color: avatarColors[entry.barredPlayerName!],
              ),
            ),
          ],
          if (entry.textAfterBarredScore != null)
            TextSpan(text: ' ${entry.textAfterBarredScore}'),
        ],
      ),
    );
  }

  Widget _buildGameLog(Map<String, Color> avatarColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _log.isEmpty
          ? Center(
              child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
            )
          : Scrollbar(
              controller: _logScrollController,
              thumbVisibility: true,
              thickness: 3,
              child: SingleChildScrollView(
                controller: _logScrollController,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  columnWidths: const {
                    0: FixedColumnWidth(_logWhoColumnWidth),
                    1: FixedColumnWidth(_logWhenColumnWidth),
                    2: FlexColumnWidth(),
                  },
                  children: [
                    // Le plus récent en haut (voir la doc de classe) : on
                    // parcourt _log à l'envers plutôt que de le retourner
                    // (évite une copie à chaque rebuild).
                    for (var i = _log.length - 1; i >= 0; i--)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: PlayerAvatarWidget(
                              name: _log[i].playerName,
                              size: 18,
                              color: avatarColors[_log[i].playerName],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              _formatLogTime(_log[i].timestamp),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: _buildLogWhatCell(_log[i], avatarColors),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Tour de l'IA en cours : un unique bouton explicite reflétant l'action
  /// qu'elle va effectuer, qui déclenche cette même action (les deux
  /// s'appuient sur la même logique de décision, voir [GameNotifier]). Gère
  /// aussi elle-même le choix de main héritée (`engine.activeTurn == null`)
  /// — plus d'écran séparé, voir CLAUDE.md. Le craque est géré séparément
  /// par [_buildBustedView] (appelé avant celle-ci par l'appelant, IA ou
  /// humain confondus).
  Widget _buildAiTurnView(GameEngine engine) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gameProvider.notifier);
    void action() => ref.read(gameProvider.notifier).playAiTurnStep();

    // Choix de main héritée : mêmes deux commandes que la version humaine en
    // rejeu (voir [_buildInheritedChoiceRow]), seule celle que l'IA va
    // réellement prendre étant active.
    if (engine.activeTurn == null) {
      final accepts = notifier.previewAiAcceptInheritedHand();
      return _controlRow(
        primary: _rollButton(
          onPressed: accepts ? action : null,
          label: _scorePercentLabel(engine.nextTurnDice, engine.inheritedExtendedValues),
        ),
        trailing: [
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: accepts ? null : action,
            child: Text(l10n.declineInheritedHandButton),
          ),
        ],
      );
    }

    final turn = engine.activeTurn!;
    final currentTotal = engine.currentPlayer.totalScore;
    final pending = turn.pendingRoll;

    // Décision de garde en attente : la ligne montre déjà ce que le lancer
    // vaudra une fois cette garde appliquée, exactement comme le bouton d'un
    // joueur humain au même instant — et le nombre de 5 que l'IA garde
    // là où l'humain a son sélecteur.
    if (pending != null) {
      final declineCount = notifier.previewAiDeclineFives(turn);
      final effective = applyKeepDecision(turn, declineFivesCount: declineCount);
      final fives = pending.declinableFives?.diceCount ?? 0;
      return _controlRow(
        primary: _rollButton(
          onPressed: action,
          label: effective.mustContinue
              ? l10n.logHotDiceMessage
              : _scorePercentLabel(effective.diceToRoll, effective.extendedValues),
        ),
        trailing: [
          if (_hasRealChoice(turn, pending, currentTotal: currentTotal)) ...[
            ..._keptFivesLead,
            Text('${fives - declineCount}'),
          ],
        ],
      );
    }

    // Plus de lancer en attente : l'IA va relancer ou s'arrêter. Les deux
    // commandes occupent les mêmes emplacements que pour un humain — Stop
    // n'apparaissant que si s'arrêter est légal — et seule celle qu'elle
    // prend est active.
    final canBank = tryBank(
      turn,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: currentTotal,
    ).success;
    final stops = canBank && !notifier.previewAiContinue(turn);
    return _controlRow(
      primary: _rollButton(
        onPressed: stops ? null : action,
        label: turn.mustContinue
            ? l10n.logHotDiceMessage
            : _scorePercentLabel(turn.diceToRoll, turn.extendedValues),
      ),
      trailing: [
        if (canBank && _rollSettled) ...[
          const SizedBox(width: 8),
          _stopButton(onPressed: stops ? action : null),
        ],
      ],
    );
  }

  /// [isAiTurn] : un tour IA n'attend jamais de clic sur ce bouton (le
  /// craque est acquitté tout seul par [GameNotifier.playAiTurnStep]) — il
  /// reste affiché tel quel, purement informatif. Pour un tour humain hors
  /// rejeu, c'est désormais [_showBustDialog] (une popup dédiée) qui porte
  /// l'action réelle : cette zone ne montre alors plus rien une fois le
  /// craque révélé, pour ne pas dupliquer le bouton.
  Widget _buildBustedView(TurnState turn, {required bool isAiTurn}) {
    // Le résultat n'est révélé qu'une fois l'animation de lancer des dés
    // terminée (cf. _scheduleBustRevealIfNeeded) : le suspense du lancer ne
    // doit pas être gâché par un message qui s'affiche trop tôt.
    final key = turn.pendingRoll ?? turn;
    final revealed = _bustRevealed && _bustKeyBeingRevealed == key;
    if (!revealed) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (!widget.replayMode && !isAiTurn) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return FilledButton(
      onPressed: () => ref.read(gameProvider.notifier).endBustedTurn(),
      child: Text(l10n.bustedTitle),
    );
  }

  /// Lance les dés du tour humain en cours, en appliquant d'abord la
  /// sélection de 5 courante ([_selectedKeep]) s'il y a un lancer en attente
  /// à trancher — logique du bouton "Lancer" de [_buildHumanControlRow],
  /// extraite pour être partagée avec [_handleShake] (secouer le téléphone
  /// équivaut à un tap sur ce même bouton).
  void _rollForHumanTurn(GameEngine engine, TurnState turn) {
    final pending = turn.pendingRoll;
    final notifier = ref.read(gameProvider.notifier);
    if (pending != null) {
      final currentTotal = engine.currentPlayer.totalScore;
      final fives = pending.declinableFives;
      final minKeep = minKeepableFives(pending);
      final maxKeep = maxKeepableFives(turn, pending, currentTotal: currentTotal);
      final selectedKeep = _selectedKeep.clamp(minKeep, maxKeep < minKeep ? minKeep : maxKeep);
      final declineCount = (fives?.diceCount ?? 0) - selectedKeep;
      notifier.applyKeep(declineFivesCount: declineCount);
      // La décision de garde peut elle-même craquer le tour (dépassement de
      // 10000, ou main pleine tombant pile dessus — voir GameEngine.applyKeep) :
      // relancer là-dessus lèverait "Le tour est terminé". Le craque est déjà
      // à l'écran, il n'y a plus rien à lancer.
      if (ref.read(gameProvider)?.activeTurn?.busted ?? false) return;
    }
    notifier.roll();
  }

  /// Appelé par [ShakeDetector] : équivaut à un tap sur le bouton "Lancer"
  /// actuellement affiché, uniquement quand ce geste a un sens sans
  /// ambiguïté — jamais pendant le tour d'une IA, sur un craque déjà
  /// affiché, ou tant que cet écran n'est pas la route au premier plan
  /// (partie en pause, écran de paramètres ouvert...). Ignore volontairement
  /// le choix de main héritée (`activeTurn == null`) : sa propre popup (voir
  /// [_showInheritedHandDialog]) propose déjà deux actions bien distinctes
  /// entre lesquelles secouer ne permettrait pas de choisir sans ambiguïté.
  void _handleShake() {
    if (!mounted || widget.replayMode) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final engine = ref.read(gameProvider);
    if (engine == null || engine.gameOver || engine.activeTurn == null) return;
    if (ref.read(gameProvider.notifier).isAiPlayer(engine.currentPlayerIndex)) return;
    final turn = engine.activeTurn!;
    if (turn.busted) return;
    _rollForHumanTurn(engine, turn);
  }

  /// Ligne de contrôle unique pour un tour humain, que le joueur soit en
  /// train de choisir combien de 5 garder sur un lancer en attente ou
  /// simplement idle (rien en attente) — même méthode dans les deux cas,
  /// pour que la zone de contrôle garde toujours la même forme (voir
  /// CLAUDE.md, "espace entre main courante et le journal"). Le bouton
  /// "Lancer" porte le pourcentage de chance de marquer au lancer suivant
  /// (dé + %), "Stop" est toujours affiché mais désactivé quand banquer
  /// n'est pas légal, et le pictogramme de recyclage + les boutons radio de
  /// choix des 5 ne sont présents QUE quand un vrai choix existe (sinon la
  /// décision forcée est appliquée directement avec l'action suivante, pas
  /// d'écran "Valider" intermédiaire).
  Widget _buildHumanControlRow(GameEngine engine, TurnState turn) {
    final l10n = AppLocalizations.of(context);
    final pending = turn.pendingRoll;
    final currentTotal = engine.currentPlayer.totalScore;
    final canChoose = pending != null && _hasRealChoice(turn, pending, currentTotal: currentTotal);
    final fives = pending?.declinableFives;
    final minKeep = pending != null ? minKeepableFives(pending) : 0;
    // Garder plus que cette borne ferait dépasser 10000 : ces options ne sont
    // pas proposées du tout (voir maxKeepableFives).
    final maxKeep = pending != null ? maxKeepableFives(turn, pending, currentTotal: currentTotal) : 0;
    final selectedKeep = _selectedKeep.clamp(minKeep, maxKeep < minKeep ? minKeep : maxKeep);
    final declineCount = pending != null
        ? (fives?.diceCount ?? 0) - selectedKeep
        : 0;

    // État hypothétique si la sélection en cours était appliquée (ou déjà
    // décidé si aucun lancer en attente) : sert à la fois au pourcentage du
    // bouton "Lancer" et à la légalité de "Stop" — évite un écran "Valider"
    // séparé de la décision de continuer/s'arrêter.
    final effective = pending != null
        ? applyKeepDecision(turn, declineFivesCount: declineCount)
        : turn;
    final bankAttempt = tryBank(
      effective,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
    );
    // mustContinue doit refléter l'état hypothétique (`effective`), pas
    // l'état déjà commité (`turn`) : tant qu'un lancer reste en attente sans
    // choix réel, la décision de garde n'a pas encore été appliquée côté
    // moteur, donc `turn.mustContinue` est toujours celui d'AVANT ce lancer
    // (un tour de retard sur les dés chauds qui viennent d'être complétés).
    final rollLabel = effective.mustContinue
        ? l10n.logHotDiceMessage
        : _scorePercentLabel(effective.diceToRoll, effective.extendedValues);

    void onRoll() => _rollForHumanTurn(engine, turn);

    void onStop() {
      final notifier = ref.read(gameProvider.notifier);
      if (pending != null) notifier.applyKeep(declineFivesCount: declineCount);
      notifier.bank();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Main pleine" et "dépasserait 10000" ont désormais leur propre
        // entrée dans le journal de partie (voir logHotDiceMessage, déjà
        // repris comme libellé du bouton Lancer ci-dessous, et _logBust)
        // plutôt qu'un bandeau ici : cette zone ne doit jamais changer de
        // forme selon la raison pour laquelle on ne peut pas (encore)
        // s'arrêter. Les autres raisons (score insuffisant, finirait sur
        // 50...) restent expliquées ici, le bouton Stop étant alors
        // simplement absent plutôt que désactivé (voir plus bas).
        if (pending == null &&
            !effective.mustContinue &&
            !bankAttempt.success &&
            bankAttempt.reason != BankFailureReason.notRolledYet)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _failureMessage(l10n, bankAttempt),
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        _controlRow(
          primary: _rollButton(onPressed: onRoll, label: rollLabel),
          trailing: [
            // Stop n'apparaît qu'une fois les dés immobilisés
            // (`_rollSettled`, comme les scores affichés) : le voir surgir
            // pendant que les dés roulent encore révélerait d'avance que le
            // lancer marque assez pour pouvoir s'arrêter — le suspense du
            // lancer serait gâché. Sans lancer en attente, `_rollSettled`
            // est déjà vrai : rien ne change pour l'état au repos.
            if (bankAttempt.success && _rollSettled) ...[
              const SizedBox(width: 8),
              _stopButton(onPressed: onStop),
            ],
            if (canChoose) ...[
              ..._keptFivesLead,
              DropdownButton<int>(
                value: selectedKeep,
                underline: const SizedBox.shrink(),
                items: [
                  for (var i = minKeep; i <= maxKeep; i++)
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (v) => setState(() => _selectedKeep = v!),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Gabarit unique de la ligne de contrôle, partagé par TOUS les tours —
  /// humain, IA, main héritée. Le bouton principal reste toujours à la même
  /// position, aligné à gauche, à sa largeur fixe ([_controlButtonWidth])
  /// pour ne pas changer de taille selon son libellé ; les commandes annexes
  /// apparaissent à sa droite, à la demande, sans jamais le déplacer. Passer
  /// par ce seul gabarit est ce qui garantit qu'un tour IA ne se présente pas
  /// autrement qu'un tour humain (emplacement, taille, alignement).
  Widget _controlRow({required Widget primary, List<Widget> trailing = const []}) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(width: _controlButtonWidth, child: primary),
          ...trailing,
        ],
      ),
    );
  }

  /// Bouton Stop, réduit au minimum (icône seule, pas de largeur imposée) :
  /// contrairement à Lancer, son libellé ne varie jamais, pas besoin d'une
  /// largeur fixe pour éviter un changement de taille. [onPressed] null le
  /// laisse visible mais inerte — c'est ainsi qu'un tour IA montre un arrêt
  /// possible qu'elle ne prend pas, sans déformer la ligne.
  Widget _stopButton({required VoidCallback? onPressed}) {
    return IconButton.outlined(
      onPressed: onPressed,
      icon: const Icon(Icons.stop),
      tooltip: AppLocalizations.of(context).stopButton,
    );
  }

  /// Pictogramme annonçant le nombre de 5 gardés, devant le sélecteur
  /// (humain) ou devant le nombre choisi par l'IA : même écart, même icône,
  /// pour que les deux lignes se superposent exactement.
  static const List<Widget> _keptFivesLead = [
    SizedBox(width: 12),
    Icon(Icons.recycling, size: 18),
    SizedBox(width: 4),
  ];

  String _failureMessage(AppLocalizations l10n, BankAttempt attempt) {
    switch (attempt.reason) {
      case BankFailureReason.belowMinimum:
        return l10n.failureBelowMinimum;
      case BankFailureReason.endsIn50:
        return l10n.failureEndsIn50;
      case BankFailureReason.mustContinueHotDice:
        return l10n.failureMustContinueHotDice;
      case BankFailureReason.notRolledYet:
        return l10n.failureNotRolledYet;
      case BankFailureReason.wouldMakeWinningImpossible:
        return l10n.failureWouldMakeWinningImpossible;
      case null:
        return '';
    }
  }

  Color? _diceColor(int index) =>
      diceBodyColorFor(ref.watch(settingsProvider).diceColorMode, index);
}

/// Construit une rangée d'exactement [count] dés qui tient toujours sur une
/// seule ligne. La taille est calculée pour [_diceRowReferenceCount] dés
/// (jamais en dessous de 40px, jamais au-dessus de la taille par défaut) —
/// PAS pour [count] : la taille d'un dé doit rester la même quel que soit le
/// nombre de dés affichés dans la rangée (1 dé n'est pas plus gros qu'une
/// main pleine), donc toujours calculée comme si les 5 dés y étaient, la
/// taille "idéale". Adaptée à la fois à la largeur de l'écran et à son
/// orientation.
const int _diceRowReferenceCount = 5;

Widget _fittedDiceRow(
  int count,
  Widget Function(int index, double size) builder,
) {
  if (count == 0) return const SizedBox.shrink();
  const dieMargin =
      8.0; // EdgeInsets.all(4) appliqué de chaque côté par DieWidget
  const minSize = 40.0;
  return LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : DieWidget.defaultSize * _diceRowReferenceCount;
      final size = ((available / _diceRowReferenceCount) - dieMargin).clamp(
        minSize,
        DieWidget.defaultSize,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [for (var i = 0; i < count; i++) builder(i, size)],
      );
    },
  );
}
