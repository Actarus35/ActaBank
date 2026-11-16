import 'package:actabank/features/settings/method_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'references_repository.dart';

class MethodsScreen extends ConsumerWidget {
  const MethodsScreen({super.key});

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(BuildContext context, [TransactionMethod? method]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MethodFormScreen(method: method)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TransactionMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${method.typeLabel} » ?'),
        content: const Text('Cette action est définitive'),
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
      await ref.read(referencesRepositoryProvider).deleteMethod(method.id);
      ref.invalidate(transactionMethodsProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      _showError(
        context,
        e.response?.statusCode == 409
          ? "Ce moyen de paiement est utilisé par des transactions récurrentes"
          : 'Impossible de supprimer le moyen de paiement',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(transactionMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moyens de paiement')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(context),
        child: const Icon(Icons.add),
      ),
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun moyen de paiement'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final m = list[i];
              return ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text(m.typeLabel),
                subtitle: Text('${m.accountName ?? 'Aucun Compte'} · ${m.typeLabel}'),
                onTap: () => _open(context, m),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, m),
                ),
              );
            },
          );
        },
      ),
    );
  }
}