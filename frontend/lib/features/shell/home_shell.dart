import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/pill_segmented.dart';
import '../auth/user_avatar.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    if (isWide(context)) {
      return Scaffold(
        body: Column(
          children: [
            _TopBar(index: _index, onSelect: _select),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: _screens[_index],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _TopBar({
    required this.index,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final mode = ref.watch(themeControllerProvider).mode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
            child: const Text(
              'A',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Actabank',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: palette.ink),
          ),
          const SizedBox(width: 24),
          _NavPill(label: 'Tableau de bord', selected: index == 0, onTap: () => onSelect(0)),
          const SizedBox(width: 4),
          _NavPill(label: 'Transactions', selected: index == 1, onTap: () => onSelect(1)),
          const Spacer(),
          PillSegmented<ThemeMode>(
            options: const [
              (ThemeMode.light, '☀'),
              (ThemeMode.dark, '☾'),
              (ThemeMode.system, '⌘'),
            ],
            selected: mode,
            onChanged: ref.read(themeControllerProvider.notifier).setMode,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () => onSelect(2),
            icon: Icon(
              Icons.settings_outlined,
              color: index == 2 ? scheme.primary : palette.muted,
            ),
          ),
          const SizedBox(width: 4),
          const UserAvatar(),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.ink : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? palette.card : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}