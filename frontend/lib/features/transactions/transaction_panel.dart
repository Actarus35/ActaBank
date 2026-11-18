import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/tag_chip.dart';
import '../../core/widgets/pill_segmented.dart';
import '../recurring/recurring_repository.dart';
import '../settings/references_repository.dart';
import 'transactions_repository.dart';

class TransactionPanel extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final VoidCallback onClose;

  const TransactionPanel({super.key, this.transaction, required this.onClose});

  @override
  ConsumerState<TransactionPanel> createState() => _TransactionPanelState();
}

class _TransactionPanelState extends ConsumerState<TransactionPanel> {
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
  bool _showDescription = false;
  bool _recurring = false;
  String _frequency = 'MONTHLY';

  String get _recurringHint {
    final every = switch (_frequency) {
      'WEEKLY' => 'chaque semaine',
      'YEARLY' => 'chaque année',
      _ => 'chaque mois',
    };
    final start = formatLongDate(_date);
    return _date.isAfter(DateTime.now())
      ? 'Créée $every à partir du $start.'
      : 'Créée $every depuis le $start, occurrences déjà passées comprises.';
  }

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _name.text = t.name;
      _amount.text = t.amount.abs().toStringAsFixed(2).replaceAll('.', ',');
      _description.text = t.description ?? '';
      _showDescription = _description.text.isNotEmpty;
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
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final value = double.parse(_amount.text.replaceAll(',', '.'));
    final description = _description.text.trim();

    try {
      final amount = _isExpense ? -value : value;
      if (_recurring) {
        await ref.read(recurringRepositoryProvider).save(
          name: _name.text.trim(),
          amount: amount,
          frequency: _frequency,
          startDate: _date,
          methodId: _methodId!,
          categoryId: _categoryId,
          tagIds: _tagIds.toList(),
        );
        ref.invalidate(recurringProvider);
      } else {
        await ref.read(transactionsRepositoryProvider).save(
          id: widget.transaction?.id,
          name: _name.text.trim(),
          date: _date,
          amount: amount,
          description: description.isEmpty ? null : description,
          methodId: _methodId!,
          categoryId: _categoryId,
          tagIds: _tagIds.toList(),
        );
      }
      ref.invalidate(transactionsProvider);
      if (mounted) widget.onClose();
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(transactionsRepositoryProvider).delete(widget.transaction!.id);
      ref.invalidate(transactionsProvider);
      if (mounted) widget.onClose();
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
    return LayoutBuilder(
      builder: (context, c) => _buildForm(context, c.maxHeight),
    );
  }

  Widget _buildForm(BuildContext context, double height) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final methods = ref.watch(transactionMethodsProvider).valueOrNull ?? const <TransactionMethod>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final editing = widget.transaction != null;

    final tight = height < 680;
    final gap = SizedBox(height: height >= 820 ? 14 : tight ? 6 : 10);

