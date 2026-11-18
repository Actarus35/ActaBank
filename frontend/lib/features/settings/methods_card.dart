import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/section_card.dart';
import 'banks_card.dart';
import 'references_repository.dart';
import 'settings_actions.dart';

class MethodsCard extends ConsumerWidget {
  const MethodsCard({super.key});

  static IconData _icon(String type) => switch (type) {
    'CARTE' => Icons.credit_card,
    'VIREMENT' => Icons.swap_horiz,
    'CHEQUE' => Icons.edit_note,
    _ => Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(transactionMethodsProvider);
    final palette = context.palette;

    Widget row(TransactionMethod m) => Row(
      children: [
        Icon(_icon(m.type), size: 18, color: palette.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            m.displayName,
            style: TextStyle(fontSize: 13, color: m.archived ? palette.muted : palette.ink),
          ),
        ),
        ItemMenu(
          archived: m.archived,
          onEdit: () => openMethodForm(context, ref, method: m),
          onArchive: () => toggleMethodArchived(context, ref, m),
          onDelete: () => deleteMethod(context, ref, m),
        ),
      ],
    );

    return SectionCard(
      title: '💳 Moyens de paiement',
      trailing: TextButton.icon(
        onPressed: () => openMethodForm(context, ref),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Ajouter'),
      ),
      child: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (list) {
          final active = list.where((m) => !m.archived).toList();
          final archived = list.where((m) => m.archived).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (active.isEmpty)
                Text('Aucun moyen de paiement actif', style: TextStyle(color: palette.muted)),
              for (final m in active) row(m),
              if (archived.isNotEmpty)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text(
                      'Archivés (${archived.length})',
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    children: [for (final m in archived) row(m)],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}