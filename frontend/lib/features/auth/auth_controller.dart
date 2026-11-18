import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'auth_repository.dart';

class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.read(tokenStorageProvider).read();
    return token != null;
  }

  Future<void> login(String username, String password) async {
    await ref.read(authRepositoryProvider).login(username, password);
    state = const AsyncData(true);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(false);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(AuthController.new);
