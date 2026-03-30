import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
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
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/autocomplete_field.dart';

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
  String _nature = 'TRANSACTIONS';
  int? _categoryId;
  int? _subcategoryId;
  int? _accountId;
  int? _cardId;
  int? _merchantId;
  int? _paymentMethodId;
  int? _purposeId;
  int? _expenseSourceId;
  int? _toAccountId;
  int? _toCardId;
  String _transferType = 'DEBIT'; // 'DEBIT', 'CREDIT', 'SELF'

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadLookups();
  }

  String get _currentCategoryType {
    return _nature;
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

    final repo = ref.read(transactionRepositoryProvider);

    if (_nature == 'TRANSFERS' && _transferType == 'SELF') {
      if (_toAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination Account')),
        );
        return;
      }

      // 1. Create the "From" side transaction
      final fromAccName = _accounts.where((a) => a.id == _accountId).firstOrNull?.accountName ?? 'Source';
      final toAccName = _accounts.where((a) => a.id == _toAccountId).firstOrNull?.accountName ?? 'Destination';

      final fromTxn = Transaction(
        transactionType: 'DEBIT',
        nature: 'TRANSFERS',
        amount: amount,
        transactionDate: _dateCtrl.text,
        description: 'Self Transfer from $fromAccName to $toAccName',
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        accountId: _accountId,
        cardId: _cardId,
        labeled: true,
        isAutoLabeled: false,
      );

      final fromId = await repo.insertTransaction(fromTxn);

      // 2. Create the "To" side transaction (Linked)
      final toTxn = Transaction(
        transactionType: 'CREDIT',
        nature: 'TRANSFERS',
        amount: amount,
        transactionDate: _dateCtrl.text,
        description: 'Self Transfer from $fromAccName to $toAccName',
        accountId: _toAccountId,
        cardId: _toCardId,
        labeled: true,
        isAutoLabeled: false,
        relatedTransactionId: fromId,
      );

      final toId = await repo.insertTransaction(toTxn);

      // 3. Update the "From" side with the relation
      await repo.updateTransaction(fromTxn.copyWith(id: fromId, relatedTransactionId: toId));
    } else {
      // Standard transaction
      final txn = Transaction(
        transactionType: _transactionType,
        nature: _nature,
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
        labeled: _categoryId != null, // Mark as labeled if category is selected
      );

      await repo.insertTransaction(txn);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addNew<T>(
    String title,
    String initialText,
    Future<T> Function(String name) onCreate,
    void Function(T newItem) onCreated,
  ) async {
    final nameCtrl = TextEditingController(text: initialText);
    final nameStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New $title'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Name', hintText: 'Enter $title name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (nameStr == null || nameStr.isEmpty || !mounted) return;

    try {
      setState(() => _saving = true);
      final newItem = await onCreate(nameStr);
      onCreated(newItem);
      await _loadLookups(); // Refresh lists
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                ButtonSegment(value: 'TRANSACTIONS', label: Text('Transaction'), icon: Icon(Icons.sync_alt_rounded, size: 18)),
                ButtonSegment(value: 'TRANSFERS', label: Text('Transfer'), icon: Icon(Icons.swap_horiz_rounded, size: 18)),
                ButtonSegment(value: 'INVESTMENTS', label: Text('Invest'), icon: Icon(Icons.pie_chart_outline, size: 18)),
              ],
              selected: {_nature},
              onSelectionChanged: (s) {
                final newNature = s.first;
                if (newNature != _nature) {
                  setState(() {
                    _nature = newNature;
                    if (_nature == 'TRANSFERS') {
                      _transactionType = 'DEBIT';
                    }
                    _categoryId = null;
                    _subcategoryId = null;
                    _subCategories = [];
                  });
                }
              },
            ),
            if (_nature == 'TRANSFERS') ...[
              const SizedBox(height: 16),
              const Text('Transfer Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'DEBIT', label: Text('Outgoing'), icon: Icon(Icons.outbound_rounded, size: 16)),
                  ButtonSegment(value: 'CREDIT', label: Text('Incoming'), icon: Icon(Icons.login_rounded, size: 16)),
                  ButtonSegment(value: 'SELF', label: Text('Self'), icon: Icon(Icons.swap_horiz_rounded, size: 16)),
                ],
                selected: {_transferType},
                onSelectionChanged: (s) => setState(() {
                  _transferType = s.first;
                  if (_transferType == 'SELF') {
                    _categoryId = _categories.where((c) => c.categoryName == 'Self Transfer').firstOrNull?.id;
                  } else if (_transferType == 'DEBIT') {
                    _categoryId = _categories.where((c) => c.categoryName == 'Investments').firstOrNull?.id;
                  }
                }),
              ),
              if (_transferType == 'SELF') ...[
                const SizedBox(height: 16),
                const Text('To Account / Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 8),
                AutocompleteField<Account>(
                  label: 'Destination Account',
                  initialItem: _toAccountId == null ? null : _accounts.where((a) => a.id == _toAccountId).firstOrNull,
                  items: _accounts.where((a) => a.id != _accountId).toList(),
                  displayStringForOption: (a) => a.accountName,
                  onChanged: (a) => setState(() => _toAccountId = a?.id),
                  onAddNew: (text) => _addNew<Account>(
                    'Account',
                    text,
                    (name) => ref.read(accountRepositoryProvider).insert(Account(accountName: name, balance: 0, icon: 'buildingColumns', iconColor: ColorHelper.toHex(Colors.blue), priority: 99).toMap()).then((id) => Account(id: id, accountName: name, balance: 0, icon: 'buildingColumns', iconColor: ColorHelper.toHex(Colors.blue), priority: 99)),
                    (a) => setState(() => _toAccountId = a.id),
                  ),
                ),
                const SizedBox(height: 12),
                AutocompleteField<model.Card>(
                  label: 'Destination Card',
                  initialItem: _toCardId == null ? null : _cards.where((c) => c.id == _toCardId).firstOrNull,
                  items: _cards.where((c) => c.accountId == _toAccountId).toList(),
                  displayStringForOption: (c) => c.cardName,
                  onChanged: (c) => setState(() => _toCardId = c?.id),
                  onAddNew: (text) => _addNew<model.Card>(
                    'Card',
                    text,
                    (name) => ref.read(cardRepositoryProvider).insert(model.Card(accountId: _toAccountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0, priority: 99).toMap()).then((id) => model.Card(id: id, accountId: _toAccountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0, priority: 99)),
                    (c) => setState(() => _toCardId = c.id),
                  ),
                ),
              ],
            ],
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
            AutocompleteField<Category>(
              label: 'Category',
              initialItem: _categoryId == null ? null : _categories.where((c) => c.id == _categoryId).firstOrNull,
              items: _categories.where((c) => c.categoryType == _currentCategoryType).toList(),
              displayStringForOption: (c) => c.categoryName,
              onChanged: (c) {
                setState(() => _categoryId = c?.id);
                if (c != null) {
                  _loadSubCategories(c.id!);
                } else {
                  setState(() { _subCategories = []; _subcategoryId = null; });
                }
              },
              onAddNew: (text) => _addNew<Category>(
                'Category',
                text,
                (name) => ref.read(categoryRepositoryProvider).insert(Category(categoryName: name, icon: 'circleQuestion', iconColor: ColorHelper.toHex(Colors.grey), priority: 99).toMap()).then((id) => Category(id: id, categoryName: name, icon: 'circleQuestion', iconColor: ColorHelper.toHex(Colors.grey), priority: 99)),
                (c) => setState(() => _categoryId = c.id),
              ),
            ),
            const SizedBox(height: 12),

            // SubCategory
            if (_subCategories.isNotEmpty || _categoryId != null)
              AutocompleteField<SubCategory>(
                label: 'Sub-Category',
                initialItem: _subcategoryId == null ? null : _subCategories.where((s) => s.id == _subcategoryId).firstOrNull,
                items: _subCategories,
                displayStringForOption: (s) => s.subcategoryName,
                onChanged: (s) => setState(() => _subcategoryId = s?.id),
                onAddNew: (text) {
                  if (_categoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Category first'), backgroundColor: Colors.orange));
                    return;
                  }
                  _addNew<SubCategory>(
                    'Sub-Category',
                    text,
                    (name) => ref.read(subCategoryRepositoryProvider).insert(SubCategory(categoryId: _categoryId!, subcategoryName: name, priority: 99).toMap()).then((id) => SubCategory(id: id, categoryId: _categoryId!, subcategoryName: name, priority: 99)),
                    (s) { setState(() => _subcategoryId = s.id); _loadSubCategories(_categoryId!); },
                  );
                },
              ),
            if (_subCategories.isNotEmpty || _categoryId != null) const SizedBox(height: 12),

            // Account
            AutocompleteField<Account>(
              label: 'Account',
              initialItem: _accountId == null ? null : _accounts.where((a) => a.id == _accountId).firstOrNull,
              items: _accounts,
              displayStringForOption: (a) => a.accountName,
              onChanged: (a) => setState(() => _accountId = a?.id),
              onAddNew: (text) => _addNew<Account>(
                'Account',
                text,
                (name) => ref.read(accountRepositoryProvider).insert(Account(accountName: name, balance: 0, icon: 'buildingColumns', iconColor: ColorHelper.toHex(Colors.blue), priority: 99).toMap()).then((id) => Account(id: id, accountName: name, balance: 0, icon: 'buildingColumns', iconColor: ColorHelper.toHex(Colors.blue), priority: 99)),
                (a) => setState(() => _accountId = a.id),
              ),
            ),
            const SizedBox(height: 12),

            // Card
            if (_cards.isNotEmpty || _accountId != null)
              AutocompleteField<model.Card>(
                label: 'Card',
                initialItem: _cardId == null ? null : _cards.where((c) => c.id == _cardId).firstOrNull,
                items: _cards,
                displayStringForOption: (c) => c.cardName,
                onChanged: (c) => setState(() => _cardId = c?.id),
                onAddNew: (text) => _addNew<model.Card>(
                  'Card',
                  text,
                  (name) => ref.read(cardRepositoryProvider).insert(model.Card(accountId: _accountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0, priority: 99).toMap()).then((id) => model.Card(id: id, accountId: _accountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0, priority: 99)),
                  (c) => setState(() => _cardId = c.id),
                ),
              ),
            if (_cards.isNotEmpty || _accountId != null) const SizedBox(height: 12),

            // Merchant
            AutocompleteField<Merchant>(
              label: 'Merchant',
              initialItem: _merchantId == null ? null : _merchants.where((m) => m.id == _merchantId).firstOrNull,
              items: _merchants,
              displayStringForOption: (m) => m.merchantName,
              onChanged: (m) => setState(() => _merchantId = m?.id),
              onAddNew: (text) => _addNew<Merchant>(
                'Merchant',
                text,
                (name) => ref.read(merchantRepositoryProvider).insert(Merchant(merchantName: name, priority: 99, iconColor: '#9E9E9E', icon: 'store').toMap()).then((id) => Merchant(id: id, merchantName: name, priority: 99, iconColor: '#9E9E9E', icon: 'store')),
                (m) => setState(() => _merchantId = m.id),
              ),
            ),
            const SizedBox(height: 12),

            // Payment Method
            AutocompleteField<PaymentMethod>(
              label: 'Payment Method',
              initialItem: _paymentMethodId == null ? null : _paymentMethods.where((p) => p.id == _paymentMethodId).firstOrNull,
              items: _paymentMethods,
              displayStringForOption: (p) => p.paymentMethodName,
              onChanged: (p) => setState(() => _paymentMethodId = p?.id),
              onAddNew: (text) => _addNew<PaymentMethod>(
                'Payment Method',
                text,
                (name) => ref.read(paymentMethodRepositoryProvider).insert(PaymentMethod(paymentMethodName: name, priority: 99).toMap()).then((id) => PaymentMethod(id: id, paymentMethodName: name, priority: 99)),
                (p) => setState(() => _paymentMethodId = p.id),
              ),
            ),
            const SizedBox(height: 12),

            // Expense Purpose
            AutocompleteField<ExpensePurpose>(
              label: 'Expense Purpose',
              initialItem: _purposeId == null ? null : _purposes.where((p) => p.id == _purposeId).firstOrNull,
              items: _purposes,
              displayStringForOption: (p) => p.expenseFor,
              onChanged: (p) => setState(() => _purposeId = p?.id),
              onAddNew: (text) => _addNew<ExpensePurpose>(
                'Expense Purpose',
                text,
                (name) => ref.read(expensePurposeRepositoryProvider).insert(ExpensePurpose(expenseFor: name, priority: 99).toMap()).then((id) => ExpensePurpose(id: id, expenseFor: name, priority: 99)),
                (p) => setState(() => _purposeId = p.id),
              ),
            ),
            const SizedBox(height: 12),

            // Expense Source
            AutocompleteField<ExpenseSource>(
              label: 'Expense Source',
              initialItem: _expenseSourceId == null ? null : _sources.where((s) => s.id == _expenseSourceId).firstOrNull,
              items: _sources,
              displayStringForOption: (s) => s.expenseSourceName,
              onChanged: (s) => setState(() => _expenseSourceId = s?.id),
              onAddNew: (text) => _addNew<ExpenseSource>(
                'Expense Source',
                text,
                (name) => ref.read(expenseSourceRepositoryProvider).insert(ExpenseSource(expenseSourceName: name, priority: 99).toMap()).then((id) => ExpenseSource(id: id, expenseSourceName: name, priority: 99)),
                (s) => setState(() => _expenseSourceId = s.id),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Transaction'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
