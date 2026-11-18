import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/pill_segmented.dart';
import '../../core/widgets/section_card.dart';
import '../recurring/recurring_screen.dart';
import 'banks_card.dart';
import 'labels_card.dart';
import 'methods_card.dart';

List<Widget> _spaced(List<Widget> cards) => [
  for (final (i, c) in cards.indexed) ...[
    if (i > 0) const SizedBox(height: 14),
    c,
  ],
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final palette = context.palette;
    const left = <Widget>[_AppearanceCard(), BanksCard(), MethodsCard()];
    const right = <Widget>[CategoriesCard(), TagsCard(), _OtherSettingsCard()];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 16, wide ? 20 : 12, wide ? 24 : 16, 24),
        children: [
          Text(
            'Paramètres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: palette.ink),
          ),
          Text(
            'Crée, modifie et archive tes comptes, catégories, tags et paiements récurrents.',
            style: TextStyle(fontSize: 12.5, color: palette.muted),
          ),
          const SizedBox(height: 16),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(left)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(right)),
                ),
              ],
            )
          else
            ..._spaced([...left, ...right]),
        ],
      ),
    );
  }
}

/// Temporaire : liens vers les anciens écrans, remplacés en R6b et R6c.
class _OtherSettingsCard extends StatelessWidget {
  const _OtherSettingsCard();

  @override
  Widget build(BuildContext context) {
    Widget link(IconData icon, String title, Widget screen) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
    );

    return SectionCard(
      title: 'Autres réglages',
      child: Column(
        children: [
          link(Icons.repeat, 'Paiements récurrents', const RecurringScreen()),
        ],
      ),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final brightness = Theme.of(context).brightness;
    final labelStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: context.palette.muted,
    );

    return SectionCard(
      title: '🎨 Apparence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couleur de l'application", style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final a in AccentColor.values)
                InkWell(
                  onTap: () => controller.setAccent(a),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: settings.accent == a ? a.main(brightness) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: a.main(Brightness.light),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Thème', style: labelStyle),
          const SizedBox(height: 8),
          PillSegmented<ThemeMode>(
            expand: true,
            options: const [
              (ThemeMode.light, '☀ Clair'),
              (ThemeMode.dark, '☾ Sombre'),
              (ThemeMode.system, '⌘ Système'),
            ],
            selected: settings.mode,
            onChanged: controller.setMode,
          ),
        ],
      ),
    );
  }
}