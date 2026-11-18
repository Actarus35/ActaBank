import 'package:flutter/material.dart';

import '../colors.dart';

class ToneChip extends StatelessWidget {
  final String label;
  final String? colorName;
  final bool dot;

  const ToneChip({super.key, required this.label, this.colorName, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final tone = labelTone(colorName, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tone.solid, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: tone.text),
          ),
        ],
      ),
    );
  }
}