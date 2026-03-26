import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/account.dart';
import '../../../models/category.dart';
import '../../../models/merchant.dart';

/// Bottom sheet for filtering transactions by date range, type, category, account, merchant.
class TransactionFilterSheet extends StatefulWidget {
  final String? startDate;
  final String? endDate;
  final String? transactionType;
  final int? categoryId;
  final int? accountId;
  final int? merchantId;
  final List<Category> categories;
  final List<Account> accounts;
  final List<Merchant> merchants;

  const TransactionFilterSheet({
    super.key,
    this.startDate,
    this.endDate,
    this.transactionType,
    this.categoryId,
    this.accountId,
    this.merchantId,
    required this.categories,
    required this.accounts,
    required this.merchants,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  String? _type;
  int? _categoryId;
  int? _accountId;
  int? _merchantId;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.startDate ?? '');
    _endCtrl = TextEditingController(text: widget.endDate ?? '');
    _type = widget.transactionType;
    _categoryId = widget.categoryId;
    _accountId = widget.accountId;
    _merchantId = widget.merchantId;
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void _apply() {
    Navigator.pop(context, {
      'startDate': _startCtrl.text.isNotEmpty ? _startCtrl.text : null,
      'endDate': _endCtrl.text.isNotEmpty ? _endCtrl.text : null,
      'transactionType': _type,
      'categoryId': _categoryId,
      'accountId': _accountId,
      'merchantId': _merchantId,
    });
  }

  void _clear() {
    Navigator.pop(context, <String, dynamic>{
      'startDate': null,
      'endDate': null,
      'transactionType': null,
      'categoryId': null,
      'accountId': null,
      'merchantId': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(
              child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            ),
            Text('Filter Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Date range
            Row(children: [
              Expanded(child: TextField(controller: _startCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 18)), onTap: () => _pickDate(_startCtrl))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _endCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 18)), onTap: () => _pickDate(_endCtrl))),
            ]),
            const SizedBox(height: 12),

            // Transaction type
            DropdownButtonFormField<String?>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Transaction Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'DEBIT', child: Text('Debit')),
                DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('All')), ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName)))],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),

            // Account
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('All')), ...widget.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.accountName)))],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),

            // Merchant
            DropdownButtonFormField<int?>(
              initialValue: _merchantId,
              decoration: const InputDecoration(labelText: 'Merchant', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('All')), ...widget.merchants.map((m) => DropdownMenuItem(value: m.id, child: Text(m.merchantName)))],
              onChanged: (v) => setState(() => _merchantId = v),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _clear, child: const Text('Clear Filters'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _apply, child: const Text('Apply'))),
            ]),
          ],
        ),
      ),
    );
  }
}
