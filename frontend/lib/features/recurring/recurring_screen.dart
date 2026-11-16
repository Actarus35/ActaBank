import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import 'recurring_form_screen.dart';
import 'recurring_repository.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Récurrences')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune récurrence'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(r.name),
                subtitle: Text('${r.frequencyLabel} · depuis le ${formatDate(r.startDate)}'),
                trailing: Text(
                  '${r.amount.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: r.amount < 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RecurringFormScreen(rule: r)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}