    final amountField = TextFormField(
      controller: _amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: tight ? 20 : 24, fontWeight: FontWeight.w700, color: palette.ink),
      decoration: InputDecoration(
        hintText: '0,00',
        suffixText: '€',
        suffixStyle: TextStyle(fontSize: tight ? 16 : 19, fontWeight: FontWeight.w600, color: palette.muted),
      ),
      validator: (v) {
        final n = double.tryParse((v ?? '').replaceAll(',', '.'));
        return (n == null || n <= 0) ? 'Montant positif attendu' : null;
      },
    );

    final dateField = InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(formatLongDate(_date), overflow: TextOverflow.ellipsis),
      ),
    );

    final form = Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, tight ? 8 : 14, 20, tight ? 14 : 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editing ? 'Modifier la transaction' : 'Ajouter une transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.ink),
                ),
              ),
              if (editing)
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving ? null : _delete,
                ),
              IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close),
                onPressed: _saving ? null : widget.onClose,
              ),
            ],
          ),
          SizedBox(height: tight ? 2 : 8),
          _TypeToggle(
            isExpense: _isExpense,
            onChanged: (v) => setState(() => _isExpense = v),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const _FieldLabel('Montant'), amountField],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const _FieldLabel('Date'), dateField],
                ),
              ),
            ],
          ),
          gap,
          const _FieldLabel('Nom'),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Ex. Carrefour'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
          ),
          gap,
          const _FieldLabel('Catégorie'),
          if (categories.isEmpty)
            Text('Aucune catégorie — crée-en dans les paramètres', style: TextStyle(color: palette.muted))
          else
            Wrap(
              spacing: 7,
              runSpacing: tight ? 5 : 7,
              children: [
                for (final c in categories)
                  _CategoryChip(
                    label: c.name,
                    colorName: c.color,
                    selected: _categoryId == c.id,
                    onTap: () => setState(() => _categoryId = _categoryId == c.id ? null : c.id),
                  ),
              ],
            ),
          if (tags.isNotEmpty) ...[
            gap,
            const _FieldLabel('Tags'),
            Wrap(
              spacing: 7,
              runSpacing: tight ? 5 : 7,
              children: [
                for (final g in tags)
                  TagChip(
                    label: g.name,
                    colorName: g.color,
                    selected: _tagIds.contains(g.id),
                    onTap: () => setState(() {
                      _tagIds.contains(g.id) ? _tagIds.remove(g.id) : _tagIds.add(g.id);
                    }),
                  ),
              ],
            ),
          ],
          gap,
          const _FieldLabel('Moyen de paiement'),
          DropdownButtonFormField<int>(
            initialValue: _methodId,
            isExpanded: true,
            items: [
              for (final m in methods.where((m) => !m.archived || m.id == _methodId))
                DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    m.archived ? '${m.displayName} (archivé)' : m.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _methodId = v),
            validator: (v) => v == null ? 'Obligatoire' : null,
          ),
          if (!editing) ...[
            gap,
            _RecurringToggle(
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
            if (_recurring) ...[
              SizedBox(height: tight ? 6 : 8),
              PillSegmented<String>(
                options: const [
                  ('WEEKLY', 'Hebdo'),
                  ('MONTHLY', 'Mensuel'),
                  ('YEARLY', 'Annuel'),
                ],
                selected: _frequency,
                expand: true,
                onChanged: (f) => setState(() => _frequency = f),
              ),
              const SizedBox(height: 6),
              Text(_recurringHint, style: TextStyle(fontSize: 11.5, color: palette.muted)),
            ],
          ] else if (widget.transaction!.recurring) ...[
            gap,
            Text(
              '↻ Générée par un paiement récurrent : la modifier ne change que cette occurrence.',
              style: TextStyle(fontSize: 11.5, color: palette.muted),
            ),
          ],
          if (!_recurring) ...[
            gap,
            if (tight && !_showDescription)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showDescription = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter une description'),
                ),
              )
            else ...[
              const _FieldLabel('Description (facultatif)'),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: tight ? 2 : 3,
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: palette.neg)),
          ],
          SizedBox(height: tight ? 12 : 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onClose,
                  style: OutlinedButton.styleFrom(minimumSize: Size(0, tight ? 42 : 48)),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: Size(0, tight ? 42 : 48)),
                  child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!tight) return form;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      child: form,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.palette.muted),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget segment(bool expense) {
      final selected = expense == isExpense;
      final background = expense ? palette.negBg : palette.posBg;
      final foreground = expense ? palette.neg : palette.posText;
      return Expanded(
        child: Material(
          color: selected ? background : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(expense),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  expense ? '− Dépense' : '+ Revenu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? foreground : palette.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [segment(true), const SizedBox(width: 4), segment(false)]),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? colorName;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.colorName,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = labelTone(colorName, Theme.of(context).brightness);
    final onSolid = tone.solid.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    return Material(
      color: selected ? tone.solid : tone.background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 14, color: onSolid),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? onSolid : tone.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RecurringToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: palette.border),
    );
    return Material(
      color: palette.page,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '↻ Paiement récurrent',
                  style: TextStyle(fontSize: 13.5, color: palette.ink),
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}