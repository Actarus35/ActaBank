import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/section_card.dart';
import '../settings/references_repository.dart';
import '../settings/settings_actions.dart';
import '../transactions/transactions_repository.dart';
import 'recurring_form_screen.dart';
import 'recurring_repository.dart';

class RecurringCard extends ConsumerWidget {
  const RecurringCard({super.key});

  /// Créer ou modifier une règle peut générer des transactions côté serveur :
  /// on recharge donc aussi la liste des transactions.
  void _refresh(WidgetRef ref) {
    ref.invalidate(recurringProvider);
    ref.invalidate(transactionsProvider);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    RecurringTransaction? rule,
    bool expense = true,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecurringFormScreen(rule: rule, initialExpense: expense)),
    );
    if (context.mounted) _refresh(ref);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, RecurringTransaction r) async {
    final confirmed = await confirmDelete(
      context,
      name: r.name,
      content: 'Les transactions déjà créées seront conservées.',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(recurringRepositoryProvider).delete(r.id);
      _refresh(ref);
    } on DioException {
      if (context.mounted) showError(context, 'Impossible de supprimer le paiement récurrent');
    }
  }

  static int _byNextDate(RecurringTransaction a, RecurringTransaction b) {
    if (a.nextDate == null) return b.nextDate == null ? 0 : 1;
    if (b.nextDate == null) return -1;
    return a.nextDate!.compareTo(b.nextDate!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider);
    final categories = {
      for (final c in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c,
    };
    final methods = {
      for (final m in ref.watch(transactionMethodsProvider).valueOrNull ?? const <TransactionMethod>[]) m.id: m,
    };
    final palette = context.palette;

    Widget section(String label, Color dot, List<RecurringTransaction> items, bool expense, String addLabel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: palette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in items)
            _RecurringRow(
              rule: r,
              category: categories[r.categoryId],
              method: methods[r.methodId],
              onTap: () => _open(context, ref, rule: r),
              onDelete: () => _delete(context, ref, r),
            ),
          _AddButton(label: addLabel, onTap: () => _open(context, ref, expense: expense)),
        ],
      );
    }

    return SectionCard(
      title: '↻ Paiements récurrents',
      child: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (list) {
          final expenses = list.where((r) => r.amount < 0).toList()..sort(_byNextDate);
          final incomes = list.where((r) => r.amount > 0).toList()..sort(_byNextDate);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section('Dépenses récurrentes', palette.neg, expenses, true, '+ Ajouter une dépense récurrente'),
              const SizedBox(height: 16),
              section('Revenus récurrents', palette.pos, incomes, false, '+ Ajouter un revenu récurrent'),
            ],
          );
        },
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  final RecurringTransaction rule;
  final Category? category;
  final TransactionMethod? method;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecurringRow({
    required this.rule,
    this.category,
    this.method,
    required this.onTap,
    required this.onDelete,
  });

  String get _status {
    if (method?.archived ?? false) return 'suspendu';
    final next = rule.nextDate;
    return next == null ? 'terminé' : 'prochain ${formatShortDate(next)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = labelTone(category?.color, Theme.of(context).brightness);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.border),
    );
    final subtitle = [
      frequencyShortLabels[rule.frequency] ?? rule.frequency,
      _status,
      ?method?.displayName,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.page,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rule.name.characters.first.toUpperCase(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tone.text),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatAmount(rule.amount, signed: true),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: rule.amount > 0 ? palette.pos : palette.neg,
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: Icon(Icons.delete_outline, size: 18, color: palette.muted),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.border, width: 1.5),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}