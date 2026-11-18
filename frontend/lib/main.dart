import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ActabankApp(),
  ));
}

class ActabankApp extends ConsumerWidget {
  const ActabankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'ActaBank',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, settings.accent),
      darkTheme: buildTheme(Brightness.dark, settings.accent),
      themeMode: settings.mode,
      home: const AuthGate(),
    );
  }
}