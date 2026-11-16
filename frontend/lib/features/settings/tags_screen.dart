import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import 'name_color_dialog.dart';
import 'references_repository.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [Tag? tag]) async {
    final result = await showNameColorDialog(
      context,
      title: tag == null ? 'Nouveau tag' : 'Modifier le tag',
      initialName: tag?.name,
      initialColor: tag?.color ?? 'WHITE',
    );
    if (result == null) return;
    try {
      await ref.read(referencesRepositoryProvider).saveTag(
        id: tag?.id,
        name: result.name,
        color: result.color,
      );
      ref.invalidate(tagsProvider);
    } on DioException {
      if (context.mounted) _showError(context, "Impossible d'enregistrer le tag");
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${tag.name} » ?'),
        content: const Text('Les transactions concernées seront conservées, sans tag.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(referencesRepositoryProvider).deleteTag(tag.id);
      ref.invalidate(tagsProvider);
    } on DioException {
      if (context.mounted) _showError(context, 'Impossible de supprimer le tag');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tags.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun tag'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              return ListTile(
                leading: CircleAvatar(radius: 12, backgroundColor: colorFromName(c.color)),
                title: Text(c.name),
                onTap: () => _edit(context, ref, c),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}