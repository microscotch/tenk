import 'dart:async';

import 'package:flutter/material.dart';

import '../auto_advance.dart';
import '../sound_effects.dart';
import '../widgets/die_widget.dart';
import 'setup_screen.dart';

/// Écran d'introduction façon "studio" : "Microscotch présente", puis les 5
/// dés qui tombent sur une quinte d'as (5x1 = 10000, victoire immédiate dans
/// les règles du jeu), avec un zoom, puis le titre qui apparaît en dessous.
/// Reste affiché [displayDuration] au total, sautable en touchant l'écran.
class SplashScreen extends StatefulWidget {
  final Duration displayDuration;

  const SplashScreen({super.key, this.displayDuration = kAutoAdvanceDelay});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _choreographyDuration = Duration(milliseconds: 3000);

  late final AnimationController _controller;
  late final Animation<double> _studioOpacity;
  late final Animation<double> _diceScale;
  late final Animation<double> _diceOpacity;
  late final Animation<double> _titleOpacity;

  Timer? _navigateTimer;
  Object? _diceRollToken;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _choreographyDuration)..forward();

    _studioOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);

    _diceOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.65));
    _diceScale = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 0.85, curve: Curves.easeOutBack));
    _titleOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0));

    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _diceRollToken = Object()));

    SoundEffects.instance.playSplash();
    _navigateTimer = Timer(widget.displayDuration, _goToSetup);
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigateTimer?.cancel();
    super.dispose();
  }

  void _goToSetup() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigateTimer?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goToSetup,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: _studioOpacity.value,
                    child: Text(
                      'Microscotch présente',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1.5),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _diceOpacity.value,
                        child: Transform.scale(
                          scale: 0.6 + _diceScale.value * 0.4,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              for (var i = 0; i < 5; i++)
                                DieWidget(value: 1, state: DieVisualState.kept, rollToken: _diceRollToken),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: _titleOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              Theme.of(context).colorScheme.primary,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(rect),
                          child: Text(
                            'Le 10 000',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
