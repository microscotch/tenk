import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/tutorial.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_providers.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bordered_section.dart';
import '../widgets/dice_classification.dart';
import '../widgets/die_widget.dart';

/// Le tutoriel : un tour joué pas à pas sur des dés choisis (voir
/// [TutorialSession]), où une seule commande est active à la fois et une bulle
/// dit quoi faire et pourquoi. Il ne touche à aucune partie — ni journal, ni
/// sauvegarde, ni statistiques — et se passe à tout moment.
///
/// Proposé au tout premier lancement (voir `launchScreenFor`), avec la page
/// [next] à ouvrir ensuite ; sans [next] (relu depuis l'écran des règles), il
/// se referme simplement.
class TutorialScreen extends ConsumerStatefulWidget {
  final Widget? next;

  const TutorialScreen({super.key, this.next});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  TutorialSession _session = TutorialSession.start();

  void _perform() =>
      setState(() => _session = _session.perform(_session.current.action));

  /// Sort du tutoriel, fini ou passé : il compte comme vu dans les deux cas.
  void _leave() {
    ref.read(settingsProvider.notifier).markTutorialSeen();
    final next = widget.next;
    if (next == null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    }
  }

  String _stepText(AppLocalizations l10n) => [
    l10n.tutorialStep0,
    l10n.tutorialStep1,
    l10n.tutorialStep2,
    l10n.tutorialStep3,
    l10n.tutorialStep4,
    l10n.tutorialStep5,
    l10n.tutorialStep6,
    l10n.tutorialStep7,
    l10n.tutorialStep8,
    l10n.tutorialStep9,
  ][_session.step];

  ({String label, IconData? icon}) _button(AppLocalizations l10n) =>
      switch (_session.current.action) {
        TutorialAction.next => (
          label: l10n.tutorialNext,
          icon: Icons.arrow_forward,
        ),
        TutorialAction.roll => (label: l10n.tutorialRoll, icon: Icons.casino),
        TutorialAction.keep => (label: l10n.tutorialKeep, icon: Icons.check),
        TutorialAction.stop => (label: l10n.stopButton, icon: Icons.front_hand),
        TutorialAction.finish => (
          label: l10n.tutorialFinish,
          icon: Icons.check,
        ),
      };

  /// Une rangée de dés tenant sur la largeur, comme celles de l'écran de jeu.
  Widget _diceRow({
    required int count,
    required Widget Function(int index, double size) die,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = ((constraints.maxWidth / 5) - 2 * DieWidget.margin).clamp(
          24.0,
          DieWidget.defaultSize,
        );
        return SizedBox(
          height: size + 2 * DieWidget.margin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (var i = 0; i < count; i++) die(i, size)],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final turn = _session.turn;
    final rolled = turn.pendingRoll;
    final button = _button(l10n);
    final isFinish = _session.current.action == TutorialAction.finish;

    return PopScope(
      canPop: widget.next == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: Text(l10n.tutorialTitle),
          automaticallyImplyLeading: widget.next == null,
          actions: [
            if (!isFinish)
              TextButton(onPressed: _leave, child: Text(l10n.tutorialSkip)),
          ],
        ),
        // Épinglé hors du défilement : la seule commande active reste visible
        // même sur un petit écran.
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const ValueKey('tutorial-action'),
              onPressed: isFinish ? _leave : _perform,
              icon: Icon(button.icon),
              label: Text(button.label),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_session.step + 1) / tutorialSteps.length,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _stepText(l10n),
                      key: const ValueKey('tutorial-text'),
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BorderedSection(
                  label: l10n.currentRollZoneLabel,
                  fillAvailableSpace: false,
                  child: rolled == null
                      ? const SizedBox(height: DieWidget.defaultSize / 2)
                      : () {
                          final states = classifyDiceForDisplay(
                            rolled,
                            rolled.declinableFives?.diceCount ?? 0,
                          );
                          return _diceRow(
                            count: rolled.faces.length,
                            die: (i, size) => DieWidget(
                              value: rolled.faces[i],
                              state: turn.busted
                                  ? DieVisualState.junk
                                  : states[i],
                              rollToken: rolled,
                              size: size,
                            ),
                          );
                        }(),
                ),
                const SizedBox(height: 12),
                BorderedSection(
                  label: l10n.currentHandZoneLabel,
                  labelSuffix: [TextSpan(text: ' ${turn.bankedScore}')],
                  fillAvailableSpace: false,
                  child: turn.keptDiceThisTurn.isEmpty
                      ? const SizedBox(height: DieWidget.defaultSize / 2)
                      : _diceRow(
                          count: turn.keptDiceThisTurn.length,
                          die: (i, size) {
                            final d = turn.keptDiceThisTurn[i];
                            return DieWidget(
                              value: d.value,
                              state: d.isExtended
                                  ? DieVisualState.extended
                                  : DieVisualState.kept,
                              size: size,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
