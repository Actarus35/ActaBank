import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/pill_segmented.dart';
import '../auth/auth_repository.dart';
import '../auth/user_avatar.dart';
import '../settings/references_repository.dart';
import 'stats_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const _Greeting(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: PillSegmented<String>(
              options: const [
                ('month', 'Ce mois'),
                ('3months', '3 mois'),
                ('6months', '6 mois'),
                ('all', 'Tout'),
              ],
              selected: period,
              onChanged: (p) => ref.read(selectedPeriodProvider.notifier).state = p,
            ),
          ),
          const SizedBox(height: 16),
          const _SummarySection(),
          const SizedBox(height: 24),
          const Text('Dépenses par catégorie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _TagFilter(),
          const SizedBox(height: 8),
          const _CategoryDonut(),
          const SizedBox(height: 24),
          const Text('Évolution du solde',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _BalanceChart(),
          const SizedBox(height: 24),
          const Text('Répartition par libellé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _TransactionNameList(),
        ],
      ),
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

    return Row(
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        if (!isWide(context)) const UserAvatar(),
      ],
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    return summary.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solde Total', style: Theme.of(context).textTheme.labelLarge),
          Text('${s.solde.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _Kpi(label: 'Revenus', value: s.revenus, color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _Kpi(label: 'Dépenses', value: s.depenses, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          Text('${s.nbTransactions} transaction(s) sur la période'),
        ],
      ),
    );
  }
}

class _TagFilter extends ConsumerWidget {
  const _TagFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    final selected = ref.watch(selectedTagProvider);
    return tags.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          children: [
            for (final t in list)
              ChoiceChip(
                label: Text(t.name),
                selected: selected == t.id,
                onSelected: (on) =>
                  ref.read(selectedTagProvider.notifier).state = on ? t.id : null,
              ),
          ],
        );
      },
    );
  }
}

class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byCategoryProvider);
    return data.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (categories) {
        if (categories.isEmpty) {
          return const Text('Aucune dépense sur la période');
        }
        return SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                for (final l in categories)
                  PieChartSectionData(
                    value: l.total,
                    color: colorFromName(l.categoryColor),
                    title: l.categoryName ?? 'Sans categorie',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceChart extends ConsumerWidget {
  const _BalanceChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(balanceOverTimeProvider);
    return data.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Text('Erreur : $e'),
      data: (b) {
        if (b.points.isEmpty) {
          return const Text('Aucun mouvement sur la période');
        }
        // On mappe chaque point à un (x = index, y = solde)
        final spots = <FlSpot>[
          for (var i = 0; i < b.points.length; i++)
            FlSpot(i.toDouble(), b.points[i].balance),
        ];
        final color = Theme.of(context).colorScheme.primary;
        return SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionNameList extends ConsumerWidget {
  const _TransactionNameList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byTransactionNameProvider);
    return data.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) {
        if (list.isEmpty) return const Text('Aucune dépense sur la période');
        final max = list.first.total;
        return Column(
          children: [
            for (final n in list.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(n.name, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: max > 0 ? n.total / max : 0,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${n.total.toStringAsFixed(0)} €'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}


class _Kpi extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Kpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text('${value.toStringAsFixed(2)} €',
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}