import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/expense_source.dart';
import '../../../services/providers.dart';
import '../../../core/widgets/icon_picker.dart';

class PurposeSourceTab extends ConsumerStatefulWidget {
  const PurposeSourceTab({super.key});

  @override
  ConsumerState<PurposeSourceTab> createState() => _PurposeSourceTabState();
}

enum _Segment { purposes, sources }

class _PurposeSourceTabState extends ConsumerState<PurposeSourceTab> {
  _Segment _segment = _Segment.purposes;

  List<ExpensePurpose> _purposes = [];
  List<ExpenseSource> _sources = [];
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
    setState(() {
      _purposes = purposes;
      _sources = sources;
      _loading = false;
    });
  }

  // ─── Expense Purpose Dialogs ────────────────────────────

  Future<void> _showPurposeDialog({ExpensePurpose? purpose}) async {
    final nameCtrl = TextEditingController(text: purpose?.expenseFor ?? '');
    final iconCtrl = TextEditingController(text: purpose?.icon ?? 'person');
    final colorCtrl = TextEditingController(text: purpose?.iconColor ?? '#607D8B');
    final isEdit = purpose != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Purpose' : 'Add Purpose'),
          content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Expense For', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
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
            TextField(controller: colorCtrl, decoration: InputDecoration(labelText: 'Icon Color (hex)', border: const OutlineInputBorder(), suffixIcon: CircleAvatar(radius: 12, backgroundColor: ColorHelper.fromHex(colorCtrl.text)))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(expensePurposeRepositoryProvider);
    if (isEdit) {
      await repo.updateExpensePurpose(purpose.copyWith(expenseFor: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertExpensePurpose(ExpensePurpose(expenseFor: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeletePurpose(ExpensePurpose purpose) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purpose'),
        content: Text('Delete "${purpose.expenseFor}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expensePurposeRepositoryProvider).deleteExpensePurpose(purpose.id!);
      await _loadData();
    }
  }

  // ─── Expense Source Dialogs ─────────────────────────────

  Future<void> _showSourceDialog({ExpenseSource? source}) async {
    final nameCtrl = TextEditingController(text: source?.expenseSourceName ?? '');
    final iconCtrl = TextEditingController(text: source?.icon ?? 'keyboard');
    final colorCtrl = TextEditingController(text: source?.iconColor ?? '#607D8B');
    final isEdit = source != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Source' : 'Add Source'),
          content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Source Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
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
            TextField(controller: colorCtrl, decoration: InputDecoration(labelText: 'Icon Color (hex)', border: const OutlineInputBorder(), suffixIcon: CircleAvatar(radius: 12, backgroundColor: ColorHelper.fromHex(colorCtrl.text)))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(expenseSourceRepositoryProvider);
    if (isEdit) {
      await repo.updateExpenseSource(source.copyWith(expenseSourceName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertExpenseSource(ExpenseSource(expenseSourceName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeleteSource(ExpenseSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Source'),
        content: Text('Delete "${source.expenseSourceName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expenseSourceRepositoryProvider).deleteExpenseSource(source.id!);
      await _loadData();
    }
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
                ButtonSegment(value: _Segment.purposes, label: Text('Purpose'), icon: Icon(Icons.person_rounded, size: 18)),
                ButtonSegment(value: _Segment.sources, label: Text('Source'), icon: Icon(Icons.keyboard_rounded, size: 18)),
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
            case _Segment.purposes:
              _showPurposeDialog();
            case _Segment.sources:
              _showSourceDialog();
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
        return _buildPurposesList(cs);
      case _Segment.sources:
        return _buildSourcesList(cs);
    }
  }

  Widget _buildPurposesList(ColorScheme cs) {
    if (_purposes.isEmpty) return Center(child: Text('No expense purposes yet.', style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _purposes.length,
      itemBuilder: (context, i) {
        final p = _purposes[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromHex(p.iconColor).withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(p.icon), color: ColorHelper.fromHex(p.iconColor)),
            ),
            title: Text(p.expenseFor, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showPurposeDialog(purpose: p)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeletePurpose(p)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildSourcesList(ColorScheme cs) {
    if (_sources.isEmpty) return Center(child: Text('No expense sources yet.', style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _sources.length,
      itemBuilder: (context, i) {
        final s = _sources[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromHex(s.iconColor).withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(s.icon), color: ColorHelper.fromHex(s.iconColor)),
            ),
            title: Text(s.expenseSourceName, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showSourceDialog(source: s)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeleteSource(s)),
            ]),
          ),
        );
      },
    );
  }
}
