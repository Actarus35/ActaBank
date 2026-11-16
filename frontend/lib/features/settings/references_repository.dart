import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Category {
  final int id;
  final String name;
  final String color;

  Category({required this.id, required this.name, required this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'] as int,
      name: json['category_name'] as String,
      color: json['category_color'] as String,
    );
  }
}

class TransactionMethod {
  final int id;
  final String type;
  final String? accountName;

  TransactionMethod({required this.id, required this.type, this.accountName});

  factory TransactionMethod.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    return TransactionMethod(
      id: json['transmet_id'] as int,
      type: json['transmet_type'] as String,
      accountName: account?['account_name'] as String?,
    );
  }

  String get displayName => accountName == null ? type : '$type · $accountName';
}

class Tag {
  final int id;
  final String name;
  final String color;

  Tag({required this.id, required this.name, required this.color});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['tag_id'] as int,
      name: json['tag_name'] as String,
      color: json['tag_color'] as String,
    );
  }
}

class Bank {
  final int id;
  final String name;
  final String color;

  Bank({required this.id, required this.name, required this.color});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['bank_id'] as int,
      name: json['bank_name'] as String,
      color: json['bank_color'] as String,
    );
  }
}

const accountTypeLabels = {
  'COMPTE_COURANT': 'Compte courant',
  'LIVRET_A': 'Livret A',
  'LIVRET_JEUNE': 'Livret Jeune',
  'PORTEFEUILLE': 'Portefeuille',
};

class Account {
  final int id;
  final String name;
  final String type;
  final double initialBalance;
  final int bankId;
  final String? bankName;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.bankId,
    this.bankName,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final bank = json['bank'] as Map<String, dynamic>?;
    return Account(
      id: json['account_id'] as int,
      name: json['account_name'] as String,
      type: json['account_type'] as String,
      initialBalance: double.parse(json['account_initial_balance'].toString()),
      bankId: json['bank_id'] as int,
      bankName: bank?['bank_name'] as String?,
    );
  }

  String get typeLabel => accountTypeLabels[type] ?? type;
}

class ReferencesRepository {
  final Dio _dio;
  ReferencesRepository(this._dio);

  Future<void> saveCategory({int? id, required String name, required String color}) async {
    final data = {'category_name': name, 'category_color': color};
    if (id == null) {
      await _dio.post('/categories/', data: data);
    } else {
      await _dio.patch('/categories/$id', data: data);
    }
  }

  Future<void> saveTag({int? id, required String name, required String color}) async {
    final data = {'tag_name': name, 'tag_color': color};
    if (id == null) {
      await _dio.post('/tags/', data: data);
    } else {
      await _dio.patch('/tags/$id', data: data);
    }
  }

  Future<void> saveBank({int? id, required String name, required String color}) async {
    final data = {'bank_name': name, 'bank_color': color};
    if (id == null) {
      await _dio.post('/banks/', data: data);
    } else {
      await _dio.patch('/banks/$id', data: data);
    }
  }

  Future<void> saveAccount({
    int? id,
    required String name,
    required String type,
    required double initialBalance,
    required int bankId,
  }) async {
    final data = {
      'account_name': name,
      'account_type': type,
      'account_initial_balance': initialBalance.toStringAsFixed(2),
      'bank_id': bankId,
    };
    if (id == null) {
      await _dio.post('/accounts/', data: data);
    } else {
      await _dio.patch('accounts/$id', data: data);
    }
  }

  Future<void> deleteCategory(int id) => _dio.delete('/categories/$id');

  Future<void> deleteTag(int id) => _dio.delete('/tags/$id');

  Future<void> deleteBank(int id) => _dio.delete('/banks/$id');

  Future<void> deleteAccount(int id) => _dio.delete('/banks/$id');

}

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final response = await ref.watch(dioProvider).get('/categories/');
  return (response.data as List)
    .map((e) => Category.fromJson(e))
    .toList();
});

final banksProvider = FutureProvider.autoDispose<List<Bank>>((ref) async {
  final response = await ref.watch(dioProvider).get('/banks/');
  return (response.data as List)
    .map((e) => Bank.fromJson(e))
    .toList();
});

final accountsProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  final response = await ref.watch(dioProvider).get('/accounts/');
  return (response.data as List)
    .map((e) => Account.fromJson(e))
    .toList();
});

final transactionMethodsProvider = FutureProvider.autoDispose<List<TransactionMethod>>((ref) async {
  final response = await ref.watch(dioProvider).get('/transaction_methods/');
  return (response.data as List)
    .map((e) => TransactionMethod.fromJson(e))
    .toList();
});

final tagsProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  final response = await ref.watch(dioProvider).get('/tags/');
  return (response.data as List)
    .map((e) => Tag.fromJson(e))
    .toList();
});

final referencesRepositoryProvider = Provider<ReferencesRepository>((ref) {
  return ReferencesRepository(ref.watch(dioProvider));
});