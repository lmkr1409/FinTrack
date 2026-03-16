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

/// Bottom sheet dialog for labeling a transaction.
/// If [applyToAll] is ON (default), also labels all unlabeled transactions
/// with the same description.
class LabelDialog extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback onSaved;

  const LabelDialog({super.key, required this.transaction, required this.onSaved});

  @override
  ConsumerState<LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends ConsumerState<LabelDialog> {
  // Current selections
  int? _categoryId;
  int? _subcategoryId;
  int? _merchantId;
  int? _paymentMethodId;
  int? _expenseSourceId;
  int? _purposeId;
  int? _accountId;
  int? _cardId;
  bool _applyToAll = true;

  // Lookup lists
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Merchant> _merchants = [];
  List<PaymentMethod> _paymentMethods = [];
  List<ExpenseSource> _expenseSources = [];
  List<ExpensePurpose> _purposes = [];
  List<Account> _accounts = [];
  List<model.Card> _cards = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing transaction values
    final t = widget.transaction;
    _categoryId = t.categoryId;
    _subcategoryId = t.subcategoryId;
    _merchantId = t.merchantId;
    _paymentMethodId = t.paymentMethodId;
    _expenseSourceId = t.expenseSourceId;
    _purposeId = t.purposeId;
    _accountId = t.accountId;
    _cardId = t.cardId;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final sources = await ref.read(expenseSourceRepositoryProvider).getAllSorted();
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();

    List<SubCategory> subs = [];
    if (_categoryId != null) {
      subs = await ref.read(subCategoryRepositoryProvider).getByCategoryId(_categoryId!);
    }

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _subCategories = subs;
      _merchants = merchants;
      _paymentMethods = methods;
      _expenseSources = sources;
      _purposes = purposes;
      _accounts = accounts;
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _loadSubs(int categoryId) async {
    final subs = await ref.read(subCategoryRepositoryProvider).getByCategoryId(categoryId);
    if (!mounted) return;
    setState(() {
      _subCategories = subs;
      _subcategoryId = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'category_id': _categoryId,
      'subcategory_id': _subcategoryId,
      'merchant_id': _merchantId,
      'payment_method_id': _paymentMethodId,
      'expense_source_id': _expenseSourceId,
      'purpose_id': _purposeId,
      'account_id': _accountId,
      'card_id': _cardId,
      'updated_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };
    // Remove null values so existing DB values are cleared only when explicitly set
    fields.removeWhere((_, v) => v == null);

    final repo = ref.read(transactionRepositoryProvider);
    // Always label current transaction
    await repo.labelTransaction(widget.transaction.id!, fields);

    // Auto-apply to other unlabeled transactions with the exact same description
    if (_applyToAll && widget.transaction.description != null && widget.transaction.description!.isNotEmpty) {
      await repo.labelByDescription(widget.transaction.description!, fields);
    }

    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }

  Future<void> _addNew<T>(
    String title,
    Future<T> Function(String name) onCreate,
    void Function(T newItem) onCreated,
  ) async {
    final nameCtrl = TextEditingController();
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
    final colorScheme = Theme.of(context).colorScheme;
    final txn = widget.transaction;
    final isDebit = txn.transactionType == 'DEBIT';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isDebit ? AppColors.expense : AppColors.income).withValues(alpha: 0.15),
                  child: Icon(isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isDebit ? AppColors.expense : AppColors.income),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.description ?? txn.transactionType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${isDebit ? '-' : '+'}₹${txn.amount.toStringAsFixed(2)}  •  ${txn.transactionDate}',
                        style: TextStyle(color: isDebit ? AppColors.expense : AppColors.income, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      // Category
                      _buildDropdown<int?>(
                        label: 'Category',
                        value: _categoryId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))),
                        ],
                        onChanged: (v) {
                          setState(() => _categoryId = v);
                          if (v != null) {
                            _loadSubs(v);
                          } else {
                            setState(() { _subCategories = []; _subcategoryId = null; });
                          }
                        },
                        onAddNew: () => _addNew<Category>(
                          'Category',
                          (name) => ref.read(categoryRepositoryProvider).insert(Category(categoryName: name, icon: 'category', iconColor: ColorHelper.toHex(Colors.grey)).toMap()).then((id) => Category(id: id, categoryName: name, icon: 'category', iconColor: ColorHelper.toHex(Colors.grey))),
                          (c) => setState(() => _categoryId = c.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sub-category
                      _buildDropdown<int?>(
                        label: 'Sub-Category',
                        value: _subcategoryId,
                        items: [
                          DropdownMenuItem(value: null, child: Text(_categoryId == null ? 'Select category first' : 'None')),
                          ..._subCategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.subcategoryName))),
                        ],
                        onChanged: _categoryId == null ? null : (v) => setState(() => _subcategoryId = v),
                        onAddNew: () {
                          if (_categoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Category first'), backgroundColor: Colors.orange));
                            return;
                          }
                          _addNew<SubCategory>(
                            'Sub-Category',
                            (name) => ref.read(subCategoryRepositoryProvider).insert(SubCategory(categoryId: _categoryId!, subcategoryName: name).toMap()).then((id) => SubCategory(id: id, categoryId: _categoryId!, subcategoryName: name)),
                            (s) { setState(() => _subcategoryId = s.id); _loadSubs(_categoryId!); },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // Merchant
                      _buildDropdown<int?>(
                        label: 'Merchant',
                        value: _merchantId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._merchants.map((m) => DropdownMenuItem(value: m.id, child: Text(m.merchantName))),
                        ],
                        onChanged: (v) => setState(() => _merchantId = v),
                        onAddNew: () => _addNew<Merchant>(
                          'Merchant',
                          (name) => ref.read(merchantRepositoryProvider).insert(Merchant(merchantName: name).toMap()).then((id) => Merchant(id: id, merchantName: name)),
                          (m) => setState(() => _merchantId = m.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Payment Method
                      _buildDropdown<int?>(
                        label: 'Payment Method',
                        value: _paymentMethodId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._paymentMethods.map((p) => DropdownMenuItem(value: p.id, child: Text(p.paymentMethodName))),
                        ],
                        onChanged: (v) => setState(() => _paymentMethodId = v),
                        onAddNew: () => _addNew<PaymentMethod>(
                          'Payment Method',
                          (name) => ref.read(paymentMethodRepositoryProvider).insert(PaymentMethod(paymentMethodName: name).toMap()).then((id) => PaymentMethod(id: id, paymentMethodName: name)),
                          (p) => setState(() => _paymentMethodId = p.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Expense Source
                      _buildDropdown<int?>(
                        label: 'Expense Source',
                        value: _expenseSourceId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._expenseSources.map((s) => DropdownMenuItem(value: s.id, child: Text(s.expenseSourceName))),
                        ],
                        onChanged: (v) => setState(() => _expenseSourceId = v),
                        onAddNew: () => _addNew<ExpenseSource>(
                          'Expense Source',
                          (name) => ref.read(expenseSourceRepositoryProvider).insert(ExpenseSource(expenseSourceName: name).toMap()).then((id) => ExpenseSource(id: id, expenseSourceName: name)),
                          (s) => setState(() => _expenseSourceId = s.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Expense Purpose
                      _buildDropdown<int?>(
                        label: 'Expense Purpose',
                        value: _purposeId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._purposes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.expenseFor))),
                        ],
                        onChanged: (v) => setState(() => _purposeId = v),
                        onAddNew: () => _addNew<ExpensePurpose>(
                          'Expense Purpose',
                          (name) => ref.read(expensePurposeRepositoryProvider).insert(ExpensePurpose(expenseFor: name).toMap()).then((id) => ExpensePurpose(id: id, expenseFor: name)),
                          (p) => setState(() => _purposeId = p.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Account
                      _buildDropdown<int?>(
                        label: 'Account',
                        value: _accountId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.accountName))),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                        onAddNew: () => _addNew<Account>(
                          'Account',
                          (name) => ref.read(accountRepositoryProvider).insert(Account(accountName: name, balance: 0, icon: 'account_balance', iconColor: ColorHelper.toHex(Colors.blue)).toMap()).then((id) => Account(id: id, accountName: name, balance: 0, icon: 'account_balance', iconColor: ColorHelper.toHex(Colors.blue))),
                          (a) => setState(() => _accountId = a.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Card
                      _buildDropdown<int?>(
                        label: 'Card',
                        value: _cardId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.cardName))),
                        ],
                        onChanged: (v) => setState(() => _cardId = v),
                        onAddNew: () => _addNew<model.Card>(
                          'Card',
                          (name) => ref.read(cardRepositoryProvider).insert(model.Card(accountId: _accountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0).toMap()).then((id) => model.Card(id: id, accountId: _accountId, cardName: name, cardType: 'Credit', cardNumber: '0000', cardExpiryDate: '12/99', cardNetwork: 'Visa', balance: 0)),
                          (c) => setState(() => _cardId = c.id),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Apply to all checkbox
                      if (txn.description != null && txn.description!.isNotEmpty)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _applyToAll,
                          onChanged: (v) => setState(() => _applyToAll = v ?? true),
                          title: const Text('Apply to all matching descriptions', style: TextStyle(fontSize: 13)),
                          subtitle: Text('"${txn.description}"', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.label_rounded, size: 18),
                        label: Text(_saving ? 'Saving…' : 'Save Label'),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required VoidCallback onAddNew,
  }) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
            items: items,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          tooltip: 'Add new $label',
          onPressed: onAddNew,
        ),
      ],
    );
  }
}
