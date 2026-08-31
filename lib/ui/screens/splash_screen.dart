import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/die_widget.dart';
import '../sound_effects.dart';
import 'setup_screen.dart';

/// Écran d'introduction façon "studio" : l'avatar GitHub de l'auteur en zoom
/// dans le haut de l'écran, puis "présente" en dessous, puis les 5 dés qui
/// tombent sur une quinte d'as (5x1 = 10000, victoire immédiate dans les
/// règles du jeu) avec "10K" en zoom au centre, et enfin la mention de
/// paternité en petit en bas. Une fois la mise en scène terminée, reste
/// affiché [displayDuration] de plus avant un fondu vers l'écran de
/// configuration ; sautable à tout moment en touchant l'écran.
class SplashScreen extends StatefulWidget {
  final Duration displayDuration;

  const SplashScreen({super.key, this.displayDuration = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _choreographyDuration = Duration(milliseconds: 3400);
  static const _fadeOutDuration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  late final Animation<double> _avatarOpacity;
  late final Animation<double> _avatarScale;
  late final Animation<double> _presenteOpacity;
  late final Animation<double> _diceOpacity;
  late final Animation<double> _diceScale;
  late final Animation<double> _resultOpacity;
  late final Animation<double> _resultScale;
  late final Animation<double> _taglineOpacity;

  Timer? _navigateTimer;
  Object? _diceRollToken;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _choreographyDuration)..forward();

    _avatarOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.28));
    _avatarScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.30, curve: Curves.easeOutBack));
    _presenteOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.42));
    _diceOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.42, 0.52));
    _diceScale = CurvedAnimation(parent: _controller, curve: const Interval(0.42, 0.72, curve: Curves.easeOutBack));
    _resultOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.72, 0.85));
    _resultScale = CurvedAnimation(parent: _controller, curve: const Interval(0.72, 0.85, curve: Curves.easeOutBack));
    _taglineOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0));

    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _diceRollToken = Object()));

    SoundEffects.instance.playSplash();
    _navigateTimer = Timer(_choreographyDuration + widget.displayDuration, _goToSetup);
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
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  const SizedBox(height: 32),
                  Opacity(
                    opacity: _avatarOpacity.value,
                    child: Transform.scale(
                      scale: 0.4 + _avatarScale.value * 0.6,
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
                  Opacity(
                    opacity: _presenteOpacity.value,
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
                            opacity: _resultOpacity.value,
                            child: Transform.scale(
                              scale: 0.5 + _resultScale.value * 0.5,
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
                  Opacity(
                    opacity: _taglineOpacity.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'a fully vibe-coded app from a raspberry pi 5 with claude-code',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
