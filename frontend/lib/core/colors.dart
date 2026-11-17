import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme/oklch.dart';

const colorNames = [
  'BLACK', 'BLUE', 'BROWN', 'GRAY', 'GREEN', 'ORANGE',
  'PINK', 'PURPLE', 'RED', 'WHITE', 'YELLOW',
];

class LabelTone {
  final Color solid;
  final Color background;
  final Color text;

  const LabelTone({required this.solid, required this.background, required this.text});
}

const Map<String, (double, double, double)> _tones = {
  'ORANGE': (0.66, 0.18, 45.0),
  'BLUE': (0.55, 0.17, 255.0),
  'GREEN': (0.60, 0.15, 150.0),
  'PURPLE': (0.52, 0.20, 305.0),
  'YELLOW': (0.76, 0.15, 85.0),
  'PINK': (0.60, 0.20, 350.0),
  'RED': (0.55, 0.22, 28.0),
  'BROWN': (0.50, 0.08, 55.0),
  'GRAY': (0.60, 0.01, 90.0),
  'BLACK': (0.30, 0.01, 90.0),
  'WHITE': (0.85, 0.01, 90.0),
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
  final solid = oklch(0.75, c * 0.9, h);
  return LabelTone(
    solid: solid,
    background: solid.withValues(alpha: 0.18),
    text: oklch(0.82, c * 0.75, h),
  );
}

Color colorFromName(String? name) => labelTone(name, Brightness.light).solid;