import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import 'name_color_dialog.dart';
import 'references_repository.dart';

class BanksScreen extends ConsumerWidget {
  const BanksScreen({super.key});

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [Bank? bank]) async {
    final result = await showNameColorDialog(
      context,
      title: bank == null ? 'Nouvelle banque' : 'Modifier la banque',
      initialName: bank?.name,
      initialColor: bank?.color ?? 'WHITE',
    );
    if (result == null) return;
    try {
      await ref.read(referencesRepositoryProvider).saveBank(
        id: bank?.id,
        name: result.name,
        color: result.color,
      );
      ref.invalidate(banksProvider);
    } on DioException {
      if (context.mounted) _showError(context, "Impossible d'enregistrer la banque");
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Bank bank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${bank.name} » ?'),
        content: const Text('Cette action est définitive.'),
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
      await ref.read(referencesRepositoryProvider).deleteBank(bank.id);
      ref.invalidate(banksProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      _showError(
        context,
        e.response?.statusCode == 409
          ? "Cette banque possède encore des comptes : archive la plutôt que de la supprimer"
          : 'Impossible de supprimer la banque',
      );
    }
  }

  Future<void> _toggleArchived(BuildContext context, WidgetRef ref, Bank bank) async {
    try {
      await ref.read(referencesRepositoryProvider).setBankArchived(bank.id, !bank.archived);
      ref.invalidate(banksProvider);
    } on DioException {
      if (context.mounted) _showError(context, "Impossible de modifier l'archivage");
    }
  }

  Widget _tile(BuildContext context, WidgetRef ref, Bank b) {
    return ListTile(
      leading: CircleAvatar(radius: 12, backgroundColor: colorFromName(b.color)),
      title: Text(b.name),
      enabled: !b.archived,
      onTap: () => _edit(context, ref, b),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: b.archived ? 'Désarchiver' : 'Archiver',
            icon: Icon(b.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
            onPressed: () => _toggleArchived(context, ref, b),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref, b),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(banksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Banques')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        child: const Icon(Icons.add),
      ),
      body: banks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune banque'));
          }
          final active = list.where((b) => !b.archived).toList();
          final archived = list.where((b) => b.archived).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (active.isEmpty)
                const ListTile(title: Text('Aucune banque active')),
              for (final b in active) _tile(context, ref, b),
              if (archived.isNotEmpty)
                ExpansionTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text('Archivées (${archived.length})'),
                  children: [
                    for (final b in archived) _tile(context, ref, b),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}