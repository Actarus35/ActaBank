import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_storage.dart';
import '../features/auth/auth_controller.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
    final storage = ref.watch(tokenStorageProvider);
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
            final token = await storage.read();
            if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
        },
        onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
                await ref.read(authControllerProvider.notifier).logout();
            }
            handler.next(error);
        }
    ));

    return dio;
});