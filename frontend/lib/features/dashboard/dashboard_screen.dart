import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/pill_segmented.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/tone_chip.dart';
import '../auth/auth_repository.dart';
import '../auth/user_avatar.dart';
import '../settings/references_repository.dart';
import 'stats_repository.dart';

const _gap = SizedBox(width: 14, height: 14);
const _minFitHeight = 620.0;
const _cardChrome = 66.0;
const _legendRatio = 1.4;


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (wide && constraints.maxHeight >= _minFitHeight) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: _WideLayout(fit: true),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 12, wide ? 24 : 16, wide ? 20 : 96),
            children: wide
              ? const [_WideLayout(fit: false)]
              : const [
                  _Greeting(),
                  SizedBox(height: 12),
                  _PeriodSelector(),
                  SizedBox(height: 14),
                  _NarrowLayout(),
                ],
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PillSegmented<String>(
        options: const [
          ('month', 'Ce mois'),
          ('3months', '3 mois'),
          ('6months', '6 mois'),
          ('all', 'Tout'),
        ],
        selected: ref.watch(selectedPeriodProvider),
        onChanged: (p) => ref.read(selectedPeriodProvider.notifier).state = p,
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final bool fit;

  const _WideLayout({required this.fit});

  Widget _row({required int flex, required double height, required List<Widget> children}) {
    final row = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    return fit ? Expanded(flex: flex, child: row) : SizedBox(height: height, child: row);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topLeft,
                        child: _Greeting(),
                      ),
                    ),
                    SizedBox(height: 12),
                    _PeriodSelector(),
                  ],
                ),
              ),
              SizedBox(width: 24),
              Expanded(flex: 135, child: _HeroCard()),
              _gap,
              Expanded(flex: 100, child: _KpiCard(income: true)),
              _gap,
              Expanded(flex: 100, child: _KpiCard(income: false)),
            ],
          ),
        ),
        _gap,
        _row(flex: 3, height: 380, children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final side = math.min(c.maxHeight - _cardChrome, 300.0);
                final width = side * (1 + _legendRatio) + 20 + 40;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: math.min(width, c.maxWidth * 0.55),
                      child: const _DonutCard(expand: true),
                    ),
                    _gap,
                    const Expanded(child: _BalanceCard(expand: true)),
                  ],
                );
              },
            ),
          ),
        ]),
        _gap,
        _row(flex: 2, height: 250, children: const [
          Expanded(flex: 10, child: _MonthlyCard(expand: true)),
          _gap,
          Expanded(flex: 19, child: _TopNamesCard(expand: true)),
        ]),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(),
        _gap,
        Row(
          children: [
            Expanded(child: _KpiCard(income: true)),
            _gap,
            Expanded(child: _KpiCard(income: false)),
          ],
        ),
        _gap,
        _DonutCard(),
        _gap,
        _BalanceCard(),
        _gap,
        _MonthlyCard(),
        _gap,
        _TopNamesCard(),
      ],
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  static const _periodLabels = {
    '3months': '3 derniers mois',
    '6months': '6 derniers mois',
    'all': 'Depuis toujours',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUsernameProvider).valueOrNull ?? '';
    final period = ref.watch(selectedPeriodProvider);
    final palette = context.palette;

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour $name 👋',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: palette.ink),
        ),
        Text(
          _periodLabels[period] ?? formatMonthYear(DateTime.now()),
          style: TextStyle(fontSize: 12.5, color: palette.muted),
        ),
      ],
    );

    if (isWide(context)) return texts;
    return Row(
      children: [
        Expanded(child: texts),
        const UserAvatar(),
      ],
    );
  }
}

class _HeroCard extends ConsumerStatefulWidget {
  const _HeroCard();

