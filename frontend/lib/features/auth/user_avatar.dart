import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUsernameProvider).valueOrNull ?? '';
    final tone = labelTone('ORANGE', Theme.of(context).brightness);

    return PopupMenuButton<String>(
      tooltip: 'Mon compte',
      onSelected: (value) {
        if (value == 'logout') ref.read(authControllerProvider.notifier).logout();
      },
      itemBuilder: (_) => [
        if (name.isNotEmpty) PopupMenuItem(enabled: false, child: Text(name)),
        const PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: tone.background,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(color: tone.text, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
