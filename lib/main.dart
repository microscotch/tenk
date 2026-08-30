import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/casino_felt_background.dart';

void main() {
  runApp(const ProviderScope(child: Le10000App()));
}

class Le10000App extends StatelessWidget {
  const Le10000App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le 10000',
      theme: buildAppTheme(),
      builder: (context, child) => Stack(
        children: [
          const CasinoFeltBackground(),
          ?child,
        ],
      ),
      home: const SplashScreen(),
    );
  }
}
