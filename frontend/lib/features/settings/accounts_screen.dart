import 'package:actabank/features/settings/accounts_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'references_repository.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(BuildContext context, [Account? account]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountFormScreen(account: account)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${account.name} » ?'),
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
      await ref.read(referencesRepositoryProvider).deleteAccount(account.id);
      ref.invalidate(accountsProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      _showError(
        context,
        e.response?.statusCode == 409
          ? "Ce compte possède encore des moyens de paiement : supprime-les d'abord"
          : 'Impossible de supprimer le compte',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(context),
        child: const Icon(Icons.add),
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun compte'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(a.name),
                subtitle: Text('${a.bankName ?? '—'} · ${a.typeLabel}'),
                onTap: () => _open(context, a),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, a),
                ),
              );
            },
          );
        },
      ),
    );
  }
}