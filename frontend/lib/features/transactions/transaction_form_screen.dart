import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../settings/references_repository.dart';
import 'transactions_repository.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

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
  int? _categoryId;
  final Set<int> _tagIds = {};
  bool _saving = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _name.text = t.name;
      _amount.text = t.amount.abs().toStringAsFixed(2);
      _description.text = t.description ?? '';
      _isExpense = t.amount < 0;
      _date = t.date;
      _methodId = t.methodId;
      _categoryId = t.categoryId;
      _tagIds.addAll(t.tags.map((tag) => tag.id));
    }
  }

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
      await ref.read(transactionsRepositoryProvider).save(
          id: widget.transaction?.id,
          name: _name.text.trim(),
          date: _date,
          amount: _isExpense ? -value : value,
          description: description.isEmpty ? null : description,
          methodId: _methodId!,
          categoryId: _categoryId,
          tagIds: _tagIds.toList(),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette transaction ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(transactionsRepositoryProvider).delete(widget.transaction!.id);
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossible de supprimer la transaction';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(transactionMethodsProvider);
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
          ? 'Nouvelle transaction'
          : 'Modifier la transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
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
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Catégories indisponibles'),
                data: (list) => DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sans catégorie')),
                    for (final l in list)
                      DropdownMenuItem(value: l.id, child: Text(l.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 12),
              tags.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Tags indisponibles'),
                data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                    spacing: 8,
                    children: [
                      for (final t in list)
                        FilterChip(
                          label: Text(t.name),
                          selected: _tagIds.contains(t.id),
                          onSelected: (on) => setState(() {
                            on ? _tagIds.add(t.id) : _tagIds.remove(t.id);
                          }),
                        ),
                    ],
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