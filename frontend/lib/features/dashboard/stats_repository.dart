import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class StatsSummary {
  final double solde;
  final double revenus;
  final double depenses;
  final double variation;
  final int nbTransactions;
  final int nbRevenus;
  final int nbDepenses;

  StatsSummary({
    required this.solde,
    required this.revenus,
    required this.depenses,
    required this.variation,
    required this.nbTransactions,
    required this.nbRevenus,
    required this.nbDepenses,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      solde: double.parse(json['solde'].toString()),
      revenus: double.parse(json['revenus'].toString()),
      depenses: double.parse(json['depenses'].toString()),
      variation: double.parse(json['variation'].toString()),
      nbTransactions: json['nb_transactions'] as int,
      nbRevenus: json['nb_revenus'] as int,
      nbDepenses: json['nb_depenses'] as int,
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
      'tag_id': ?tagId,
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

  Future<List<MonthlyStat>> getMonthly({int months = 6}) async {
    final response = await _dio.get('/stats/monthly', queryParameters: {'months': months});
    return (response.data as List).map((e) => MonthlyStat.fromJson(e)).toList();
  }

  Future<Balances> getBalances() async {
    final response = await _dio.get('/stats/balances');
    return Balances.fromJson(response.data);
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

class MonthlyStat {
  final DateTime start;
  final double revenus;
  final double depenses;

  MonthlyStat({required this.start, required this.revenus, required this.depenses});

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      start: DateTime.parse(json['month'] as String),
      revenus: double.parse(json['revenus'].toString()),
      depenses: double.parse(json['depenses'].toString()),
    );
  }
}

class AccountBalance {
  final int id;
  final String name;
  final bool archived;
  final String? bankName;
  final String? bankColor;
  final double balance;

  AccountBalance({
    required this.id,
    required this.name,
    required this.archived,
    this.bankName,
    this.bankColor,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['account_id'] as int,
      name: json['account_name'] as String,
      archived: json['account_archived'] as bool,
      bankName: json['bank_name'] as String?,
      bankColor: json['bank_color'] as String?,
      balance: double.parse(json['balance'].toString()),
    );
  }
}

class Balances {
  final List<AccountBalance> accounts;
  final double unassigned;

  Balances({required this.accounts, required this.unassigned});

  factory Balances.fromJson(Map<String, dynamic> json) {
    return Balances(
      accounts: (json['accounts'] as List).map((e) => AccountBalance.fromJson(e)).toList(),
      unassigned: double.parse(json['unassigned'].toString()),
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

final monthlyProvider = FutureProvider.autoDispose<List<MonthlyStat>>((ref) {
  return ref.watch(statsRepositoryProvider).getMonthly();
});

final balancesProvider = FutureProvider.autoDispose<Balances>((ref) {
  return ref.watch(statsRepositoryProvider).getBalances();
});