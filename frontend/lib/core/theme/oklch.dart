import 'dart:math' as math;

import 'package:flutter/painting.dart';

Color oklch(double l, double c, double h, [double alpha = 1]) {
  final hr = h * math.pi / 180;
  final a = c * math.cos(hr);
  final b = c * math.sin(hr);

  final l1 = l + 0.3963377774 * a + 0.2158037573 * b;
  final m1 = l - 0.1055613458 * a - 0.0638541728 * b;
  final s1 = l - 0.0894841775 * a - 1.2914855480 * b;
  final ll = l1 * l1 * l1;
  final mm = m1 * m1 * m1;
  final ss = s1 * s1 * s1;

  double toSrgb(double x) {
    final v = x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
    return v.clamp(0.0, 1.0).toDouble();
  }

  return Color.from(
    alpha: alpha,
    red: toSrgb(4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss),
    green: toSrgb(-1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss),
    blue: toSrgb(-0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss),
  );
}