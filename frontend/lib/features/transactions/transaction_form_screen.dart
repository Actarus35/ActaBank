import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../settings/references_repository.dart';
import 'transactions_repository.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  bool _isExpense = true;
  DateTime _date = DateTime.now();
  int? _methodId;
  int? _labelId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null;});

    final value = double.parse(_amount.text.replaceAll(',', '.'));
    final description = _description.text.trim();

    try {
      await ref.read(transactionsRepositoryProvider).create(
          name: _name.text.trim(),
          date: _date,
          amount: _isExpense ? -value : value,
          description: description.isEmpty ? null : description,
          methodId: _methodId!,
          labelId: _labelId,
        );
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Impossible d'enregistrer la transaction";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(transactionMethodsProvider);
    final labels = ref.watch(labelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle transaction')),
      body: Center(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Dépense')),
                  ButtonSegment(value: false, label: Text('Revenu')),
                ],
                selected: {_isExpense},
                onSelectionChanged: (s) =>
                  setState(() => _isExpense = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Libellé'),
                validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant', suffixText: '€'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return (n == null || n <= 0)
                    ? 'Montant positif attendu'
                    : null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(formatDate(_date)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              methods.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Moyens de paiement indisponibles'),
                data: (list) => DropdownButtonFormField<int>(
                  initialValue: _methodId,
                  decoration: const InputDecoration(labelText: 'Moyen de paiement'),
                  items: [
                    for (final m in list)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text(m.displayName)
                      )
                  ],
                  onChanged: (v) => setState(() => _methodId = v),
                  validator: (v) => v == null ? 'Obligatoire' : null,
                ),
              ),
              const SizedBox(height: 12),
              labels.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Labels indisponibles'),
                data: (list) => DropdownButtonFormField<int?>(
                  initialValue: _labelId,
                  decoration: const InputDecoration(labelText: 'Label'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sans label')),
                    for (final l in list)
                      DropdownMenuItem(value: l.id, child: Text(l.name)),
                  ],
                  onChanged: (v) => setState(() => _labelId = v),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description (optionnel)'),
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
      )
    );
  }
}