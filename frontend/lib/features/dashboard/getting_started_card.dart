import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/section_card.dart';
import '../settings/references_repository.dart';
import '../settings/settings_actions.dart';
import '../transactions/transactions_repository.dart';

final setupStepsProvider = Provider.autoDispose<List<bool>?>((ref) {
  final banks = ref.watch(banksProvider).valueOrNull;
  final accounts = ref.watch(accountsProvider).valueOrNull;
  final methods = ref.watch(transactionMethodsProvider).valueOrNull;
  final transactions = ref.watch(transactionsProvider).valueOrNull;
  if (banks == null || accounts == null || methods == null || transactions == null) return null;
  return [
    banks.isNotEmpty || accounts.isNotEmpty, // un compte sans banque (portefeuille) suffit
    accounts.isNotEmpty,
    methods.isNotEmpty,
    transactions.isNotEmpty,
  ];
});

class GettingStartedCard extends ConsumerWidget {
  final List<bool> done;
  const GettingStartedCard({super.key, required this.done});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = <(String, String, VoidCallback?)>[
      ('Crée ta banque', 'Ex. : CIC, Crédit Agricole… (facultatif pour des espèces)', () => editBank(context, ref)),
      ('Ajoute un compte', 'Compte courant, livret, portefeuille…', () => openAccountForm(context, ref)),
      ('Ajoute un moyen de paiement', 'La carte ou le virement lié à ce compte', () => openMethodForm(context, ref)),
      ('Saisis ta première transaction', 'Onglet Transactions, bouton +', null),
    ];
    final next = done.indexOf(false); // première étape non faite

    return SectionCard(
      title: '👋 Premiers pas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quatre étapes pour commencer à suivre tes comptes :',
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              number: i + 1,
              title: steps[i].$1,
              subtitle: steps[i].$2,
              done: done[i],
              current: i == next,
              onTap: steps[i].$3,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final VoidCallback? onTap;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // État donné par la FORME (✓ ou numéro), pas seulement par la couleur
          done
            ? Icon(Icons.check_circle, color: palette.pos, size: 26)
            : CircleAvatar(
                radius: 13,
                backgroundColor: current ? primary : palette.border,
                child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '$title — fait' : title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: done ? palette.muted : palette.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!done) Text(subtitle, style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
          if (current && onTap != null) FilledButton(onPressed: onTap, child: const Text('Commencer')),
        ],
      ),
    );
  }
}