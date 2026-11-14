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

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final response = await ref.watch(dioProvider).get('/categories/');
  return (response.data as List)
    .map((e) => Category.fromJson(e))
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