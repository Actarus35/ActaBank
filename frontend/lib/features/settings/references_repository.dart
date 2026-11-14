import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Label {
  final int id;
  final String name;
  final String color;

  Label({required this.id, required this.name, required this.color});

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['label_id'] as int,
      name: json['label_name'] as String,
      color: json['label_color'] as String,
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

final labelsProvider = FutureProvider.autoDispose<List<Label>>((ref) async {
  final response = await ref.watch(dioProvider).get('/labels/');
  return (response.data as List)
    .map((e) => Label.fromJson(e))
    .toList();
});

final transactionMethodsProvider = FutureProvider.autoDispose<List<TransactionMethod>>((ref) async {
  final response = await ref.watch(dioProvider).get('/transaction_methods/');
  return (response.data as List)
    .map((e) => TransactionMethod.fromJson(e))
    .toList();
});