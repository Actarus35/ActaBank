import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class StatsSummary {
  final double solde;
  final double revenus;
  final double depenses;
  final double variation;
  final int nbTransactions;

  StatsSummary({
    required this.solde,
    required this.revenus,
    required this.depenses,
    required this.variation,
    required this.nbTransactions,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      solde: double.parse(json['solde'].toString()),
      revenus: double.parse(json['revenus'].toString()),
      depenses: double.parse(json['depenses'].toString()),
      variation: double.parse(json['variation'].toString()),
      nbTransactions: json['nb_transactions'] as int,
    );
  }
}

class StatsRepository {
  final Dio _dio;
  StatsRepository(this._dio);

  Future<StatsSummary> getSummary(String period) async {
    final response = await _dio.get('/stats/summary', queryParameters: {'period': period});
    return StatsSummary.fromJson(response.data);
  }

  Future<List<LabelStat>> getByLabel(String period) async {
    final response = await _dio.get('/stats/by-label', queryParameters: {'period': period});
    return (response.data as List).map((e) => LabelStat.fromJson(e)).toList();
  }

  Future<BalanceOverTime> getBalanceOverTime(String period) async {
    final response = await _dio.get('/stats/balance-over-time', queryParameters: {'period': period});
    return BalanceOverTime.fromJson(response.data);
  }

  Future<List<TransactionNameStat>> getByTransactionName(String period) async {
    final response = await _dio.get('/stats/by-name', queryParameters: {'period': period});
    return (response.data as List).map((e) => TransactionNameStat.fromJson(e)).toList();
  }

}

class LabelStat {
  final String? labelName;
  final String? labelColor;
  final double total;

  LabelStat({this.labelName, this.labelColor, required this.total});

  factory LabelStat.fromJson(Map<String, dynamic> json) {
    return LabelStat(
      labelName: json['label_name'] as String?,
      labelColor: json['label_color'] as String?,
      total: double.parse(json['total'].toString()),
    );
  }
}

class BalancePoint {
  final DateTime date;
  final double balance;

  BalancePoint({required this.date, required this.balance});

  factory BalancePoint.fromJson(Map<String, dynamic> json) {
    return BalancePoint(
      date: DateTime.parse(json['date'] as String),
      balance: double.parse(json['balance'].toString()),
    );
  }
}

class BalanceOverTime {
  final double opening;
  final List<BalancePoint> points;

  BalanceOverTime({required this.opening, required this.points});

  factory BalanceOverTime.fromJson(Map<String, dynamic> json) {
    return BalanceOverTime(
      opening: double.parse(json['opening'].toString()),
      points: (json['points'] as List)
          .map((e) => BalancePoint.fromJson(e))
          .toList(),
    );
  }
}

class TransactionNameStat {
  final String name;
  final double total;

  TransactionNameStat({required this.name, required this.total});

  factory TransactionNameStat.fromJson(Map<String, dynamic> json) {
    return TransactionNameStat(
      name: json['name'] as String,
      total: double.parse(json['total'].toString()),
    );
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(dioProvider));
});

final selectedPeriodProvider = StateProvider<String>((ref) => 'month');

final summaryProvider = FutureProvider.autoDispose<StatsSummary>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(statsRepositoryProvider).getSummary(period);
});

final byLabelProvider = FutureProvider.autoDispose<List<LabelStat>>((ref) {
    final period = ref.watch(selectedPeriodProvider);
    return ref.watch(statsRepositoryProvider).getByLabel(period);
});

final byTransactionNameProvider = FutureProvider.autoDispose<List<TransactionNameStat>>((ref) {
    final period = ref.watch(selectedPeriodProvider);
    return ref.watch(statsRepositoryProvider).getByTransactionName(period);
});

final balanceOverTimeProvider = FutureProvider.autoDispose<BalanceOverTime>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(statsRepositoryProvider).getBalanceOverTime(period);
});