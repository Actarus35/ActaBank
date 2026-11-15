import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import 'name_color_dialog.dart';
import 'references_repository.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [Category? category]) async {
    final result = await showNameColorDialog(
      context,
      title: category == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
      initialName: category?.name,
      initialColor: category?.color ?? 'WHITE',
    );
    if (result == null) return;
    try {
      await ref.read(referencesRepositoryProvider).saveCategory(
        id: category?.id,
        name: result.name,
        color: result.color,
      );
      ref.invalidate(categoriesProvider);
    } on DioException {
      if (context.mounted) _showError(context, "Impossible d'enregistrer la catégorie");
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${category.name} » ?'),
        content: const Text('Les transactions concernées seront conservées, sans catégorie.'),
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
      await ref.read(referencesRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoriesProvider);
    } on DioException {
      if (context.mounted) _showError(context, 'Impossible de supprimer la catégorie');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune catégorie'));
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