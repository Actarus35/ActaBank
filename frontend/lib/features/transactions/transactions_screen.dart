import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/colors.dart';
import 'transaction_form_screen.dart';
import 'transactions_repository.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune transaction'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return ListTile(
                title: Text(t.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatDate(t.date)} · ${t.categoryName ?? 'Sans catégorie'}'),
                    if (t.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 96),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            for (final tag in t.tags)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 4, backgroundColor: colorFromName(tag.color)),
                                  const SizedBox(width: 4),
                                  Text(tag.name, style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  formatAmount(t.amount, signed: true),
                  style: TextStyle(
                    color: t.amount < 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionFormScreen(transaction: t),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}