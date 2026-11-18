import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'references_repository.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;
  final int? initialBankId;

  const AccountFormScreen({super.key, this.account, this.initialBankId});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0.00');

  String? _type;
  int? _bankId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _name.text = a.name;
      _balance.text = a.initialBalance.toStringAsFixed(2);
      _type = a.type;
      _bankId = a.bankId;
    } else {
      _bankId = widget.initialBankId;
      _type = 'COURANT';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final typed = _name.text.trim();
    final name = typed.isEmpty ? accountTypeLabels[_type]! : typed;

    try {
      await ref.read(referencesRepositoryProvider).saveAccount(
        id: widget.account?.id,
        name: name,
        type: _type!,
        initialBalance: double.parse(_balance.text.replaceAll(',', '.')),
        bankId: _type == 'PORTEFEUILLE' ? null : _bankId,
      );
      ref.invalidate(accountsProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Impossible d'enregistrer le compte";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(banksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Nouveau compte' : 'Modifier le compte'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in accountTypeLabels.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _type == e.key,
                    onSelected: (_) => setState(() => _type = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nom (facultatif)',
                hintText: accountTypeLabels[_type],
                helperText: 'Ex. Livret A, Compte joint, PEA…',
              ),
            ),
            const SizedBox(height: 12),
            if (_type != 'PORTEFEUILLE') ...[
              banks.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Banques indisponibles'),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _bankId,
                decoration: InputDecoration(
                  labelText: 'Banque',
                  helperText: list.isEmpty ? "Crée d'abord une banque" : null,
                ),
                items: [
                  for (final b in list.where((b) => !b.archived || b.id == _bankId))
                    DropdownMenuItem(value: b.id, child: Text(b.name)),
                ],
                onChanged: (v) => setState(() => _bankId = v),
                validator: (v) => v == null ? 'Obligatoire' : null,
              ),
            ),
            const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Solde initial', suffixText: '€'),
              validator: (v) =>
                double.tryParse((v ?? '').replaceAll(',', '.')) == null
                  ? 'Nombre attendu'
                  : null,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}