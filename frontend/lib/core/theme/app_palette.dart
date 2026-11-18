import 'package:flutter/material.dart';

import 'oklch.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color page;
  final Color card;
  final Color ink;
  final Color muted;
  final Color border;
  final Color soft;
  final Color pos;
  final Color posBg;
  final Color posText;
  final Color posBar;
  final Color neg;
  final Color negBg;
  final Color negBar;

  const AppPalette({
    required this.page,
    required this.card,
    required this.ink,
    required this.muted,
    required this.border,
    required this.soft,
    required this.pos,
    required this.posBg,
    required this.posText,
    required this.posBar,
    required this.neg,
    required this.negBg,
    required this.negBar,
  });

  static final light = AppPalette(
    page: const Color(0xFFFAF7F2),
    card: const Color(0xFFFFFFFF),
    ink: const Color(0xFF1C1A17),
    muted: const Color(0xFF8A847A),
    border: const Color(0x12000000),
    soft: const Color(0xFFF0EDE8),
    pos: oklch(0.56, 0.15, 150),
    posBg: oklch(0.94, 0.06, 150),
    posText: oklch(0.48, 0.14, 150),
    posBar: oklch(0.76, 0.15, 150),
    neg: oklch(0.55, 0.23, 28),
    negBg: oklch(0.95, 0.07, 28),
    negBar: oklch(0.58, 0.24, 28),
  );

  static final dark = AppPalette(
    page: const Color(0xFF17181C),
    card: const Color(0xFF1E2026),
    ink: const Color(0xFFF2F0EC),
    muted: const Color(0xFF8B8E97),
    border: const Color(0x0FFFFFFF),
    soft: const Color(0xFF2A2D34),
    pos: oklch(0.8, 0.15, 150),
    posBg: oklch(0.8, 0.15, 150, 0.16),
    posText: oklch(0.84, 0.13, 150),
    posBar: oklch(0.82, 0.15, 150),
    neg: oklch(0.68, 0.22, 28),
    negBg: oklch(0.68, 0.22, 28, 0.16),
    negBar: oklch(0.7, 0.23, 28),
  );

  @override
  AppPalette copyWith({
    Color? page,
    Color? card,
    Color? ink,
    Color? muted,
    Color? border,
    Color? soft,
    Color? pos,
    Color? posBg,
    Color? posText,
    Color? posBar,
    Color? neg,
    Color? negBg,
    Color? negBar,
  }) {
    return AppPalette(
      page: page ?? this.page,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      soft: soft ?? this.soft,
      pos: pos ?? this.pos,
      posBg: posBg ?? this.posBg,
      posText: posText ?? this.posText,
      posBar: posBar ?? this.posBar,
      neg: neg ?? this.neg,
      negBg: negBg ?? this.negBg,
      negBar: negBar ?? this.negBar,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      page: mix(page, other.page),
      card: mix(card, other.card),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      soft: mix(soft, other.soft),
      pos: mix(pos, other.pos),
      posBg: mix(posBg, other.posBg),
      posText: mix(posText, other.posText),
      posBar: mix(posBar, other.posBar),
      neg: mix(neg, other.neg),
      negBg: mix(negBg, other.negBg),
      negBar: mix(negBar, other.negBar),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}