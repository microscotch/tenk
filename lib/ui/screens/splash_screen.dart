import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/about_dialog.dart' show kAppTagline;
import '../widgets/die_widget.dart';
import 'setup_screen.dart';

/// Écran d'introduction façon "studio" : l'avatar GitHub de l'auteur en zoom
/// dans le haut de l'écran, puis "présente" en dessous, puis les 5 dés, qui
/// apparaissent immobiles en fondu sur des faces quelconques et, une fois le
/// fondu terminé, roulent pour tomber sur une quinte d'as (5x1 = 10000,
/// victoire immédiate dans les règles du jeu). Une fois le lancer
/// immobilisé, une courte pause puis "10K" zoome au centre, et enfin la
/// mention de paternité apparaît en bas. Une fois la mise en scène terminée,
/// reste affiché [displayDuration] de plus avant un fondu vers l'écran de
/// configuration ; sautable à tout moment en touchant l'écran.
class SplashScreen extends StatefulWidget {
  final Duration displayDuration;

  const SplashScreen({super.key, this.displayDuration = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Chorégraphie décrite comme une suite d'étapes séquentielles (chacune son
  // propre délai de déclenchement + sa propre durée de fondu), plutôt qu'une
  // seule timeline proportionnelle : ça permet de faire correspondre le
  // déclenchement de chaque étape à un événement réel plutôt qu'à une
  // fraction arbitraire d'une durée totale — en particulier, les dés ne
  // ne doivent commencer à rouler qu'une fois leur fondu d'apparition
  // terminé (on les voit d'abord posés, puis lancés), et "10K" ne doit
  // apparaître qu'après la fin RÉELLE du lancer
  // ([DieWidget.maxRollDuration]) plus une pause fixe de 250 ms.
  static const _avatarFadeIn = Duration(milliseconds: 500);
  static const _gapBeforePresente = Duration(milliseconds: 200);
  static const _presenteFadeIn = Duration(milliseconds: 350);
  static const _gapBeforeDice = Duration(milliseconds: 200);
  static const _diceFadeIn = Duration(milliseconds: 400);
  static const _pauseAfterRoll = Duration(milliseconds: 250);
  static const _resultFadeIn = Duration(milliseconds: 400);
  static const _gapBeforeFooter = Duration(milliseconds: 200);
  static const _footerFadeIn = Duration(milliseconds: 350);
  static const _fadeOutDuration = Duration(milliseconds: 600);

  // Instants de déclenchement de chaque étape, cumulés à partir des durées
  // ci-dessus (pas `const` : l'opérateur `+` de Duration n'est pas évaluable
  // à la compilation).
  static final _diceStart = _avatarFadeIn + _gapBeforePresente + _presenteFadeIn + _gapBeforeDice;
  static final _rollStart = _diceStart + _diceFadeIn;
  static final _resultStart = _rollStart + DieWidget.maxRollDuration + _pauseAfterRoll;
  static final _footerStart = _resultStart + _resultFadeIn + _gapBeforeFooter;
  static final _choreographyDuration = _footerStart + _footerFadeIn;

  final List<Timer> _timers = [];
  Object? _diceRollToken;

  /// Faces des dés avant le lancer : tirées au hasard, jamais l'as, pour que
  /// le lancer vers la quinte d'as se voie.
  List<int> _diceValues = [for (var i = 0; i < 5; i++) 2 + Random().nextInt(5)];
  bool _avatarVisible = false;
  bool _presenteVisible = false;
  bool _diceVisible = false;
  bool _resultVisible = false;
  bool _footerVisible = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Un délai nul déclencherait le fondu avant même le premier frame rendu
    // (donc sans transition visible) : on attend explicitement ce frame pour
    // l'étape initiale, comme pour n'importe quel autre déclenchement basé
    // sur l'affichage effectif à l'écran plutôt que sur une horloge.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _avatarVisible = true);
    });
    _schedule(_avatarFadeIn + _gapBeforePresente, () => setState(() => _presenteVisible = true));
    _schedule(_diceStart, () => setState(() => _diceVisible = true));
    _schedule(
      _rollStart,
      () => setState(() {
        // DieWidget ne lance son animation qu'au changement de token : le
        // lancer part donc exactement à la fin du fondu, et chaque dé
        // s'immobilise sur l'as.
        _diceRollToken = Object();
        _diceValues = List.filled(5, 1);
      }),
    );
    _schedule(_resultStart, () => setState(() => _resultVisible = true));
    _schedule(_footerStart, () => setState(() => _footerVisible = true));
    _schedule(_choreographyDuration + widget.displayDuration, _goToSetup);
  }

  void _schedule(Duration delay, VoidCallback action) {
    _timers.add(
      Timer(delay, () {
        if (!mounted) return;
        action();
      }),
    );
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _goToSetup() {
    if (_navigated || !mounted) return;
    _navigated = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        // Route nommée : c'est ce nom qui permet à n'importe quel écran plus
        // profond de revenir ici à coup sûr (voir [SetupScreen.routeName]).
        settings: const RouteSettings(name: SetupScreen.routeName),
        transitionDuration: _fadeOutDuration,
        pageBuilder: (_, _, _) => const SetupScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goToSetup,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: _avatarVisible ? 1 : 0,
                duration: _avatarFadeIn,
                child: AnimatedScale(
                  scale: _avatarVisible ? 1 : 0.4,
                  duration: _avatarFadeIn,
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(color: colorScheme.primary.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/github_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedOpacity(
                opacity: _presenteVisible ? 1 : 0,
                duration: _presenteFadeIn,
                child: Text(
                  AppLocalizations.of(context).splashPresents,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1.5),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: _diceVisible ? 1 : 0,
                        duration: _diceFadeIn,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            for (final value in _diceValues)
                              DieWidget(value: value, state: DieVisualState.kept, rollToken: _diceRollToken),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: _resultVisible ? 1 : 0,
                        duration: _resultFadeIn,
                        child: AnimatedScale(
                          scale: _resultVisible ? 1 : 0.5,
                          duration: _resultFadeIn,
                          curve: Curves.easeOutBack,
                          child: ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.4),
                                colorScheme.primary,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(rect),
                            child: Text(
                              '10K',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _footerVisible ? 1 : 0,
                duration: _footerFadeIn,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    kAppTagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
