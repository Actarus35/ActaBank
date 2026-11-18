import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'oklch.dart';

enum AccentColor {
  orange(45),
  blue(255),
  green(155),
  purple(305),
  pink(350),
  teal(200);

  const AccentColor(this.hue);

  final double hue;

  Color main(Brightness b) =>
      b == Brightness.light ? oklch(0.6, 0.17, hue) : oklch(0.72, 0.16, hue);

  Color deep(Brightness b) =>
      b == Brightness.light ? oklch(0.52, 0.18, hue - 12) : oklch(0.63, 0.17, hue - 12);
}

ThemeData buildTheme(Brightness brightness, AccentColor accentColor) {
  final palette = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
  final accent = accentColor.main(brightness);

  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
    primary: accent,
    onPrimary: Colors.white,
    secondary: accentColor.deep(brightness),
    onSecondary: Colors.white,
    surface: palette.card,
    onSurface: palette.ink,
    onSurfaceVariant: palette.muted,
    surfaceContainerHighest: palette.soft,
    outline: palette.border,
    outlineVariant: palette.border,
    error: palette.neg,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final r11 = BorderRadius.circular(11);

  return base.copyWith(
    scaffoldBackgroundColor: palette.page,
    textTheme: GoogleFonts.fredokaTextTheme(base.textTheme),
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.page,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: palette.page,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      border: OutlineInputBorder(borderRadius: r11, borderSide: BorderSide(color: palette.border)),
      enabledBorder: OutlineInputBorder(borderRadius: r11, borderSide: BorderSide(color: palette.border)),
      focusedBorder: OutlineInputBorder(borderRadius: r11, borderSide: BorderSide(color: accent)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: const ChipThemeData(shape: StadiumBorder(), side: BorderSide.none),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.card,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : palette.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? accent : palette.muted,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.card,
      showDragHandle: true,
      dragHandleColor: palette.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.border, space: 1),
  );
}