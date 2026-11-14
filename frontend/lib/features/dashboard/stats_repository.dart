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

  Future<List<CategoryStat>> getByCategory(String period, {int? tagId}) async {
    final response = await _dio.get('/stats/by-category', queryParameters: {
      'period': period,
      if (tagId != null) 'tag_id': tagId,
    });
    return (response.data as List).map((e) => CategoryStat.fromJson(e)).toList();
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

class CategoryStat {
  final String? categoryName;
  final String? categoryColor;
  final double total;

  CategoryStat({this.categoryName, this.categoryColor, required this.total});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as String?,
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
final selectedTagProvider = StateProvider.autoDispose<int?>((ref) => null);

final summaryProvider = FutureProvider.autoDispose<StatsSummary>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(statsRepositoryProvider).getSummary(period);
});

final byCategoryProvider = FutureProvider.autoDispose<List<CategoryStat>>((ref) {
    final period = ref.watch(selectedPeriodProvider);
    final tagId = ref.watch(selectedTagProvider);
    return ref.watch(statsRepositoryProvider).getByCategory(period, tagId: tagId);
});

final byTransactionNameProvider = FutureProvider.autoDispose<List<TransactionNameStat>>((ref) {
    final period = ref.watch(selectedPeriodProvider);
    return ref.watch(statsRepositoryProvider).getByTransactionName(period);
});

final balanceOverTimeProvider = FutureProvider.autoDispose<BalanceOverTime>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(statsRepositoryProvider).getBalanceOverTime(period);
});