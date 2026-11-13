import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_gate.dart';

void main() {
  runApp(const ProviderScope(child: ActabankApp()));
}

class ActabankApp extends StatelessWidget {
  const ActabankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ActaBank',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}