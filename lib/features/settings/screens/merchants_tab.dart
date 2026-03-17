import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/merchant.dart';
import '../../../services/providers.dart';
import '../../../core/widgets/icon_picker.dart';

/// Merchants CRUD tab (Tab 4 of Configuration).
class MerchantsTab extends ConsumerStatefulWidget {
  const MerchantsTab({super.key});

  @override
  ConsumerState<MerchantsTab> createState() => _MerchantsTabState();
}

class _MerchantsTabState extends ConsumerState<MerchantsTab> {
  List<Merchant> _merchants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    setState(() {
      _merchants = merchants;
      _loading = false;
    });
  }

  Future<void> _showMerchantDialog({Merchant? merchant}) async {
    final nameCtrl = TextEditingController(text: merchant?.merchantName ?? '');
    final iconCtrl = TextEditingController(text: merchant?.icon ?? 'store');
    final colorCtrl = TextEditingController(text: merchant?.iconColor ?? '#FF9800');
    final isEdit = merchant != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Merchant' : 'Add Merchant'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Merchant Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
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
    final repo = ref.read(merchantRepositoryProvider);
    if (isEdit) {
      await repo.updateMerchant(merchant.copyWith(merchantName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertMerchant(Merchant(merchantName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeleteMerchant(Merchant merchant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Merchant'),
        content: Text('Delete "${merchant.merchantName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(merchantRepositoryProvider).deleteMerchant(merchant.id!);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: _merchants.isEmpty
          ? Center(child: Text('No merchants yet.', style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _merchants.length,
              itemBuilder: (context, i) {
                final m = _merchants[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ColorHelper.fromHex(m.iconColor).withValues(alpha: 0.15),
                      child: Icon(IconHelper.getIcon(m.icon), color: ColorHelper.fromHex(m.iconColor)),
                    ),
                    title: Text(m.merchantName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showMerchantDialog(merchant: m)),
                      IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeleteMerchant(m)),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMerchantDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
