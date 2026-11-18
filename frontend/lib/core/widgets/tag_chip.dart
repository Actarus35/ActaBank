import 'package:flutter/material.dart';

import '../colors.dart';
import '../theme/app_palette.dart';

class TagChip extends StatelessWidget {
  final String label;
  final String? colorName;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.label,
    this.colorName,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = labelTone(colorName, Theme.of(context).brightness);
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? tone.solid : tone.solid.withValues(alpha: 0.45),
        width: 1.5,
      ),
    );

    return Material(
      color: selected ? tone.background : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check_rounded : Icons.sell_outlined, size: 13, color: tone.solid),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? tone.text : palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}