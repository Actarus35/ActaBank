import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'references_repository.dart';

class MethodFormScreen extends ConsumerStatefulWidget {
  final TransactionMethod? method;

  const MethodFormScreen({super.key, this.method});

  @override
  ConsumerState<MethodFormScreen> createState() => _MethodFormScreenState();
}

class _MethodFormScreenState extends ConsumerState<MethodFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _type;
  int? _accountId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.method;
    if (a != null) {
      _type = a.type;
      _accountId = a.accountId;
    }
  }


    Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(referencesRepositoryProvider).saveMethod(
        id: widget.method?.id,
        type: _type!,
        accountId: _accountId,
      );
      ref.invalidate(transactionMethodsProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Impossible d'enregistrer le moyen de paiement";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.method == null ? 'Nouvelle méthode' : 'Modifier la méthode'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final e in methodTypeLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            accounts.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Comptes indisponibles'),
              data: (list) => DropdownButtonFormField<int?>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Compte'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucun compte')),
                  for (final a in list)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
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