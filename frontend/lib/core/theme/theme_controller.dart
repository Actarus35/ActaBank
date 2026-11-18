import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Fourni dans main()'),
);

class ThemeSettings {
  final ThemeMode mode;
  final AccentColor accent;

  const ThemeSettings({required this.mode, required this.accent});
}

class ThemeController extends Notifier<ThemeSettings> {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';

  @override
  ThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final modeName = prefs.getString(_modeKey);
    final accentName = prefs.getString(_accentKey);
    return ThemeSettings(
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => ThemeMode.system,
      ),
      accent: AccentColor.values.firstWhere(
        (a) => a.name == accentName,
        orElse: () => AccentColor.orange,
      ),
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = ThemeSettings(mode: mode, accent: state.accent);
    await ref.read(sharedPreferencesProvider).setString(_modeKey, mode.name);
  }

  Future<void> setAccent(AccentColor accent) async {
    state = ThemeSettings(mode: state.mode, accent: accent);
    await ref.read(sharedPreferencesProvider).setString(_accentKey, accent.name);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);