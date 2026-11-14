import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Transaction {
    final int id;
    final String name;
    final DateTime date;
    final double amount;
    final String? description;
    final String? categoryName;
    final String? categoryColor;
    final String methodType;

    Transaction({
        required this.id,
        required this.name,
        required this.date,
        required this.amount,
        this.description,
        this.categoryName,
        this.categoryColor,
        required this.methodType,
    });

    factory Transaction.fromJson(Map<String, dynamic> json) {
        final category = json['category'] as Map<String, dynamic>?;
        return Transaction(
            id: json['transac_id'] as int,
            name: json['transac_name'] as String,
            date: DateTime.parse(json['transac_date'] as String),
            amount: double.parse(json['transac_amount'].toString()),
            description: json['transac_description'] as String?,
            categoryName: category?['category_name'] as String?,
            categoryColor: category?['category_color'] as String?,
            methodType: json['method']['transmet_type'] as String,
        );
    }
}

class TransactionsRepository {
    final Dio _dio;
    TransactionsRepository(this._dio);

    Future<List<Transaction>> getAll() async {
        final response = await _dio.get('/transactions/');
        final list = (response.data as List)
            .map((e) => Transaction.fromJson(e))
            .toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
    }

    Future<void> create({
      required String name,
      required DateTime date,
      required double amount,
      String? description,
      required int methodId,
      int? categoryId,
    }) async {
      await _dio.post('/transactions/', data: {
        'transac_name': name,
        'transac_date': date.toIso8601String(),
        'transac_amount': amount.toStringAsFixed(2),
        'transac_description': description,
        'transmet_id': methodId,
        'category_id': categoryId,
      });
    }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
    return TransactionsRepository(ref.watch(dioProvider));
});

final transactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) {
    return ref.watch(transactionsRepositoryProvider).getAll();
});