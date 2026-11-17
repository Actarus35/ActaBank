import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../settings/references_repository.dart';
import 'recurring_repository.dart';

class RecurringFormScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? rule;

  const RecurringFormScreen({super.key, this.rule});

  @override
  ConsumerState<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();

  bool _isExpense = true;
  String? _frequency;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _methodId;
  int? _categoryId;
  final Set<int> _tagIds = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    if (r != null) {
      _name.text = r.name;
      _amount.text = r.amount.abs().toStringAsFixed(2);
      _isExpense = r.amount < 0;
      _frequency = r.frequency;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _methodId = r.methodId;
      _categoryId = r.categoryId;
      _tagIds.addAll(r.tags.map((tag) => tag.id));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endDate ?? _startDate) : _startDate,
      firstDate: isEnd ? _startDate : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final value = double.parse(_amount.text.replaceAll(',', '.'));

    try {
      await ref.read(recurringRepositoryProvider).save(
        id: widget.rule?.id,
        name: _name.text.trim(),
        amount: _isExpense ? -value : value,
        frequency: _frequency!,
        startDate: _startDate,
        endDate: _endDate,
        methodId: _methodId!,
        categoryId: _categoryId,
        tagIds: _tagIds.toList(),
      );
      ref.invalidate(recurringProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Impossible d'enregistrer la récurrence";
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette récurrence ?'),
        content: const Text('Les transactions déjà générées seront conservées.'),
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
      await ref.read(recurringRepositoryProvider).delete(widget.rule!.id);
      ref.invalidate(recurringProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossible de supprimer la récurrence';
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
        title: Text(widget.rule == null ? 'Nouvelle récurrence' : 'Modifier la récurrence'),
        actions: [
          if (widget.rule != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
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
              onSelectionChanged: (s) => setState(() => _isExpense = s.first),
            ),
            if (widget.rule == null) ...[
              const SizedBox(height: 8),
              Text(
                'Les échéances déjà passées depuis la date de début seront créées immédiatement.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
                return (n == null || n <= 0) ? 'Montant positif attendu' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Fréquence'),
              items: [
                for (final e in frequencyLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _frequency = v),
              validator: (v) => v == null ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Début : ${formatDate(_startDate)}'),
              onTap: () => _pickDate(isEnd: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: Text(_endDate == null
                ? 'Sans date de fin'
                : 'Fin : ${formatDate(_endDate!)}'),
              onTap: () => _pickDate(isEnd: true),
              trailing: _endDate == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _endDate = null),
                  ),
            ),
            const SizedBox(height: 12),
            methods.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Moyens de paiement indisponibles'),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _methodId,
                decoration: const InputDecoration(labelText: 'Moyen de paiement'),
                items: [
                  for (final m in list.where((m) => !m.archived || m.id == _methodId))
                    DropdownMenuItem(
                      value: m.id,
                      child: Text(m.archived ? '${m.displayName} (archivé)' : m.displayName),
                    ),
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
                  const DropdownMenuItem(value: null, child: Text('Sans catégorie')),
                  for (final c in list)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
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