  @override
  ConsumerState<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<_HeroCard> {
  bool _showBanks = false;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(summaryProvider);
    final balances = ref.watch(balancesProvider).valueOrNull;
    final period = ref.watch(selectedPeriodProvider);
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(isWide(context) ? 18 : 22);
    final count = balances?.accounts.where((a) => !a.archived).length;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.secondary],
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => setState(() => _showBanks = !_showBanks),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: summary.when(
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (e, _) => Text('Erreur : $e'),
                data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            count == null
                              ? 'Solde total'
                              : 'Solde total · $count compte${count > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          _showBanks ? 'Masquer ›' : 'Répartition par banque ›',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatAmount(s.solde, signed: s.solde < 0),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${s.variation >= 0 ? '▲' : '▼'} ${formatAmount(s.variation, signed: true)} '
                        '${period == 'month' ? 'ce mois' : 'sur la période'}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_showBanks && balances != null) ...[
                      const SizedBox(height: 13),
                      _BankBreakdown(balances: balances),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankBreakdown extends StatelessWidget {
  final Balances balances;

  const _BankBreakdown({required this.balances});

  static const _shades = [1.0, 0.7, 0.5, 0.35, 0.25];

  @override
  Widget build(BuildContext context) {
    final byBank = <String, double>{};
    for (final a in balances.accounts) {
      final key = a.bankName ?? 'Portefeuille';
      byBank[key] = (byBank[key] ?? 0) + a.balance;
    }
    if (balances.unassigned != 0) byBank['Sans compte'] = balances.unassigned;

    final positive = byBank.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = positive.fold<double>(0, (sum, e) => sum + e.value);
    if (total == 0) {
      return const Text('Aucun solde positif à répartir', style: TextStyle(fontSize: 11.5));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: [
              for (final (i, e) in positive.indexed)
                Expanded(
                  flex: (e.value / total * 1000).round().clamp(1, 1000),
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(right: i == positive.length - 1 ? 0 : 2),
                    color: Colors.white.withValues(alpha: _shades[i % _shades.length]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final e in positive)
              Text(
                '${e.key} · ${(e.value / total * 100).round()} %',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends ConsumerWidget {
  final bool income;

  const _KpiCard({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider).valueOrNull;
    final palette = context.palette;
    final value = summary == null ? null : (income ? summary.revenus : summary.depenses);
    final count = summary == null ? 0 : (income ? summary.nbRevenus : summary.nbDepenses);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              income ? 'Revenus' : 'Dépenses',
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value == null ? '…' : formatAmount(value, signed: true),
              style: TextStyle(
                fontSize: isWide(context) ? 25 : 19,
                fontWeight: FontWeight.w700,
                color: income ? palette.pos : palette.neg,
              ),
            ),
            Text(
              '$count transaction${count > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutCard extends ConsumerWidget {
  final bool expand;

  const _DonutCard({this.expand = false});

  Widget _donut(BuildContext context, List<CategoryStat> list, double total, double side) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: side * 0.31,
              startDegreeOffset: -90,
              sections: [
                for (final c in list)
                  PieChartSectionData(
                    value: c.total,
                    color: labelTone(c.categoryColor, brightness).solid,
                    radius: side * 0.16,
                    showTitle: c.total / total >= 0.07,
                    title: '${(c.total / total * 100).round()} %',
                    titleStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: labelTone(c.categoryColor, brightness).solid.computeLuminance() > 0.4
                        ? Colors.black87
                        : Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatAmount(total, rounded: true),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: palette.ink),
              ),
              Text('dépensés', style: TextStyle(fontSize: 12, color: palette.muted)),
            ],
          ),
        ],
      ),
    );
  }

  double _total(List<CategoryStat> list) => list.fold<double>(0, (sum, c) => sum + c.total);

  Widget _chips(List<CategoryStat> list, {bool center = false}) {
    final total = _total(list);
    return Wrap(
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final c in list)
          ToneChip(
            label: '${c.categoryName ?? 'Sans catégorie'} '
              '${formatAmount(c.total, rounded: true)} · ${(c.total / total * 100).round()} %',
            colorName: c.categoryColor,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byCategoryProvider);
    final palette = context.palette;
    final empty = Text('Aucune dépense sur la période', style: TextStyle(color: palette.muted));
    const title = 'Où part ton argent ?';

    if (expand) {
      final current = data.valueOrNull ?? const <CategoryStat>[];
      Widget donutArea(double side) => data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) => list.isEmpty
          ? Center(child: empty)
          : Center(child: _donut(context, list, _total(list), side)),
      );
      return SectionCard(
        title: title,
        expand: true,
        child: LayoutBuilder(
          builder: (context, c) {
            final side = math.min(math.min(c.maxHeight, c.maxWidth * 0.5), 300.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: side, child: donutArea(side)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TagFilter(),
                      const _GroupLabel('Catégories'),
                      const SizedBox(height: 7),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: SingleChildScrollView(child: _chips(current)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final content = data.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) {
        if (list.isEmpty) {
          return Padding(padding: const EdgeInsets.all(40), child: Center(child: empty));
        }
        return Column(
          children: [
            _donut(context, list, _total(list), 200),
            const SizedBox(height: 12),
            _chips(list, center: true),
          ],
        );
      },
    );
    return SectionCard(
      title: title,
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: _TagFilter()),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}

class _TagFilter extends ConsumerWidget {
  const _TagFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    if (tags.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(selectedTagProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _GroupLabel('Filtrer par tag'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final t in tags)
                _TagChip(
                  tag: t,
                  selected: selected == t.id,
                  onTap: () => ref.read(selectedTagProvider.notifier).state =
                    selected == t.id ? null : t.id,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = labelTone(tag.color, Theme.of(context).brightness);
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? tone.solid : tone.solid.withValues(alpha: 0.45),
        width: 1.5,
      ),
    );

    return Material(
      color: selected ? tone.background : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : Icons.sell_outlined,
                size: 13,
                color: tone.solid,
              ),
              const SizedBox(width: 5),
              Text(
                tag.name,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? tone.text : palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.palette.muted,
      ),
    );
  }
}

const _monthNames = [
  'Janv', 'Fév', 'Mars', 'Avr', 'Mai', 'Juin',
  'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc',
];

const _maxDateLabels = 15;
const _monthSteps = [1, 2, 3, 6, 12, 24, 36, 60, 120];

/// Un axe de temps : où placer une date (x), le pas entre deux
/// graduations, et l'étiquette d'une graduation (null = pas d'étiquette).
class _TimeAxis {
  final double Function(DateTime) x;
  final double interval;
  final String? Function(double) label;

  const _TimeAxis(this.x, this.interval, this.label);
}

_TimeAxis _timeAxis(DateTime from, DateTime to) {
  final span = DateTime.utc(to.year, to.month, to.day)
    .difference(DateTime.utc(from.year, from.month, from.day))
    .inDays;
  String month(int m) => _monthNames[m - 1];

  // Jusqu'à 1 mois : x en jours, origine le lundi précédent, un pas de 7 jours = chaque lundi.
  if (span <= 31) {
    final monday = DateTime.utc(from.year, from.month, from.day - (from.weekday - 1));
    return _TimeAxis(
      (d) => DateTime.utc(d.year, d.month, d.day).difference(monday).inDays.toDouble(),
      7,
      (v) {
        final d = monday.add(Duration(days: v.round()));
        return '${d.day} ${month(d.month).toLowerCase()}';
      },
    );
  }

  // Jusqu'à 4 mois : x en jours depuis le 1er du mois, étiquettes le 1er et le 15.
  if (span <= 120) {
    final origin = DateTime.utc(from.year, from.month, 1);
    return _TimeAxis(
      (d) => DateTime.utc(d.year, d.month, d.day).difference(origin).inDays.toDouble(),
      1,
      (v) {
        final d = origin.add(Duration(days: v.round()));
        return d.day == 1 || d.day == 15 ? '${d.day} ${month(d.month).toLowerCase()}' : null;
      },
    );
  }

  // Au-delà : x en mois. Le plus petit pas qui donne au plus 15 étiquettes.
  final months = (to.year - from.year) * 12 + to.month - from.month;
  final step = _monthSteps.firstWhere(
    (s) => months / s <= _maxDateLabels - 1,
    orElse: () => _monthSteps.last,
  );
  // Origine : le mois « rond » qui précède `from` (janvier d'une année paire pour un pas de 2 ans…).
  var origin = from.year * 12 + from.month - 1;
  origin -= origin % step;

  return _TimeAxis(
    (d) {
      final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
      return (d.year * 12 + d.month - 1 - origin) + (d.day - 1) / daysInMonth;
    },
    step.toDouble(),
    (v) {
      final m = origin + v.round();
      final year = m ~/ 12;
      final mon = m % 12 + 1;
      if (step >= 12) return '$year';
      if (step == 1) return month(mon);
      return '${month(mon)} ${(year % 100).toString().padLeft(2, '0')}';
    },
  );
}


class _MonthlyCard extends ConsumerWidget {
  final bool expand;
  const _MonthlyCard({this.expand = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(monthlyProvider);
    final palette = context.palette;
    const top = BorderRadius.vertical(top: Radius.circular(5));
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return SectionCard(
      title: 'Revenus vs dépenses',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: palette.posBar, label: 'Revenus'),
          const SizedBox(width: 14),
          _LegendDot(color: palette.negBar, label: 'Dépenses'),
        ],
      ),
      expand: expand,
      child: SizedBox(
        height: expand ? null : 240,
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (months) => BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: hidden,
                rightTitles: hidden,
                topTitles: hidden,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _monthNames[months[value.toInt()].start.month - 1],
                        style: TextStyle(fontSize: 11, color: palette.muted),
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (final (i, m) in months.indexed)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 5,
                    barRods: [
                      BarChartRodData(toY: m.revenus, color: palette.posBar, width: 17, borderRadius: top),
                      BarChartRodData(toY: m.depenses, color: palette.negBar, width: 17, borderRadius: top),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, color: context.palette.muted)),
      ],
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final bool expand;

  const _BalanceCard({this.expand = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(balanceOverTimeProvider);
    final palette = context.palette;
    const title = 'Évolution du solde';
    final height = expand ? null : 180.0;

    return data.when(
      loading: () => SectionCard(
        title: title,
        expand: expand,
        child: SizedBox(height: height, child: const Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => SectionCard(title: title, expand: expand, child: Text('Erreur : $e')),
      data: (b) {
        Widget? badge;
        if (b.points.isNotEmpty && b.opening != 0) {
          final change = (b.points.last.balance - b.opening) / b.opening.abs() * 100;
          final up = change >= 0;
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: up ? palette.posBg : palette.negBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${up ? '+' : '−'}${change.abs().toStringAsFixed(1).replaceAll('.', ',')} %',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: up ? palette.posText : palette.neg,
              ),
            ),
          );
        }

        return SectionCard(
          title: title,
          trailing: badge,
          expand: expand,
          child: SizedBox(
            height: height,
            child: b.points.isEmpty
              ? Center(
                  child: Text('Aucun mouvement sur la période', style: TextStyle(color: palette.muted)),
                )
              : _chart(context, b),
          ),
        );
      },
    );
  }

  Widget _chart(BuildContext context, BalanceOverTime b) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    final axis = _timeAxis(b.points.first.date, b.points.last.date);
    final lastX = axis.x(b.points.last.date);

    final axisStyle = TextStyle(fontSize: 10.5, color: palette.muted);
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(lastX, 1.0).toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: palette.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: hidden,
          rightTitles: hidden,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 58,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(formatAmount(value, signed: value < 0, rounded: true), style: axisStyle),
              ),
            ),
          ),
                    bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: axis.interval,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final label = axis.label(value);
                if (label == null) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(label, style: axisStyle),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final p in b.points) FlSpot(axis.x(p.date), p.balance),
            ],
            color: accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _TopNamesCard extends ConsumerWidget {
  final bool expand;

  const _TopNamesCard({this.expand = false});

  static const _colors = ['ORANGE', 'BLUE', 'GREEN', 'PURPLE', 'YELLOW'];
  static const _rowGap = 11.0;
  static const _rowHeight = 30.0 + _rowGap;

  Widget _rows(BuildContext context, List<TransactionNameStat> list, int count) {
    final palette = context.palette;
    final brightness = Theme.of(context).brightness;
    final top = list.take(count).toList();
    final highest = top.first.total;
    return Column(
      children: [
        for (final (i, n) in top.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: i == top.length - 1 ? 0 : _rowGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: palette.ink),
                      ),
                    ),
                    Text(
                      formatAmount(n.total),
                      style: TextStyle(fontSize: 12.5, color: palette.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: highest > 0 ? n.total / highest : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: labelTone(_colors[i % _colors.length], brightness).solid,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byTransactionNameProvider);
    final palette = context.palette;

    return SectionCard(
      title: 'Top dépenses par nom',
      expand: expand,
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (list) {
          if (list.isEmpty) {
            return Text('Aucune dépense sur la période', style: TextStyle(color: palette.muted));
          }
          if (!expand) return _rows(context, list, 5);
          return LayoutBuilder(
            builder: (context, c) {
              final fits = ((c.maxHeight + _rowGap) / _rowHeight).floor();
              return _rows(context, list, fits.clamp(1, 5));
            },
          );
        },
      ),
    );
  }
}