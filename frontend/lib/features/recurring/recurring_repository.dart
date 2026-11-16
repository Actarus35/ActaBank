import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../settings/references_repository.dart';

const frequencyLabels = {
  'DAILY': 'Tous les jours',
  'WEEKLY': 'Toutes les semaines',
  'MONTHLY': 'Tous les mois',
  'YEARLY': 'Tous les ans',
};

class RecurringTransaction {
  final int id;
  final String name;
  final double amount;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int methodId;
  final int? categoryId;
  final List<Tag> tags;

  RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.methodId,
    this.categoryId,
    required this.tags,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    final end = json['rectrans_end_date'] as String?;
    return RecurringTransaction(
      id: json['rectrans_id'] as int,
      name: json['rectrans_name'] as String,
      amount: double.parse(json['rectrans_amount'].toString()),
      frequency: json['rectrans_frequency'] as String,
      startDate: DateTime.parse(json['rectrans_start_date'] as String),
      endDate: end == null ? null : DateTime.parse(end),
      methodId: json['rectrans_transmet_id'] as int,
      categoryId: json['rectrans_category_id'] as int?,
      tags: (json['tags'] as List).map((e) => Tag.fromJson(e)).toList(),
    );
  }

  String get frequencyLabel => frequencyLabels[frequency] ?? frequency;
}

class RecurringRepository {
  final Dio _dio;
  RecurringRepository(this._dio);

  Future<List<RecurringTransaction>> getAll() async {
    final response = await _dio.get('/recurring_transactions/');
    return (response.data as List)
        .map((e) => RecurringTransaction.fromJson(e))
        .toList();
  }

  Future<void> save({
    int? id,
    required String name,
    required double amount,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required int methodId,
    int? categoryId,
    List<int> tagIds = const [],
  }) async {
    final data = {
      'rectrans_name': name,
      'rectrans_amount': amount.toStringAsFixed(2),
      'rectrans_frequency': frequency,
      'rectrans_start_date': startDate.toIso8601String(),
      'rectrans_end_date': endDate?.toIso8601String(),
      'rectrans_transmet_id': methodId,
      'rectrans_category_id': categoryId,
      'tag_ids': tagIds,
    };
    if (id == null) {
      await _dio.post('/recurring_transactions/', data: data);
    } else {
      await _dio.patch('/recurring_transactions/$id', data: data);
    }
  }

  Future<void> delete(int id) => _dio.delete('/recurring_transactions/$id');
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(dioProvider));
});

final recurringProvider = FutureProvider.autoDispose<List<RecurringTransaction>>((ref) {
  return ref.watch(recurringRepositoryProvider).getAll();
});
