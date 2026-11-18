import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/pill_segmented.dart';
import '../../core/widgets/tone_chip.dart';
import '../settings/references_repository.dart';
import 'transaction_form_screen.dart';
import 'transactions_repository.dart';

enum _Filter { all, expenses, income }

// Valeurs spéciales des menus de filtre. On ne peut pas utiliser null :
// PopupMenuButton considère une valeur null comme « menu fermé sans choix ».
const _all = -1;
const _none = -2;

/// Une ligne de la liste : soit un en-tête de jour, soit une transaction.
sealed class _Row {}

class _HeaderRow extends _Row {
  final DateTime day;
  double total = 0;
  _HeaderRow(this.day);
}

class _TransactionRow extends _Row {
  final Transaction transaction;
  _TransactionRow(this.transaction);
}

List<_Row> _groupByDay(List<Transaction> list) {
  final rows = <_Row>[];
  _HeaderRow? header;
  for (final t in list) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (header == null || header.day != day) {
      header = _HeaderRow(day);
      rows.add(header);
    }
    header.total += t.amount;
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
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;
  int _category = _all;
  int _tag = _all;
  int _account = _all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
    _search.text.trim().isNotEmpty || _category != _all || _tag != _all || _account != _all;

  void _clearFilters() => setState(() {
    _search.clear();
    _category = _all;
    _tag = _all;
    _account = _all;
  });

  static bool _matches(int filter, int? value) =>
    filter == _all || (filter == _none ? value == null : value == filter);

  bool _keep(Transaction t) {
    final typeOk = switch (_filter) {
      _Filter.all => true,
      _Filter.expenses => t.amount < 0,
      _Filter.income => t.amount > 0,
    };
    final query = _search.text.trim().toLowerCase();
    return typeOk
      && (query.isEmpty || t.name.toLowerCase().contains(query))
      && _matches(_category, t.categoryId)
      && _matches(_account, t.accountId)
      && (_tag == _all || t.tags.any((g) => g.id == _tag));
  }

  String get _emptyText => switch (_filter) {
    _Filter.all => 'Aucune transaction',
    _Filter.expenses => 'Aucune dépense',
    _Filter.income => 'Aucun revenu',
  };

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final palette = context.palette;
    final wide = isWide(context);

    final title = Text(
      'Transactions',
      style: TextStyle(fontSize: wide ? 20 : 19, fontWeight: FontWeight.w600, color: palette.ink),
    );
    final typeFilter = PillSegmented<_Filter>(
      options: const [
        (_Filter.all, 'Tout'),
        (_Filter.expenses, 'Dépenses'),
        (_Filter.income, 'Revenus'),
      ],
      selected: _filter,
      expand: !wide,
      onChanged: (f) => setState(() => _filter = f),
    );

    final search = TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Rechercher par nom…',
        isDense: true,
        fillColor: palette.card,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _search.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Effacer',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(_search.clear),
            ),
      ),
    );

    final menus = <Widget>[
      _FilterMenu(
        label: 'Catégorie',
        allLabel: 'Toutes les catégories',
        selected: _category,
        options: [
          for (final c in categories) (c.id, c.name),
          (_none, 'Sans catégorie'),
        ],
        onSelected: (v) => setState(() => _category = v),
      ),
      if (tags.isNotEmpty)
        _FilterMenu(
          label: 'Tag',
          allLabel: 'Tous les tags',
          selected: _tag,
          options: [for (final g in tags) (g.id, g.name)],
          onSelected: (v) => setState(() => _tag = v),
        ),
      _FilterMenu(
        label: 'Compte',
        allLabel: 'Tous les comptes',
        selected: _account,
        options: [
          for (final a in accounts) (a.id, a.archived ? '${a.name} (archivé)' : a.name),
          (_none, 'Sans compte'),
        ],
        onSelected: (v) => setState(() => _account = v),
      ),
    ];

    final filters = wide
      ? Row(
          children: [
            Expanded(child: search),
            for (final m in menus) ...[const SizedBox(width: 10), m],
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, m) in menus.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    m,
                  ],
                ],
              ),
            ),
          ],
        );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 12, wide ? 24 : 16, wide ? 20 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(children: [Expanded(child: title), typeFilter])
            else ...[
              title,
              const SizedBox(height: 10),
              typeFilter,
            ],
            const SizedBox(height: 12),
            filters,
            const SizedBox(height: 14),
            Expanded(
              child: transactions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (all) {
                  final rows = _groupByDay(all.where(_keep).toList());
                  if (rows.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _hasFilters ? 'Aucune transaction ne correspond' : _emptyText,
                            style: TextStyle(color: palette.muted),
                          ),
                          if (_hasFilters)
                            TextButton(onPressed: _clearFilters, child: const Text('Effacer les filtres')),
                        ],
                      ),
                    );
                  }
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: wide ? 0 : 88),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => switch (rows[i]) {
                        _HeaderRow(:final day, :final total) => _DayHeader(day: day, total: total),
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

class _FilterMenu extends StatelessWidget {
  final String label;
  final String allLabel;
  final int selected;
  final List<(int, String)> options;
  final ValueChanged<int> onSelected;

  const _FilterMenu({
    required this.label,
    required this.allLabel,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    final active = selected != _all;
    final current = options.where((o) => o.$1 == selected).firstOrNull?.$2;

    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(value: _all, checked: !active, child: Text(allLabel)),
        const PopupMenuDivider(),
        for (final (id, name) in options)
          CheckedPopupMenuItem(value: id, checked: id == selected, child: Text(name)),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.1) : palette.card,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? accent : palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? current ?? label : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? accent : palette.ink,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 20, color: active ? accent : palette.muted),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final double total;

  const _DayHeader({required this.day, required this.total});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.55,
      color: palette.muted,
    );
    return Container(
      color: palette.soft,
      padding: EdgeInsets.symmetric(horizontal: isWide(context) ? 18 : 16, vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(formatDayHeader(day), style: style)),
          Text(formatAmount(total, signed: true), style: style),
        ],
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