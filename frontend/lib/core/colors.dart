import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme/oklch.dart';

const colorNames = [
  'BLACK', 'BLUE', 'BROWN', 'GRAY', 'GREEN', 'ORANGE',
  'PINK', 'PURPLE', 'RED', 'WHITE', 'YELLOW',
];

const colorLabels = {
  'BLACK': 'Noir',
  'BLUE': 'Bleu',
  'BROWN': 'Marron',
  'GRAY': 'Gris',
  'GREEN': 'Vert',
  'ORANGE': 'Orange',
  'PINK': 'Rose',
  'PURPLE': 'Violet',
  'RED': 'Rouge',
  'WHITE': 'Blanc',
  'YELLOW': 'Jaune',
};

class LabelTone {
  final Color solid;
  final Color background;
  final Color text;

  const LabelTone({required this.solid, required this.background, required this.text});
}


const Map<String, (double, double, double)> _tones = {
  'BLACK': (0.28, 0.01, 90.0),
  'BROWN': (0.40, 0.07, 60.0),
  'BLUE': (0.50, 0.17, 255.0),
  'GRAY': (0.50, 0.01, 90.0),
  'RED': (0.58, 0.21, 27.0),
  'PURPLE': (0.64, 0.17, 305.0),
  'GREEN': (0.66, 0.14, 165.0),
  'PINK': (0.74, 0.13, 350.0),
  'ORANGE': (0.78, 0.16, 62.0),
  'YELLOW': (0.90, 0.16, 100.0),
  'WHITE': (0.96, 0.005, 90.0),
};


LabelTone labelTone(String? name, Brightness brightness) {
  final (l, c, h) = _tones[name] ?? (0.60, 0.01, 90.0);
  if (brightness == Brightness.light) {
    return LabelTone(
      solid: oklch(l, c, h),
      background: oklch(0.95, math.min(c, 0.06), h),
      text: oklch(0.47, c * 0.85, h),
    );
  }
  final solid = oklch(0.25 + l * 0.68, c * 0.9, h);
  return LabelTone(
    solid: solid,
    background: solid.withValues(alpha: 0.18),
    text: oklch(0.82, c * 0.75, h),
  );
}

final transferTone = LabelTone(
  solid: oklch(0.87, 0.18, 95),
  background: oklch(0.87, 0.18, 95),
  text: const Color(0xFF1C1A17),
);

Color colorFromName(String? name) => labelTone(name, Brightness.light).solid;