import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/stats_repository.dart';
import 'accounts_form_screen.dart';
import 'name_color_dialog.dart';
import 'references_repository.dart';
import 'method_form_screen.dart';

void showError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String name,
  String content = 'Cette action est définitive.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Supprimer « $name » ?'),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
      ],
    ),
  );
  return confirmed == true;
}

/// Archiver une banque archive ses comptes, et un compte ses moyens de paiement :
/// on recharge donc toute la chaîne, ainsi que les soldes.
void refreshBanking(WidgetRef ref) {
  ref.invalidate(banksProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(transactionMethodsProvider);
  ref.invalidate(balancesProvider);
}

Future<void> editBank(BuildContext context, WidgetRef ref, [Bank? bank]) async {
  final result = await showNameColorDialog(
    context,
    title: bank == null ? 'Nouvelle banque' : 'Modifier la banque',
    initialName: bank?.name,
    initialColor: bank?.color ?? 'WHITE',
  );
  if (result == null || !context.mounted) return;
  try {
    await ref.read(referencesRepositoryProvider).saveBank(id: bank?.id, name: result.name, color: result.color);
    refreshBanking(ref);
  } on DioException {
    if (context.mounted) showError(context, "Impossible d'enregistrer la banque");
  }
}

Future<void> deleteBank(BuildContext context, WidgetRef ref, Bank bank) async {
  if (!await confirmDelete(context, name: bank.name) || !context.mounted) return;
  try {
    await ref.read(referencesRepositoryProvider).deleteBank(bank.id);
    refreshBanking(ref);
  } on DioException catch (e) {
    if (!context.mounted) return;
    showError(
      context,
      e.response?.statusCode == 409
        ? 'Cette banque possède encore des comptes : archive-la plutôt que de la supprimer'
        : 'Impossible de supprimer la banque',
    );
  }
}

Future<void> toggleBankArchived(BuildContext context, WidgetRef ref, Bank bank) async {
  try {
    await ref.read(referencesRepositoryProvider).setBankArchived(bank.id, !bank.archived);
    refreshBanking(ref);
  } on DioException {
    if (context.mounted) showError(context, "Impossible de modifier l'archivage");
  }
}

Future<void> openAccountForm(
  BuildContext context,
  WidgetRef ref, {
  Account? account,
  int? bankId,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AccountFormScreen(account: account, initialBankId: bankId)),
  );
  if (context.mounted) refreshBanking(ref);
}

Future<void> deleteAccount(BuildContext context, WidgetRef ref, Account account) async {
  if (!await confirmDelete(context, name: account.name) || !context.mounted) return;
  try {
    await ref.read(referencesRepositoryProvider).deleteAccount(account.id);
    refreshBanking(ref);
  } on DioException catch (e) {
    if (!context.mounted) return;
    showError(
      context,
      e.response?.statusCode == 409
        ? 'Ce compte possède encore des moyens de paiement ou des transferts : archive-le plutôt que de le supprimer'
        : 'Impossible de supprimer le compte',
    );
  }
}

Future<void> toggleAccountArchived(BuildContext context, WidgetRef ref, Account account) async {
  try {
    await ref.read(referencesRepositoryProvider).setAccountArchived(account.id, !account.archived);
    refreshBanking(ref);
  } on DioException {
    if (context.mounted) showError(context, "Impossible de modifier l'archivage");
  }
}

Future<void> openMethodForm(BuildContext context, WidgetRef ref, {TransactionMethod? method}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MethodFormScreen(method: method)),
  );
  if (context.mounted) ref.invalidate(transactionMethodsProvider);
}

Future<void> deleteMethod(BuildContext context, WidgetRef ref, TransactionMethod method) async {
  if (!await confirmDelete(context, name: method.displayName) || !context.mounted) return;
  try {
    await ref.read(referencesRepositoryProvider).deleteMethod(method.id);
    ref.invalidate(transactionMethodsProvider);
  } on DioException catch (e) {
    if (!context.mounted) return;
    showError(
      context,
      e.response?.statusCode == 409
        ? 'Ce moyen de paiement est encore utilisé : archive-le plutôt que de le supprimer'
        : 'Impossible de supprimer le moyen de paiement',
    );
  }
}

Future<void> toggleMethodArchived(BuildContext context, WidgetRef ref, TransactionMethod method) async {
  try {
    await ref.read(referencesRepositoryProvider).setMethodArchived(method.id, !method.archived);
    ref.invalidate(transactionMethodsProvider);
  } on DioException {
    if (context.mounted) showError(context, "Impossible de modifier l'archivage");
  }
}