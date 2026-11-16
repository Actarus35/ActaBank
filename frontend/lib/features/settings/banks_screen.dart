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
          ? "Cette banque possède encore des comptes : supprime-les d'abord"
          : 'Impossible de supprimer la banque',
      );
    }
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