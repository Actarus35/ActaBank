import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/section_card.dart';
import '../dashboard/stats_repository.dart';
import 'references_repository.dart';
import 'settings_actions.dart';

class BanksCard extends ConsumerWidget {
  const BanksCard({super.key});

  Widget _bankMenu(BuildContext context, WidgetRef ref, Bank b) => ItemMenu(
    archived: b.archived,
    onEdit: () => editBank(context, ref, b),
    onArchive: () => toggleBankArchived(context, ref, b),
    onDelete: () => deleteBank(context, ref, b),
  );

  Widget _accountMenu(BuildContext context, WidgetRef ref, Account a) => ItemMenu(
    archived: a.archived,
    onEdit: () => openAccountForm(context, ref, account: a),
    onArchive: () => toggleAccountArchived(context, ref, a),
    onDelete: () => deleteAccount(context, ref, a),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(banksProvider);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final balances = {
      for (final b in ref.watch(balancesProvider).valueOrNull?.accounts ?? const <AccountBalance>[])
        b.id: b.balance,
    };
    double balanceOf(Account a) => balances[a.id] ?? a.initialBalance;
    final palette = context.palette;

    return SectionCard(
      title: '🏦 Banques & comptes',
      trailing: TextButton.icon(
        onPressed: () => editBank(context, ref),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Banque'),
      ),
      child: banks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur : $e'),
        data: (bankList) {
          final activeBanks = bankList.where((b) => !b.archived).toList();
          final activeAccounts = accounts.where((a) => !a.archived).toList();
          final wallets = activeAccounts.where((a) => a.bankId == null).toList();
          final archived = <Widget>[
            for (final b in bankList.where((b) => b.archived))
              _ArchivedRow(name: b.name, subtitle: 'Banque', menu: _bankMenu(context, ref, b)),
            for (final a in accounts.where((a) => a.archived))
              _ArchivedRow(
                name: a.name,
                subtitle: '${a.bankName ?? 'Portefeuille'} · ${a.typeLabel}',
                menu: _accountMenu(context, ref, a),
              ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (activeBanks.isEmpty && wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("Aucune banque pour l'instant", style: TextStyle(color: palette.muted)),
                ),
              for (final b in activeBanks)
                _BankGroup(
                  title: b.name,
                  colorName: b.color,
                  accounts: [for (final a in activeAccounts) if (a.bankId == b.id) a],
                  balanceOf: balanceOf,
                  menu: _bankMenu(context, ref, b),
                  accountMenu: (a) => _accountMenu(context, ref, a),
                  onAddAccount: () => openAccountForm(context, ref, bankId: b.id),
                ),
              if (wallets.isNotEmpty)
                _BankGroup(
                  title: 'Portefeuille',
                  accounts: wallets,
                  balanceOf: balanceOf,
                  accountMenu: (a) => _accountMenu(context, ref, a),
                  onAddAccount: () => openAccountForm(context, ref),
                ),
              if (activeBanks.isEmpty && wallets.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openAccountForm(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Compte'),
                  ),
                ),
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
                    children: archived,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BankGroup extends StatefulWidget {
  final String title;
  final String? colorName;
  final List<Account> accounts;
  final double Function(Account) balanceOf;
  final Widget? menu;
  final Widget Function(Account) accountMenu;
  final VoidCallback onAddAccount;

  const _BankGroup({
    required this.title,
    this.colorName,
    required this.accounts,
    required this.balanceOf,
    this.menu,
    required this.accountMenu,
    required this.onAddAccount,
  });

  @override
  State<_BankGroup> createState() => _BankGroupState();
}

class _BankGroupState extends State<_BankGroup> {
  bool _expanded = true;

  static IconData _icon(String type) => switch (type) {
    'PORTEFEUILLE' => Icons.account_balance_wallet_outlined,
    'COMPTE_COURANT' => Icons.credit_card,
    _ => Icons.savings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final palette = context.palette;
    final tone = labelTone(w.colorName, Theme.of(context).brightness);
    final total = w.accounts.fold<double>(0, (sum, a) => sum + w.balanceOf(a));
    final separator = BoxDecoration(border: Border(top: BorderSide(color: palette.border)));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: palette.soft,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                      color: palette.muted,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(color: tone.solid, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                    ),
                    Text(
                      formatAmount(total, signed: total < 0),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.muted),
                    ),
                    w.menu ?? const SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            for (final a in w.accounts)
              Container(
                decoration: separator,
                padding: const EdgeInsets.fromLTRB(14, 4, 2, 4),
                child: Row(
                  children: [
                    Icon(_icon(a.type), size: 18, color: palette.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: TextStyle(fontSize: 13, color: palette.ink)),
                          if (a.name != a.typeLabel)
                            Text(a.typeLabel, style: TextStyle(fontSize: 11, color: palette.muted)),
                        ],
                      ),
                    ),
                    Text(
                      formatAmount(w.balanceOf(a), signed: w.balanceOf(a) < 0),
                      style: TextStyle(fontSize: 13, color: palette.ink),
                    ),
                    w.accountMenu(a),
                  ],
                ),
              ),
            Container(
              decoration: separator,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: w.onAddAccount,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Compte'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget menu;

  const _ArchivedRow({required this.name, required this.subtitle, required this.menu});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 13, color: palette.muted)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: palette.muted)),
            ],
          ),
        ),
        menu,
      ],
    );
  }
}

enum _MenuAction { edit, archive, delete }

/// Menu « ⋮ » commun : modifier, archiver ou désarchiver, supprimer.
class ItemMenu extends StatelessWidget {
  final bool archived;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const ItemMenu({
    super.key,
    required this.archived,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) => ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Actions',
      icon: Icon(Icons.more_vert, size: 18, color: context.palette.muted),
      onSelected: (action) => switch (action) {
        _MenuAction.edit => onEdit(),
        _MenuAction.archive => onArchive(),
        _MenuAction.delete => onDelete(),
      },
      itemBuilder: (_) => [
        if (!archived)
          PopupMenuItem(value: _MenuAction.edit, child: item(Icons.edit_outlined, 'Modifier')),
        PopupMenuItem(
          value: _MenuAction.archive,
          child: item(
            archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            archived ? 'Désarchiver' : 'Archiver',
          ),
        ),
        PopupMenuItem(value: _MenuAction.delete, child: item(Icons.delete_outline, 'Supprimer')),
      ],
    );
  }
}