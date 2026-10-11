import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/tutorial.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/settings_providers.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/tutorial_overlay.dart';
import 'game_screen.dart';

/// Le tutoriel : des leçons jouées sur le vrai écran de jeu ([GameScreen] en
/// mode tutoriel), contre un bot, sur des dés scénarisés (voir
/// [tutorialLessons]). Des bulles montrent la commande à toucher (voir
/// [TutorialOverlay]) ; l'étape suivante vient de l'état de la partie.
///
/// Sans [lesson], c'est le parcours complet, leçon après leçon : celui du
/// premier lancement (voir `launchScreenFor`), avec la page [next] à ouvrir
/// ensuite. Avec [lesson] (rejouée depuis la liste des leçons), cette leçon
/// seule.
///
/// Ce n'est pas une partie pour autant : ni seed, ni sauvegarde, ni
/// statistiques (voir [GameNotifier.startTutorial]). Il remplace l'état du
/// notifier de partie, qui est celui de l'écran de jeu : ne l'ouvrir que depuis
/// un écran sans partie empilée dessous (le premier lancement, l'accueil). Se
/// passe à tout moment, retour système compris ; fini ou passé, il compte comme
/// vu.
class TutorialScreen extends ConsumerStatefulWidget {
  final Widget? next;
  final TutorialLessonId? lesson;

  const TutorialScreen({super.key, this.next, this.lesson});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final List<TutorialLesson> _path = widget.lesson == null ? tutorialLessons : [tutorialLesson(widget.lesson!)];
  var _index = 0;
  TutorialGuide? _guide;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Après la première construction : un provider ne se modifie pas pendant
    // celle-ci. Les noms viennent de la langue de l'écran, d'où `context`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLesson(0));
  }

  @override
  void dispose() {
    _guide?.dispose();
    super.dispose();
  }

  void _startLesson(int index) {
    if (!mounted || _left) return;
    final l10n = AppLocalizations.of(context);
    final lesson = _path[index];
    ref.read(gameProvider.notifier).startTutorial(lesson, playerName: l10n.tutorialPlayerName, botName: l10n.botLabel);
    final previous = _guide;
    setState(() {
      _index = index;
      _guide = TutorialGuide(
        lesson: lesson,
        number: widget.lesson == null ? index + 1 : tutorialLessons.indexOf(lesson) + 1,
        total: tutorialLessons.length,
        hasNext: index + 1 < _path.length,
        onLessonDone: _lessonDone,
        onExit: _leave,
      );
    });
    // L'écran de la leçon précédente se démonte à la construction suivante.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous?.dispose());
  }

  void _lessonDone() {
    if (_index + 1 < _path.length) return _startLesson(_index + 1);
    _leave();
  }

  /// Sort du tutoriel, fini ou passé : il compte comme vu dans les deux cas, et
  /// la partie qu'il jouait ne reste pas à l'écran.
  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    ref.read(settingsProvider.notifier).markTutorialSeen();
    ref.read(gameProvider.notifier).endTutorial();
    final next = widget.next;
    if (next == null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    if (guide == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // Une clé par leçon : l'écran de jeu repart de zéro à chaque leçon.
    return GameScreen(key: ValueKey(guide.lesson.id), tutorial: guide);
  }
}

/// La liste des leçons du tutoriel, pour en rejouer une : ouverte depuis
/// l'écran des règles, et seulement depuis l'accueil (voir
/// `RulesScreen.canReplayTutorial`). Le parcours complet est le premier choix.
class TutorialLessonsScreen extends StatelessWidget {
  const TutorialLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(TutorialLessonId? lesson) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TutorialScreen(lesson: lesson)));
    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.tutorialLessonsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(l10n.tutorialWholePath),
            onTap: () => open(null),
          ),
          const Divider(),
          for (final (i, lesson) in tutorialLessons.indexed)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(tutorialLessonTitle(l10n, lesson.id)),
              onTap: () => open(lesson.id),
            ),
        ],
      ),
    );
  }
}
