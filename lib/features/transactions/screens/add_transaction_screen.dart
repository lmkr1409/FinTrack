import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/category.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/expense_source.dart';
import '../../../models/merchant.dart';
import '../../../models/payment_method.dart';
import '../../../models/sub_category.dart';
import '../../../models/transaction.dart';
import '../../../services/providers.dart';

/// Full-page form to add a new transaction.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String _transactionType = 'DEBIT';
  int? _categoryId;
  int? _subcategoryId;
  int? _accountId;
  int? _cardId;
  int? _merchantId;
  int? _paymentMethodId;
  int? _purposeId;
  int? _expenseSourceId;

  // Lookup data
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Account> _accounts = [];
  List<model.Card> _cards = [];
  List<Merchant> _merchants = [];
  List<PaymentMethod> _paymentMethods = [];
  List<ExpensePurpose> _purposes = [];
  List<ExpenseSource> _sources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();
    final sources = await ref.read(expenseSourceRepositoryProvider).getAllSorted();

    setState(() {
      _categories = categories;
      _accounts = accounts;
      _cards = cards;
      _merchants = merchants;
      _paymentMethods = methods;
      _purposes = purposes;
      _sources = sources;
      _loading = false;
    });
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final subs = await ref.read(subCategoryRepositoryProvider).getByCategoryId(categoryId);
    setState(() {
      _subCategories = subs;
      _subcategoryId = null;
    });
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    final txn = Transaction(
      transactionType: _transactionType,
      amount: amount,
      transactionDate: _dateCtrl.text,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      categoryId: _categoryId,
      subcategoryId: _subcategoryId,
      accountId: _accountId,
      cardId: _cardId,
      merchantId: _merchantId,
      paymentMethodId: _paymentMethodId,
      purposeId: _purposeId,
      expenseSourceId: _expenseSourceId,
    );

    await ref.read(transactionRepositoryProvider).insertTransaction(txn);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Save'),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DEBIT', label: Text('Debit'), icon: Icon(Icons.arrow_upward_rounded, size: 18)),
                ButtonSegment(value: 'CREDIT', label: Text('Credit'), icon: Icon(Icons.arrow_downward_rounded, size: 18)),
              ],
              selected: {_transactionType},
              onSelectionChanged: (s) => setState(() => _transactionType = s.first),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder(), prefixText: '₹ '),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 12),

            // Date
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              onTap: _pickDate,
              validator: (v) => (v == null || v.isEmpty) ? 'Pick a date' : null,
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName)))],
              onChanged: (v) {
                setState(() => _categoryId = v);
                if (v != null) _loadSubCategories(v);
              },
            ),
            const SizedBox(height: 12),

            // SubCategory
            if (_subCategories.isNotEmpty)
              DropdownButtonFormField<int?>(
                initialValue: _subcategoryId,
                decoration: const InputDecoration(labelText: 'SubCategory', border: OutlineInputBorder()),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ..._subCategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.subcategoryName)))],
                onChanged: (v) => setState(() => _subcategoryId = v),
              ),
            if (_subCategories.isNotEmpty) const SizedBox(height: 12),

            // Account
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.accountName)))],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),

            // Card
            if (_cards.isNotEmpty)
              DropdownButtonFormField<int?>(
                initialValue: _cardId,
                decoration: const InputDecoration(labelText: 'Card', border: OutlineInputBorder()),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ..._cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.cardName)))],
                onChanged: (v) => setState(() => _cardId = v),
              ),
            if (_cards.isNotEmpty) const SizedBox(height: 12),

            // Merchant
            DropdownButtonFormField<int?>(
              initialValue: _merchantId,
              decoration: const InputDecoration(labelText: 'Merchant', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._merchants.map((m) => DropdownMenuItem(value: m.id, child: Text(m.merchantName)))],
              onChanged: (v) => setState(() => _merchantId = v),
            ),
            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<int?>(
              initialValue: _paymentMethodId,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._paymentMethods.map((p) => DropdownMenuItem(value: p.id, child: Text(p.paymentMethodName)))],
              onChanged: (v) => setState(() => _paymentMethodId = v),
            ),
            const SizedBox(height: 12),

            // Expense Purpose
            DropdownButtonFormField<int?>(
              initialValue: _purposeId,
              decoration: const InputDecoration(labelText: 'Expense Purpose', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._purposes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.expenseFor)))],
              onChanged: (v) => setState(() => _purposeId = v),
            ),
            const SizedBox(height: 12),

            // Expense Source
            DropdownButtonFormField<int?>(
              initialValue: _expenseSourceId,
              decoration: const InputDecoration(labelText: 'Expense Source', border: OutlineInputBorder()),
              items: [const DropdownMenuItem(value: null, child: Text('None')), ..._sources.map((s) => DropdownMenuItem(value: s.id, child: Text(s.expenseSourceName)))],
              onChanged: (v) => setState(() => _expenseSourceId = v),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Transaction'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
