import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/icon_picker.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/expense_source.dart';
import '../../../models/merchant.dart';
import '../../../services/providers.dart';

class EntitiesTab extends ConsumerStatefulWidget {
  const EntitiesTab({super.key});

  @override
  ConsumerState<EntitiesTab> createState() => _EntitiesTabState();
}

enum _Segment { purposes, sources, merchants }

class _EntitiesTabState extends ConsumerState<EntitiesTab> {
  _Segment _segment = _Segment.purposes;

  List<ExpensePurpose> _purposes = [];
  List<ExpenseSource> _sources = [];
  List<Merchant> _merchants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();
    final sources = await ref.read(expenseSourceRepositoryProvider).getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    
    setState(() {
      _purposes = purposes;
      _sources = sources;
      _merchants = merchants;
      _loading = false;
    });
  }

  // ─── Dialogs ───────────────────────────────────────────

  Future<void> _showPurposeDialog({ExpensePurpose? purpose}) async {
    final isEdit = purpose != null;
    final nameCtrl = TextEditingController(text: purpose?.expenseFor ?? '');
    final iconCtrl = TextEditingController(text: purpose?.icon ?? 'person');
    final colorCtrl = TextEditingController(text: purpose?.iconColor ?? '#607D8B');

    final result = await _commonDialog(
      title: isEdit ? 'Edit Purpose' : 'Add Purpose',
      nameLabel: 'Expense For',
      nameCtrl: nameCtrl,
      iconCtrl: iconCtrl,
      colorCtrl: colorCtrl,
    );

    if (result == true) {
      final repo = ref.read(expensePurposeRepositoryProvider);
      if (isEdit) {
        await repo.updateExpensePurpose(purpose.copyWith(expenseFor: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      } else {
        await repo.insertExpensePurpose(ExpensePurpose(expenseFor: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      }
      _loadData();
    }
  }

  Future<void> _showSourceDialog({ExpenseSource? source}) async {
    final isEdit = source != null;
    final nameCtrl = TextEditingController(text: source?.expenseSourceName ?? '');
    final iconCtrl = TextEditingController(text: source?.icon ?? 'keyboard');
    final colorCtrl = TextEditingController(text: source?.iconColor ?? '#607D8B');

    final result = await _commonDialog(
      title: isEdit ? 'Edit Source' : 'Add Source',
      nameLabel: 'Source Name',
      nameCtrl: nameCtrl,
      iconCtrl: iconCtrl,
      colorCtrl: colorCtrl,
    );

    if (result == true) {
      final repo = ref.read(expenseSourceRepositoryProvider);
      if (isEdit) {
        await repo.updateExpenseSource(source.copyWith(expenseSourceName: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      } else {
        await repo.insertExpenseSource(ExpenseSource(expenseSourceName: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      }
      _loadData();
    }
  }

  Future<void> _showMerchantDialog({Merchant? merchant}) async {
    final isEdit = merchant != null;
    final nameCtrl = TextEditingController(text: merchant?.merchantName ?? '');
    final iconCtrl = TextEditingController(text: merchant?.icon ?? 'store');
    
    String defaultColor = merchant?.iconColor ?? '#FF9800';
    if (!isEdit) {
      final existingColors = _merchants.map((m) => m.iconColor).whereType<String>().toList();
      defaultColor = ColorHelper.generateUniqueColor(existingColors);
    }
    final colorCtrl = TextEditingController(text: defaultColor);

    final result = await _commonDialog(
      title: isEdit ? 'Edit Merchant' : 'Add Merchant',
      nameLabel: 'Merchant Name',
      nameCtrl: nameCtrl,
      iconCtrl: iconCtrl,
      colorCtrl: colorCtrl,
    );

    if (result == true) {
      final repo = ref.read(merchantRepositoryProvider);
      if (isEdit) {
        await repo.updateMerchant(merchant.copyWith(merchantName: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      } else {
        await repo.insertMerchant(Merchant(merchantName: nameCtrl.text, icon: iconCtrl.text, iconColor: colorCtrl.text));
      }
      _loadData();
    }
  }

  Future<bool?> _commonDialog({
    required String title,
    required String nameLabel,
    required TextEditingController nameCtrl,
    required TextEditingController iconCtrl,
    required TextEditingController colorCtrl,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: nameLabel, border: const OutlineInputBorder()), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextFormField(
                controller: iconCtrl,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Icon', border: const OutlineInputBorder(), suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text))),
                onTap: () async {
                  final selected = await IconPicker.show(context, initialIcon: iconCtrl.text);
                  if (selected != null) {
                    setDialogState(() => iconCtrl.text = selected);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorCtrl,
                decoration: InputDecoration(
                  labelText: 'Icon Color (hex)',
                  border: const OutlineInputBorder(),
                  suffixIcon: CircleAvatar(radius: 12, backgroundColor: ColorHelper.fromHex(colorCtrl.text)),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_Segment>(
              segments: const [
                ButtonSegment(value: _Segment.purposes, label: Text('Purposes'), icon: Icon(Icons.person_rounded, size: 18)),
                ButtonSegment(value: _Segment.sources, label: Text('Sources'), icon: Icon(Icons.keyboard_rounded, size: 18)),
                ButtonSegment(value: _Segment.merchants, label: Text('Merchants'), icon: Icon(Icons.store_rounded, size: 18)),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_segment) {
            case _Segment.purposes: _showPurposeDialog();
            case _Segment.sources: _showSourceDialog();
            case _Segment.merchants: _showMerchantDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    final cs = Theme.of(context).colorScheme;
    switch (_segment) {
      case _Segment.purposes:
        return _buildList(
          items: _purposes.map((p) => (id: p.id, name: p.expenseFor, icon: p.icon ?? 'person', color: p.iconColor)).toList(),
          emptyText: 'No purposes yet.',
          onEdit: (id) => _showPurposeDialog(purpose: _purposes.firstWhere((p) => p.id == id)),
          onDelete: (id) => _confirmDelete('Purpose', _purposes.firstWhere((p) => p.id == id).expenseFor, () => ref.read(expensePurposeRepositoryProvider).deleteExpensePurpose(id!)),
          cs: cs,
        );
      case _Segment.sources:
        return _buildList(
          items: _sources.map((s) => (id: s.id, name: s.expenseSourceName, icon: s.icon ?? 'keyboard', color: s.iconColor)).toList(),
          emptyText: 'No sources yet.',
          onEdit: (id) => _showSourceDialog(source: _sources.firstWhere((s) => s.id == id)),
          onDelete: (id) => _confirmDelete('Source', _sources.firstWhere((s) => s.id == id).expenseSourceName, () => ref.read(expenseSourceRepositoryProvider).deleteExpenseSource(id!)),
          cs: cs,
        );
      case _Segment.merchants:
        return _buildList(
          items: _merchants.map((m) => (id: m.id, name: m.merchantName, icon: m.icon ?? 'store', color: m.iconColor)).toList(),
          emptyText: 'No merchants yet.',
          onEdit: (id) => _showMerchantDialog(merchant: _merchants.firstWhere((m) => m.id == id)),
          onDelete: (id) => _confirmDelete('Merchant', _merchants.firstWhere((m) => m.id == id).merchantName, () => ref.read(merchantRepositoryProvider).deleteMerchant(id!)),
          cs: cs,
        );
    }
  }

  Widget _buildList({
    required List<({int? id, String name, String icon, String? color})> items,
    required String emptyText,
    required Function(int?) onEdit,
    required Function(int?) onDelete,
    required ColorScheme cs,
  }) {
    if (items.isEmpty) return Center(child: Text(emptyText, style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final color = ColorHelper.fromHex(item.color ?? '#607D8B');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(item.icon), color: color),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => onEdit(item.id)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => onDelete(item.id)),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String entityName, String name, Future<void> Function() deleteFn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $entityName'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteFn();
      _loadData();
    }
  }
}
