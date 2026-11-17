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
          ? "Ce compte possède encore des moyens de paiement : archive le plutôt que de le supprimer"
          : 'Impossible de supprimer le compte',
      );
    }
  }

  Future<void> _toggleArchived(BuildContext context, WidgetRef ref, Account account) async {
    try {
      await ref.read(referencesRepositoryProvider).setAccountArchived(account.id, !account.archived);
      ref.invalidate(accountsProvider);
    } on DioException {
      if (context.mounted) _showError(context, "Impossible de modifier l'archivage");
    }
  }
  Widget _tile(BuildContext context, WidgetRef ref, Account a) {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(a.name),
      subtitle: Text('${a.bankName ?? 'Sans banque'} · ${a.typeLabel}'),
      enabled: !a.archived,
      onTap: () => _open(context, a),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: a.archived ? 'Désarchiver' : 'Archiver',
            icon: Icon(a.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
            onPressed: () => _toggleArchived(context, ref, a),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref, a),
          ),
        ],
      ),
    );
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
          final active = list.where((a) => !a.archived).toList();
          final archived = list.where((a) => a.archived).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (active.isEmpty)
                const ListTile(title: Text('Aucun compte actif')),
              for (final a in active) _tile(context, ref, a),
              if (archived.isNotEmpty)
                ExpansionTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text('Archivés (${archived.length})'),
                  children: [
                    for (final a in archived) _tile(context, ref, a),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}