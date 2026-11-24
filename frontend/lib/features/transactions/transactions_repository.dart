import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../settings/references_repository.dart';

class Transaction {
    final int id;
    final String name;
    final DateTime date;
    final double amount;
    final String? description;
    final int? categoryId;
    final String? categoryName;
    final String? categoryColor;
    final int methodId;
    final String methodType;
    final int? accountId;
    final String? accountName;
    final String? bankName;
    final bool recurring;
    final String? transferId;
    final List<Tag> tags;

    Transaction({
        required this.id,
        required this.name,
        required this.date,
        required this.amount,
        this.description,
        required this.categoryId,
        this.categoryName,
        this.categoryColor,
        required this.methodId,
        required this.methodType,
        this.accountId,
        this.accountName,
        this.bankName,
        required this.recurring,
        this.transferId,
        required this.tags,
    });

    factory Transaction.fromJson(Map<String, dynamic> json) {
        final category = json['category'] as Map<String, dynamic>?;
        final method = json['method'] as Map<String, dynamic>;
        final account = method['account'] as Map<String, dynamic>?;
        final bank = account?['bank'] as Map<String, dynamic>?;
        return Transaction(
            id: json['transac_id'] as int,
            name: json['transac_name'] as String,
            date: DateTime.parse(json['transac_date'] as String),
            amount: double.parse(json['transac_amount'].toString()),
            description: json['transac_description'] as String?,
            categoryId: json['category_id'] as int?,
            categoryName: category?['category_name'] as String?,
            categoryColor: category?['category_color'] as String?,
            methodId: json['transmet_id'] as int,
            methodType: method['transmet_type'] as String,
            accountId: account?['account_id'] as int?,
            accountName: account?['account_name'] as String?,
            bankName: bank?['bank_name'] as String?,
            recurring: json['rectrans_id'] != null,
            transferId: json['transac_transfer_id'] as String?,
            tags: (json['tags'] as List).map((e) => Tag.fromJson(e)).toList(),
        );
    }

    bool get isTransfer => transferId != null;

    String get subtitle => methodLabel(methodType, accountName: accountName, bankName: bankName);
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

    Future<void> save({
      int? id,
      required String name,
      required DateTime date,
      required double amount,
      String? description,
      required int methodId,
      int? categoryId,
      List<int> tagIds = const[],
    }) async {
      final data = {
        'transac_name': name,
        'transac_date': date.toIso8601String(),
        'transac_amount': amount.toStringAsFixed(2),
        'transac_description': description,
        'transmet_id': methodId,
        'category_id': categoryId,
        'tag_ids': tagIds,
      };
      if (id == null) {
        await _dio.post('/transactions/', data: data);
      } else {
        await _dio.patch('/transactions/$id', data:data);
      }
    }

    Future<void> createTransfer({
      required int fromAccountId,
      required int toAccountId,
      required double amount,
      required DateTime date,
      required String name,
      String? description,
    }) async {
      await _dio.post('/transfers/', data: {
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount.toStringAsFixed(2),
        'transfer_date': date.toIso8601String(),
        'name': name,
        'description': description,
      });
    }

    Future<void> rename(int id, {required String name, String? description}) =>
      _dio.patch('/transactions/$id', data: {
        'transac_name': name,
        'transac_description': description,
      });

    Future<void> delete(int id) => _dio.delete('/transactions/$id');
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
    return TransactionsRepository(ref.watch(dioProvider));
});

final transactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) {
    return ref.watch(transactionsRepositoryProvider).getAll();
});