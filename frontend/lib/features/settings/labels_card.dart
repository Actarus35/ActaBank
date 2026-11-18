import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/section_card.dart';
import 'name_color_dialog.dart';
import 'references_repository.dart';
import 'settings_actions.dart';

typedef LabelItem = ({int id, String name, String color});
typedef SaveLabel = Future<void> Function({int? id, required String name, required String color});

class CategoriesCard extends ConsumerWidget {
  const CategoriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(referencesRepositoryProvider);
    return _LabelsCard(
      title: '🗂️ Catégories',
      hint: 'Nouvelle catégorie…',
      noun: 'la catégorie',
      deleteMessage: 'Les transactions concernées seront conservées, sans catégorie.',
      items: ref.watch(categoriesProvider).whenData(
        (list) => [for (final c in list) (id: c.id, name: c.name, color: c.color)],
      ),
      save: repo.saveCategory,
      delete: repo.deleteCategory,
      refresh: () => ref.invalidate(categoriesProvider),
    );
  }
}

class TagsCard extends ConsumerWidget {
  const TagsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(referencesRepositoryProvider);
    return _LabelsCard(
      title: '🏷️ Tags',
      hint: 'Nouveau tag…',
      noun: 'le tag',
      deleteMessage: 'Le tag sera retiré des transactions, qui seront conservées.',
      outlined: true,
      items: ref.watch(tagsProvider).whenData(
        (list) => [for (final t in list) (id: t.id, name: t.name, color: t.color)],
      ),
      save: repo.saveTag,
      delete: repo.deleteTag,
      refresh: () => ref.invalidate(tagsProvider),
    );
  }
}

class _LabelsCard extends StatefulWidget {
  final String title;
  final String hint;
  final String noun;
  final String deleteMessage;
  final bool outlined;
  final AsyncValue<List<LabelItem>> items;
  final SaveLabel save;
  final Future<void> Function(int id) delete;
  final VoidCallback refresh;

  const _LabelsCard({
    required this.title,
    required this.hint,
    required this.noun,
    required this.deleteMessage,
    this.outlined = false,
    required this.items,
    required this.save,
    required this.delete,
    required this.refresh,
  });

  @override
  State<_LabelsCard> createState() => _LabelsCardState();
}

class _LabelsCardState extends State<_LabelsCard> {
  static const _suggested = ['BLUE', 'ORANGE', 'GREEN', 'PURPLE', 'PINK', 'YELLOW', 'RED', 'BROWN', 'GRAY'];

  final _name = TextEditingController();
  String? _color;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _nextColor(List<LabelItem> items) {
    final used = {for (final i in items) i.color};
    return _suggested.firstWhere((c) => !used.contains(c), orElse: () => 'GRAY');
  }

  /// Lance une requête, recharge la liste, affiche l'erreur éventuelle.
  /// Renvoie true si tout s'est bien passé.
  Future<bool> _run(Future<void> Function() action, String error) async {
    setState(() => _busy = true);
    var ok = true;
    try {
      await action();
      widget.refresh();
    } on DioException {
      ok = false;
      if (mounted) showError(context, error);
    }
    if (mounted) setState(() => _busy = false);
    return ok;
  }

  Future<void> _add(List<LabelItem> items) async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    final color = _color ?? _nextColor(items);
    final ok = await _run(
      () => widget.save(name: name, color: color),
      "Impossible d'ajouter ${widget.noun}",
    );
    if (ok && mounted) {
      setState(() {
        _name.clear();
        _color = null;
      });
    }
  }

  Future<void> _edit(LabelItem item) async {
    final result = await showNameColorDialog(
      context,
      title: 'Modifier ${widget.noun}',
      initialName: item.name,
      initialColor: item.color,
    );
    if (result == null || !mounted) return;
    await _run(
      () => widget.save(id: item.id, name: result.name, color: result.color),
      "Impossible de modifier ${widget.noun}",
    );
  }

  Future<void> _delete(LabelItem item) async {
    if (!await confirmDelete(context, name: item.name, content: widget.deleteMessage) || !mounted) return;
    await _run(() => widget.delete(item.id), 'Impossible de supprimer ${widget.noun}');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SectionCard(
      title: widget.title,
      child: widget.items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (items) {
          final color = _color ?? _nextColor(items);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                Text("Aucun élément pour l'instant", style: TextStyle(color: palette.muted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in items)
                      _LabelChip(
                        item: i,
                        outlined: widget.outlined,
                        onTap: () => _edit(i),
                        onDelete: () => _delete(i),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    _ColorPicker(
                      selected: color,
                      onSelected: (c) => setState(() => _color = c),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        onSubmitted: (_) => _add(items),
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          filled: false,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _add(items),
                      child: const Text('+ Ajouter'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final LabelItem item;
  final bool outlined;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LabelChip({
    required this.item,
    required this.outlined,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = labelTone(item.color, Theme.of(context).brightness);
    final shape = StadiumBorder(
      side: outlined
        ? BorderSide(color: tone.solid.withValues(alpha: 0.45), width: 1.5)
        : BorderSide.none,
    );
    final textColor = outlined ? palette.ink : tone.text;

    return Material(
      color: outlined ? Colors.transparent : tone.background,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (outlined)
                Icon(Icons.sell_outlined, size: 13, color: tone.solid)
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: tone.solid, shape: BoxShape.circle),
                ),
              const SizedBox(width: 7),
              Text(
                item.name,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: 'Supprimer',
                child: InkResponse(
                  onTap: onDelete,
                  radius: 14,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: textColor.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    Widget dot(String c, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: labelTone(c, brightness).solid,
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.border),
      ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Couleur : ${colorLabels[selected]}',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final c in colorNames)
          PopupMenuItem(
            value: c,
            child: Row(
              children: [
                dot(c, 14),
                const SizedBox(width: 10),
                Expanded(child: Text(colorLabels[c]!)),
                if (c == selected) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: dot(selected, 18),
      ),
    );
  }
}