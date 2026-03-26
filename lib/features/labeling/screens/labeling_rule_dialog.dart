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
import '../../../models/labeling_rule.dart';
import '../../../services/providers.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/autocomplete_field.dart';

class LabelingRuleDialog extends ConsumerStatefulWidget {
  final LabelingRule? rule;
  final VoidCallback onSaved;

  const LabelingRuleDialog({super.key, this.rule, required this.onSaved});

  @override
  ConsumerState<LabelingRuleDialog> createState() => _LabelingRuleDialogState();
}

class _LabelingRuleDialogState extends ConsumerState<LabelingRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keywordCtrl = TextEditingController();

  int? _categoryId;
  int? _subcategoryId;
  int? _merchantId;
  int? _paymentMethodId;
  int? _expenseSourceId;
  int? _purposeId;
  int? _accountId;
  int? _cardId;
  String? _transactionType;

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
    if (widget.rule != null) {
      final r = widget.rule!;
      _keywordCtrl.text = r.keyword;
      _categoryId = r.categoryId;
      _subcategoryId = r.subcategoryId;
      _merchantId = r.merchantId;
      _paymentMethodId = r.paymentMethodId;
      _expenseSourceId = r.expenseSourceId;
      _purposeId = r.purposeId;
      _accountId = r.accountId;
      _cardId = r.cardId;
      _transactionType = r.transactionType;
    }
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final ruleMap = <String, dynamic>{
      if (widget.rule != null) 'rule_id': widget.rule!.id,
      'keyword': _keywordCtrl.text.trim(),
      'transaction_type': _transactionType,
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

    final repo = ref.read(labelingRuleRepositoryProvider);
    
    if (widget.rule == null) {
      await repo.insert(ruleMap);
    } else {
      await repo.update(widget.rule!.id!, ruleMap);
    }

    if (mounted) Navigator.pop(context);
    widget.onSaved();
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
      await _loadLookups();
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.rule_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.rule == null ? 'New Labeling Rule' : 'Edit Labeling Rule',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  TextFormField(
                    controller: _keywordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keyword',
                      hintText: 'e.g., KFC, UPI',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a keyword' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Mappings (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String?>(
                    initialValue: _transactionType,
                    decoration: const InputDecoration(labelText: 'Transaction Type', prefixIcon: Icon(Icons.swap_horiz_rounded)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('None / Inherit')),
                      DropdownMenuItem(value: 'DEBIT', child: Text('Debit (Expense)')),
                      DropdownMenuItem(value: 'CREDIT', child: Text('Credit (Income)')),
                      DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer')),
                    ],
                    onChanged: (val) => setState(() => _transactionType = val),
                  ),
                  const SizedBox(height: 12),
                  
                  AutocompleteField<Category>(
                    label: 'Category',
                    initialItem: _categoryId == null ? null : _categories.where((c) => c.id == _categoryId).firstOrNull,
                    items: _categories,
                    displayStringForOption: (c) => c.categoryName,
                    onChanged: (c) {
                      setState(() => _categoryId = c?.id);
                      if (c != null) {
                        _loadSubs(c.id!);
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
                        (s) { setState(() => _subcategoryId = s.id); _loadSubs(_categoryId!); },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
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
                  
                  AutocompleteField<ExpenseSource>(
                    label: 'Expense Source',
                    initialItem: _expenseSourceId == null ? null : _expenseSources.where((s) => s.id == _expenseSourceId).firstOrNull,
                    items: _expenseSources,
                    displayStringForOption: (s) => s.expenseSourceName,
                    onChanged: (s) => setState(() => _expenseSourceId = s?.id),
                    onAddNew: (text) => _addNew<ExpenseSource>(
                      'Expense Source',
                      text,
                      (name) => ref.read(expenseSourceRepositoryProvider).insert(ExpenseSource(expenseSourceName: name, priority: 99).toMap()).then((id) => ExpenseSource(id: id, expenseSourceName: name, priority: 99)),
                      (s) => setState(() => _expenseSourceId = s.id),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
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
                  const SizedBox(height: 24),
                  
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save Rule'),
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
