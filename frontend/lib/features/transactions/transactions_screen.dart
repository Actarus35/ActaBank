import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/pill_segmented.dart';
import '../../core/widgets/tone_chip.dart';
import 'transaction_form_screen.dart';
import 'transactions_repository.dart';

enum _Filter { all, expenses, income }

/// Une ligne de la liste : soit un en-tête de jour, soit une transaction.
sealed class _Row {}

class _HeaderRow extends _Row {
  final DateTime day;
  _HeaderRow(this.day);
}

class _TransactionRow extends _Row {
  final Transaction transaction;
  _TransactionRow(this.transaction);
}

List<_Row> _groupByDay(List<Transaction> list) {
  final rows = <_Row>[];
  DateTime? current;
  for (final t in list) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (day != current) {
      rows.add(_HeaderRow(day));
      current = day;
    }
    rows.add(_TransactionRow(t));
  }
  return rows;
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _Filter _filter = _Filter.all;

  bool _keep(Transaction t) => switch (_filter) {
    _Filter.all => true,
    _Filter.expenses => t.amount < 0,
    _Filter.income => t.amount > 0,
  };

  String get _emptyText => switch (_filter) {
    _Filter.all => 'Aucune transaction',
    _Filter.expenses => 'Aucune dépense',
    _Filter.income => 'Aucun revenu',
  };

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final palette = context.palette;
    final wide = isWide(context);

    final title = Text(
      'Transactions',
      style: TextStyle(fontSize: wide ? 20 : 19, fontWeight: FontWeight.w600, color: palette.ink),
    );
    final filter = PillSegmented<_Filter>(
      options: const [
        (_Filter.all, 'Tout'),
        (_Filter.expenses, 'Dépenses'),
        (_Filter.income, 'Revenus'),
      ],
      selected: _filter,
      expand: !wide,
      onChanged: (f) => setState(() => _filter = f),
    );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 12, wide ? 24 : 16, wide ? 20 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(children: [Expanded(child: title), filter])
            else ...[
              title,
              const SizedBox(height: 10),
              filter,
            ],
            const SizedBox(height: 14),
            Expanded(
              child: transactions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (all) {
                  final rows = _groupByDay(all.where(_keep).toList());
                  if (rows.isEmpty) {
                    return Center(child: Text(_emptyText, style: TextStyle(color: palette.muted)));
                  }
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: wide ? 0 : 88),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => switch (rows[i]) {
                        _HeaderRow(:final day) => _DayHeader(day: day),
                        _TransactionRow(:final transaction) => _TransactionTile(transaction: transaction),
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;

  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      color: palette.soft,
      padding: EdgeInsets.symmetric(horizontal: isWide(context) ? 18 : 16, vertical: 9),
      child: Text(
        formatDayHeader(day),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.55,
          color: palette.muted,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;
    final wide = isWide(context);
    final tone = labelTone(t.categoryColor, brightness);
    final category = t.categoryName ?? 'Sans catégorie';

    final amount = Text(
      formatAmount(t.amount, signed: true),
      style: TextStyle(
        fontSize: wide ? 15 : 14,
        fontWeight: FontWeight.w600,
        color: t.amount > 0 ? palette.pos : palette.neg,
      ),
    );

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TransactionFormScreen(transaction: t)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 16, vertical: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: palette.border))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                t.name.characters.first.toUpperCase(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tone.text),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: wide ? 14 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      if (t.recurring) ...[
                        const SizedBox(width: 7),
                        const _RecurringBadge(),
                      ],
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: t.subtitle),
                        for (final tag in t.tags)
                          TextSpan(
                            text: '  #${tag.name}',
                            style: TextStyle(
                              color: labelTone(tag.color, brightness).text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: wide ? 12 : 11, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (wide) ...[
              ToneChip(label: category, colorName: t.categoryColor),
              const SizedBox(width: 14),
              SizedBox(width: 104, child: Align(alignment: Alignment.centerRight, child: amount)),
            ] else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  amount,
                  Text(
                    category,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: tone.text),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RecurringBadge extends StatelessWidget {
  const _RecurringBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: 'Transaction récurrente',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '↻',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.muted),
        ),
      ),
    );
  }
}