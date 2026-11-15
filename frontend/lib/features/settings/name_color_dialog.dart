import 'package:flutter/material.dart';

import '../../core/colors.dart';

Future<({String name, String color})?> showNameColorDialog(
  BuildContext context, {
  required String title,
  String? initialName,
  String initialColor = 'WHITE',
}) {
  return showDialog<({String name, String color})>(
    context: context,
    builder: (_) => _NameColorDialog(
      title: title,
      initialName: initialName,
      initialColor: initialColor,
    ),
  );
}

class _NameColorDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String initialColor;

  const _NameColorDialog({
    required this.title,
    this.initialName,
    required this.initialColor,
  });

  @override
  State<_NameColorDialog> createState() => _NameColorDialogState();
}

class _NameColorDialogState extends State<_NameColorDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late String _color = widget.initialColor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in colorNames) _ColorDot(
                color: colorFromName(c),
                selected: _color == c,
                onTap: () => setState(() => _color = c),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 17,
        backgroundColor: Theme.of(context).colorScheme.outline,
        child: CircleAvatar(
          radius: 15,
          backgroundColor: color,
          child: selected
            ? Icon(Icons.check, size: 18, color: dark ? Colors.white : Colors.black)
            : null,
        ),
      ),
    );
  }
}