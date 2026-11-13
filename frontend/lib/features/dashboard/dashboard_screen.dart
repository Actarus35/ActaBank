import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'stats_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ActaBank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'month', label: Text('Ce mois')),
                ButtonSegment(value: '3months', label: Text('3 mois')),
                ButtonSegment(value: '6months', label: Text('6 mois')),
                ButtonSegment(value: 'all', label: Text('Tout')),
              ],
              selected: {period},
              onSelectionChanged: (s) =>
                ref.read(selectedPeriodProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _SummarySection(),
                SizedBox(height: 24),
                Text('Dépenses par catégorie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _LabelDonut(),
                SizedBox(height: 24),
                Text('Évolution du solde',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _BalanceChart(),
                SizedBox(height: 24),
                Text('Répartition par bénéficiaire',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _BeneficiaryList(),
              ],
            ),
          ),
        ],
      ),
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

class _LabelDonut extends ConsumerWidget {
  const _LabelDonut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byLabelProvider);
    return data.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (labels) {
        if (labels.isEmpty) {
          return const Text('Aucune dépense sur la période');
        }
        return SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                for (final l in labels)
                  PieChartSectionData(
                    value: l.total,
                    color: _colorFromName(l.labelColor),
                    title: l.labelName ?? 'Sans label',
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

class _BeneficiaryList extends ConsumerWidget {
  const _BeneficiaryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(byBeneficiaryProvider);
    return data.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Text('Erreur : $e'),
      data: (list) {
        if (list.isEmpty) return const Text('Aucune dépense sur la période');
        final max = list.first.total;
        return Column(
          children: [
            for (final b in list.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(b.beneficiary, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: max > 0 ? b.total / max : 0,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${b.total.toStringAsFixed(0)} €'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}


Color _colorFromName(String? name) {
  switch (name) {
    case 'BLACK': return Colors.black;
    case 'BLUE': return Colors.blue;
    case 'BROWN': return Colors.brown;
    case 'GRAY': return Colors.grey;
    case 'GREEN': return Colors.green;
    case 'ORANGE': return Colors.orange;
    case 'PINK': return Colors.pink;
    case 'PURPLE': return Colors.purple;
    case 'RED': return Colors.red;
    case 'WHITE': return Colors.white;
    case 'YELLOW': return Colors.yellow;
    default: return Colors.grey.shade400;
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