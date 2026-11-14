import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Transaction {
    final int id;
    final String name;
    final DateTime date;
    final double amount;
    final String? description;
    final String? labelName;
    final String? labelColor;
    final String methodType;

    Transaction({
        required this.id,
        required this.name,
        required this.date,
        required this.amount,
        this.description,
        this.labelName,
        this.labelColor,
        required this.methodType,
    });

    factory Transaction.fromJson(Map<String, dynamic> json) {
        final label = json['label'] as Map<String, dynamic>?;
        return Transaction(
            id: json['transac_id'] as int,
            name: json['transac_name'] as String,
            date: DateTime.parse(json['transac_date'] as String),
            amount: double.parse(json['transac_amount'].toString()),
            description: json['transac_description'] as String?,
            labelName: label?['label_name'] as String?,
            labelColor: label?['label_color'] as String?,
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
      int? labelId,
    }) async {
      await _dio.post('/transactions/', data: {
        'transac_name': name,
        'transac_date': date.toIso8601String(),
        'transac_amount': amount.toStringAsFixed(2),
        'transac_description': description,
        'transmet_id': methodId,
        'label_id': labelId,
      });
    }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
    return TransactionsRepository(ref.watch(dioProvider));
});

final transactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) {
    return ref.watch(transactionsRepositoryProvider).getAll();
});