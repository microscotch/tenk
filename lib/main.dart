import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/setup_screen.dart';

void main() {
  runApp(const ProviderScope(child: Le10000App()));
}

class Le10000App extends StatelessWidget {
  const Le10000App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le 10000',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      home: const SetupScreen(),
    );
  }
}
