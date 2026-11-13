import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/token_storage.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _storage;
  AuthRepository(this._dio, this._storage);

  Future<void> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    await _storage.save(response.data['access_token'] as String);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});