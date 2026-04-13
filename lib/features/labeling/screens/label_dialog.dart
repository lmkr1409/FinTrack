import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/category.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/expense_source.dart';
import '../../../models/investment_goal.dart';
import '../../../models/merchant.dart';
import '../../../models/payment_method.dart';
import '../../../models/sub_category.dart';
import '../../../models/transaction.dart';
import '../../../services/providers.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/autocomplete_field.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'transaction_split_dialog.dart';

/// Bottom sheet dialog for labeling a transaction and creating rules.
class LabelDialog extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback onSaved;
  final bool showSaveRule;

  const LabelDialog({
    super.key,
    required this.transaction,
    required this.onSaved,
    this.showSaveRule = true,
  });

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
  String _transactionType = 'DEBIT';
  String _nature = 'TRANSACTIONS';
  int? _goalId;

  // Rule generation toggles and strings
  bool _saveAsRule = true;
  String _amountStr = '';
  String _transactionTypeKeyword = '';
  String _paymentMethodKeyword = '';
  String _accountKeyword = '';
  String _cardKeyword = '';

  final _merchantKeywordCtrl = TextEditingController();
  final _merchantKeywordFocus = FocusNode();
  String? _merchantKeywordLastSelectedText;

  // Lookup lists
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Merchant> _merchants = [];
  List<PaymentMethod> _paymentMethods = [];
  List<ExpenseSource> _expenseSources = [];
  List<ExpensePurpose> _purposes = [];
  List<Account> _accounts = [];
  List<model.Card> _cards = [];
  List<InvestmentGoal> _goals = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing transaction values
    final t = widget.transaction;
    _amountStr = t.amount > 0 ? t.amount.toStringAsFixed(2) : '';
    _categoryId = t.categoryId;
    _subcategoryId = t.subcategoryId;
    _merchantId = t.merchantId;
    _paymentMethodId = t.paymentMethodId;
    _expenseSourceId = t.expenseSourceId;
    _purposeId = t.purposeId;
    _accountId = t.accountId;
    _cardId = t.cardId;
    _transactionType = t.transactionType;
    _nature = t.nature;

    _loadLookups();
  }

  @override
  void dispose() {
    _merchantKeywordCtrl.dispose();
    _merchantKeywordFocus.dispose();
    super.dispose();
  }

  String get _currentCategoryType {
    return _nature;
  }

  Future<void> _loadLookups() async {
    final categories = await ref
        .read(categoryRepositoryProvider)
        .getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final methods = await ref
        .read(paymentMethodRepositoryProvider)
        .getAllSorted();
    final sources = await ref
        .read(expenseSourceRepositoryProvider)
        .getAllSorted();
    final purposes = await ref
        .read(expensePurposeRepositoryProvider)
        .getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final goals = await ref.read(investmentGoalRepositoryProvider).getAll();


    List<SubCategory> subs = [];
    if (_categoryId != null) {
      subs = await ref
          .read(subCategoryRepositoryProvider)
          .getByCategoryId(_categoryId!);
    }

    // Default to 'MANUAL_ENTRY' if there's no description (manual entry) and no source previously selected
    if (_expenseSourceId == null &&
        (widget.transaction.description == null ||
            widget.transaction.description!.trim().isEmpty)) {
      final manual = sources
          .where((s) => s.expenseSourceName == 'MANUAL_ENTRY')
          .firstOrNull;
      if (manual != null) {
        _expenseSourceId = manual.id;
      }
    }

    // Pre-load existing rule keywords from the database
    final tRuleRepo = ref.read(transactionRuleRepositoryProvider);
    if (_paymentMethodId != null && _paymentMethodKeyword.trim().isEmpty) {
      final kw = await tRuleRepo.getPatternByTypeAndId(
        'PAYMENT_METHOD',
        'payment_method_id',
        _paymentMethodId!,
      );
      if (kw != null) _paymentMethodKeyword = kw;
    }
    if (_accountId != null && _accountKeyword.trim().isEmpty) {
      final kw = await tRuleRepo.getPatternByTypeAndId(
        'ACCOUNT',
        'account_id',
        _accountId!,
      );
      if (kw != null) _accountKeyword = kw;
    }
    if (_cardId != null && _cardKeyword.trim().isEmpty) {
      final kw = await tRuleRepo.getPatternByTypeAndId(
        'CARD',
        'card_id',
        _cardId!,
      );
      if (kw != null) _cardKeyword = kw;
    }
    if (_transactionTypeKeyword.trim().isEmpty) {
      final kw = await tRuleRepo.getTransactionTypePattern(_transactionType);
      if (kw != null) _transactionTypeKeyword = kw;
    }

    // If it's a self transfer, try to find a card/account for the "To" side if possible
    // (For now, let the user select it)

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
      _goals = goals;
      _loading = false;
    });

  }

  Future<void> _loadSubs(int categoryId, [int? subId]) async {
    final subs = await ref
        .read(subCategoryRepositoryProvider)
        .getByCategoryId(categoryId);
    if (!mounted) return;
    setState(() {
      _subCategories = subs;
      _subcategoryId = subId;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Explicitly include all fields to ensure NULLs are saved to the DB
    final fields = <String, dynamic>{
      'category_id': _categoryId,
      'subcategory_id': _subcategoryId,
      'merchant_id': _merchantId,
      'payment_method_id': _paymentMethodId,
      'expense_source_id': _expenseSourceId,
      'purpose_id': _purposeId,
      'account_id': _accountId,
      'card_id': _cardId,
      'transaction_type': _transactionType,
      'nature': _nature,
      'goal_id': _goalId,
      'updated_time': nowStr,
    };

    // Add amount if it's a valid number
    final amount = double.tryParse(_amountStr);
    if (amount != null) {
      fields['amount'] = amount;
    }

    final repo = ref.read(transactionRepositoryProvider);

    // Standard labeling
    await repo.labelTransaction(widget.transaction.id!, fields);

    // Create rules if checked
    if (_saveAsRule) {
      final tRuleRepo = ref.read(transactionRuleRepositoryProvider);
      final mRuleRepo = ref.read(merchantRuleRepositoryProvider);

      // Transaction Type Rule
      if (_transactionTypeKeyword.trim().isNotEmpty) {
        await tRuleRepo.insert({
          'rule_type': 'TRANSACTION_TYPE',
          'pattern': _transactionTypeKeyword.trim(),
          'mapped_type': _transactionType,
          'updated_time': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Payment Method Rule
      if (_paymentMethodKeyword.trim().isNotEmpty && _paymentMethodId != null) {
        await tRuleRepo.insert({
          'rule_type': 'PAYMENT_METHOD',
          'pattern': _paymentMethodKeyword.trim(),
          'payment_method_id': _paymentMethodId,
          'updated_time': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Account Rule
      if (_accountKeyword.trim().isNotEmpty && _accountId != null) {
        await tRuleRepo.insert({
          'rule_type': 'ACCOUNT',
          'pattern': _accountKeyword.trim(),
          'account_id': _accountId,
          'updated_time': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Card Rule
      if (_cardKeyword.trim().isNotEmpty && _cardId != null) {
        await tRuleRepo.insert({
          'rule_type': 'CARD',
          'pattern': _cardKeyword.trim(),
          'card_id': _cardId,
          'updated_time': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Merchant Rule
      if (_merchantKeywordCtrl.text.trim().isNotEmpty) {
        await mRuleRepo.insert({
          'keyword': _merchantKeywordCtrl.text.trim(),
          'merchant_id': _merchantId,
          'category_id': _categoryId,
          'subcategory_id': _subcategoryId,
          'purpose_id': _purposeId,
          'goal_id': _goalId,
          'updated_time': nowStr,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter $title name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openSplitDialog(BuildContext context) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: TransactionSplitDialog(
          transaction: widget.transaction,
          onSplitComplete: () {
            // Success! The dialog itself will pop with 'true' result
          },
        ),
      ),
    );

    if (success == true && mounted) {
      Navigator.pop(context); // Close the LabelDialog itself
      widget.onSaved(); // Refresh the list
    }
  }

  List<String> _tokenizeMessage(String msg) {
    if (msg.trim().isEmpty) return [];
    // Split on spaces only to preserve characters like . or - in UIDs
    return msg
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().length > 2)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final txn = widget.transaction;
    final isDebit = txn.transactionType == 'DEBIT';

    final textTokens = _tokenizeMessage(txn.description ?? '');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        (isDebit ? AppColors.expense : AppColors.income)
                            .withValues(alpha: 0.15),
                    child: Icon(
                      isDebit
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isDebit ? AppColors.expense : AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Label Transaction & Create Rules',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${isDebit ? '-' : '+'}₹${txn.amount.toStringAsFixed(2)}  •  ${txn.transactionDate}',
                          style: TextStyle(
                            color: isDebit
                                ? AppColors.expense
                                : AppColors.income,
                            fontSize: 13,
                          ),
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
                        // 1. Message Section
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Original Message',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  txn.description ?? 'No description',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openSplitDialog(context),
                                    icon: const Icon(Icons.call_split_rounded, size: 18),
                                    label: const Text('Split Transaction'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      side: const BorderSide(color: AppColors.primary),
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: Column(
                            children: [
                              // 2. Nature Section
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.label_important_outline,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Type & Keyword Rule',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 4,
                                ),
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'TRANSACTIONS',
                                      label: Text('Transaction'),
                                      icon: Icon(Icons.sync_alt_rounded),
                                    ),
                                    ButtonSegment(
                                      value: 'TRANSFERS',
                                      label: Text('Transfer'),
                                      icon: Icon(Icons.swap_horiz_rounded),
                                    ),
                                    ButtonSegment(
                                      value: 'INVESTMENTS',
                                      label: Text('Invest'),
                                      icon: Icon(Icons.pie_chart_outline),
                                    ),
                                  ],
                                  selected: {_nature},
                                  onSelectionChanged: (s) {
                                    setState(() {
                                      _nature = s.first;
                                      if (_nature == 'TRANSFERS') {
                                        // Clear all expense-related fields for transfers
                                        _categoryId = null;
                                        _subcategoryId = null;
                                        _subCategories = [];
                                        _merchantId = null;
                                        _merchantKeywordCtrl.clear();
                                        _purposeId = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 3. Amount Section
                              ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: const Icon(
                                  Icons.numbers_rounded,
                                  color: AppColors.primary,
                                ),
                                title: const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  4,
                                  8,
                                  4,
                                  16,
                                ),
                                children: [
                                  TextFormField(
                                    initialValue: _amountStr,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      hintText: 'e.g., 500.00',
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _amountStr = v),
                                  ),
                                ],
                              ),

                              // 3. Transaction Type Section
                              ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: const Icon(
                                  Icons.swap_horiz,
                                  color: AppColors.primary,
                                ),
                                title: const Text(
                                  'Transaction Type Rule',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  4,
                                  8,
                                  4,
                                  16,
                                ),
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _transactionType,
                                    decoration: const InputDecoration(
                                      labelText: 'Transaction Type',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    selectedItemBuilder: (context) => [
                                      'DEBIT',
                                      'CREDIT',
                                    ].map((e) {
                                      final label = e == 'DEBIT' ? 'Debit (Out)' : 'Credit (In)';
                                      return FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(label),
                                      );
                                    }).toList(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'DEBIT',
                                        child: Text('Debit (Out)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CREDIT',
                                        child: Text('Credit (In)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null &&
                                          val != _transactionType) {
                                        setState(() {
                                          _transactionType = val;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    initialValue: _transactionTypeKeyword,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Keyword used to identify type',
                                      hintText: 'e.g., debited',
                                    ),
                                    onChanged: (v) => setState(
                                      () => _transactionTypeKeyword = v,
                                    ),
                                  ),
                                ],
                              ),

                              if (_nature != 'TRANSFERS') ...[
                                // 4. Payment Method Section
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  leading: const Icon(
                                    Icons.payment,
                                    color: AppColors.primary,
                                  ),
                                  title: const Text(
                                    'Payment Method Rule',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    16,
                                  ),
                                  children: [
                                    AutocompleteField<PaymentMethod>(
                                      label: 'Payment Method',
                                      initialItem: _paymentMethodId == null
                                          ? null
                                          : _paymentMethods
                                                .where(
                                                  (p) => p.id == _paymentMethodId,
                                                )
                                                .firstOrNull,
                                      items: _paymentMethods,
                                      displayStringForOption: (p) =>
                                          p.paymentMethodName,
                                      onChanged: (p) => setState(
                                        () => _paymentMethodId = p?.id,
                                      ),
                                      onAddNew: (text) => _addNew<PaymentMethod>(
                                        'Payment Method',
                                        text,
                                        (name) => ref
                                            .read(paymentMethodRepositoryProvider)
                                            .insert(
                                              PaymentMethod(
                                                paymentMethodName: name,
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => PaymentMethod(
                                                id: id,
                                                paymentMethodName: name,
                                                priority: 99,
                                              ),
                                            ),
                                        (p) => setState(
                                          () => _paymentMethodId = p.id,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: _paymentMethodKeyword,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Keyword used to identify method',
                                        hintText: 'e.g., UPI',
                                      ),
                                      onChanged: (v) => setState(
                                        () => _paymentMethodKeyword = v,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (_nature != 'TRANSFERS') ...[
                                // 5. Account Section
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  leading: const Icon(
                                    Icons.account_balance,
                                    color: AppColors.primary,
                                  ),
                                  title: const Text(
                                    'Account Rule',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    16,
                                  ),
                                  children: [
                                    AutocompleteField<Account>(
                                      label: 'Account',
                                      initialItem: _accountId == null
                                          ? null
                                          : _accounts
                                                .where((a) => a.id == _accountId)
                                                .firstOrNull,
                                      items: _accounts,
                                      displayStringForOption: (a) =>
                                          a.accountName,
                                      onChanged: (a) =>
                                          setState(() => _accountId = a?.id),
                                      onAddNew: (text) => _addNew<Account>(
                                        'Account',
                                        text,
                                        (name) => ref
                                            .read(accountRepositoryProvider)
                                            .insert(
                                              Account(
                                                accountName: name,
                                                balance: 0,
                                                icon: 'buildingColumns',
                                                iconColor: ColorHelper.toHex(
                                                  Colors.blue,
                                                ),
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => Account(
                                                id: id,
                                                accountName: name,
                                                balance: 0,
                                                icon: 'buildingColumns',
                                                iconColor: ColorHelper.toHex(
                                                  Colors.blue,
                                                ),
                                                priority: 99,
                                              ),
                                            ),
                                        (a) => setState(() => _accountId = a.id),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: _accountKeyword,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Keyword used to identify account',
                                        hintText: 'e.g., HDFC Bank',
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _accountKeyword = v),
                                    ),
                                  ],
                                ),
                              ],

                              if (_nature != 'TRANSFERS') ...[
                                // 6. Card Section
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  leading: const Icon(
                                    Icons.credit_card,
                                    color: AppColors.primary,
                                  ),
                                  title: const Text(
                                    'Card Rule',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    16,
                                  ),
                                  children: [
                                    AutocompleteField<model.Card>(
                                      label: 'Card',
                                      initialItem: _cardId == null
                                          ? null
                                          : _cards
                                                .where((c) => c.id == _cardId)
                                                .firstOrNull,
                                      items: _cards,
                                      displayStringForOption: (c) => c.cardName,
                                      onChanged: (c) =>
                                          setState(() => _cardId = c?.id),
                                      onAddNew: (text) => _addNew<model.Card>(
                                        'Card',
                                        text,
                                        (name) => ref
                                            .read(cardRepositoryProvider)
                                            .insert(
                                              model.Card(
                                                accountId: _accountId,
                                                cardName: name,
                                                cardType: 'Credit',
                                                cardNumber: '0000',
                                                cardExpiryDate: '12/99',
                                                cardNetwork: 'Visa',
                                                balance: 0,
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => model.Card(
                                                id: id,
                                                accountId: _accountId,
                                                cardName: name,
                                                cardType: 'Credit',
                                                cardNumber: '0000',
                                                cardExpiryDate: '12/99',
                                                cardNetwork: 'Visa',
                                                balance: 0,
                                                priority: 99,
                                              ),
                                            ),
                                        (c) => setState(() => _cardId = c.id),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: _cardKeyword,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Keyword used to identify card',
                                        hintText: 'e.g., ending with 1234',
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _cardKeyword = v),
                                    ),
                                  ],
                                ),
                              ],

                              if (_nature != 'TRANSFERS') ...[
                                // 7. Merchant Section
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  leading: const Icon(
                                    Icons.store,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    _nature == 'INVESTMENTS' ? 'Investment Platform Rule' : 'Merchant Rule',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    16,
                                  ),
                                  children: [
                                    RawAutocomplete<String>(
                                      textEditingController: _merchantKeywordCtrl,
                                      focusNode: _merchantKeywordFocus,
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty ||
                                                (_merchantKeywordLastSelectedText !=
                                                        null &&
                                                    textEditingValue.text ==
                                                        _merchantKeywordLastSelectedText)) {
                                              return const Iterable<
                                                String
                                              >.empty();
                                            }
                                            return textTokens.where((
                                              String option,
                                            ) {
                                              return option
                                                  .toLowerCase()
                                                  .contains(
                                                    textEditingValue.text
                                                        .toLowerCase(),
                                                  );
                                            });
                                          },
                                      fieldViewBuilder:
                                          (
                                            context,
                                            textEditingController,
                                            focusNode,
                                            onFieldSubmitted,
                                          ) {
                                            return TextFormField(
                                              controller: textEditingController,
                                              focusNode: focusNode,
                                              scrollPadding:
                                                  const EdgeInsets.only(
                                                    bottom: 250,
                                                  ),
                                              onChanged: (_) {
                                                _merchantKeywordLastSelectedText =
                                                    null;
                                              },
                                              decoration: InputDecoration(
                                                labelText: _nature == 'INVESTMENTS'
                                                    ? 'Platform Keyword (Auto-suggests)'
                                                    : 'Merchant Keyword (Auto-suggests)',
                                                hintText:
                                                    'e.g. q321SDf54sf64sdv6@ybl',
                                              ),
                                            );
                                          },
                                      optionsViewBuilder: (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  32, // Parent width
                                              child: ListView.builder(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (context, index) {
                                                  final option = options
                                                      .elementAt(index);
                                                  return InkWell(
                                                    onTap: () {
                                                      _merchantKeywordLastSelectedText =
                                                          option;
                                                      onSelected(option);
                                                      // Do not unfocus keyword field after selection
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 12,
                                                          ),
                                                      child: Text(option),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    AutocompleteField<Merchant>(
                                      label: _nature == 'INVESTMENTS' ? 'Platform Name' : 'Merchant Name',
                                      initialItem: _merchantId == null
                                          ? null
                                          : _merchants
                                                .where((m) => m.id == _merchantId)
                                                .firstOrNull,
                                      items: _merchants,
                                      displayStringForOption: (m) =>
                                          m.merchantName,
                                      onChanged: (m) {
                                        setState(() => _merchantId = m?.id);
                                        if (m != null) {
                                          // Auto-populate Category, SubCategory, and Purpose from existing rules
                                          ref
                                              .read(
                                                merchantRuleRepositoryProvider,
                                              )
                                              .getByMerchantId(m.id!)
                                              .then((rule) {
                                                if (rule != null && mounted) {
                                                  setState(() {
                                                    if (rule.categoryId != null)
                                                      _categoryId =
                                                          rule.categoryId;
                                                    if (rule.subcategoryId !=
                                                        null)
                                                      _subcategoryId =
                                                          rule.subcategoryId;
                                                    if (rule.purposeId != null)
                                                      _purposeId = rule.purposeId;
                                                    if (rule.goalId != null)
                                                      _goalId = rule.goalId;
                                                  });
                                                  if (rule.categoryId != null) {
                                                    _loadSubs(
                                                      rule.categoryId!,
                                                      rule.subcategoryId,
                                                    );
                                                  }
                                                }
                                              });
                                        }
                                      },
                                      onAddNew: (text) {
                                        final existingColors = _merchants
                                            .map((m) => m.iconColor)
                                            .whereType<String>()
                                            .toList();
                                        final newColor =
                                            ColorHelper.generateUniqueColor(
                                              existingColors,
                                            );
                                        _addNew<Merchant>(
                                          _nature == 'INVESTMENTS' ? 'Investment Platform' : 'Merchant',
                                          text,
                                          (name) => ref
                                              .read(merchantRepositoryProvider)
                                              .insert(
                                                Merchant(
                                                  merchantName: name,
                                                  priority: 99,
                                                  iconColor: newColor,
                                                  icon: 'store',
                                                ).toMap(),
                                              )
                                              .then(
                                                (id) => Merchant(
                                                  id: id,
                                                  merchantName: name,
                                                  priority: 99,
                                                  iconColor: newColor,
                                                  icon: 'store',
                                                ),
                                              ),
                                          (m) =>
                                              setState(() => _merchantId = m.id),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Goal selection inside Merchant Rule
                                    if (_nature == 'INVESTMENTS') ...[
                                      AutocompleteField<InvestmentGoal>(
                                        label: 'Investment Goal',
                                        initialItem: _goalId == null
                                            ? null
                                            : _goals
                                                .where((g) => g.id == _goalId)
                                                .firstOrNull,
                                        items: _goals,
                                        displayStringForOption: (g) => g.goalName,
                                        onChanged: (g) {
                                          setState(() {
                                            _goalId = g?.id;
                                            if (g != null) {
                                              _categoryId = g.categoryId;
                                              _subcategoryId = g.subcategoryId;
                                              _purposeId = g.purposeId;
                                            }
                                          });
                                          if (g?.categoryId != null) {
                                            _loadSubs(g!.categoryId, g.subcategoryId);
                                          }
                                        },
                                        onAddNew: (text) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Add new goals in Settings > Planner',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    AutocompleteField<Category>(
                                      label: 'Category',
                                      initialItem: _categoryId == null
                                          ? null
                                          : _categories
                                                .where((c) => c.id == _categoryId)
                                                .firstOrNull,
                                      items: _categories
                                          .where(
                                            (c) =>
                                                c.categoryType ==
                                                _currentCategoryType,
                                          )
                                          .toList(),
                                      displayStringForOption: (c) =>
                                          c.categoryName,
                                      onChanged: (c) {
                                        setState(() => _categoryId = c?.id);
                                        if (c != null) {
                                          _loadSubs(c.id!);
                                        } else {
                                          setState(() {
                                            _subCategories = [];
                                            _subcategoryId = null;
                                          });
                                        }
                                      },
                                      onAddNew: (text) => _addNew<Category>(
                                        'Category',
                                        text,
                                        (name) => ref
                                            .read(categoryRepositoryProvider)
                                            .insert(
                                              Category(
                                                categoryName: name,
                                                icon: 'circleQuestion',
                                                iconColor: ColorHelper.toHex(
                                                  Colors.grey,
                                                ),
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => Category(
                                                id: id,
                                                categoryName: name,
                                                icon: 'circleQuestion',
                                                iconColor: ColorHelper.toHex(
                                                  Colors.grey,
                                                ),
                                                priority: 99,
                                              ),
                                            ),
                                        (c) => setState(() => _categoryId = c.id),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AutocompleteField<SubCategory>(
                                      label: 'Sub-Category',
                                      initialItem: _subcategoryId == null
                                          ? null
                                          : _subCategories
                                                .where(
                                                  (s) => s.id == _subcategoryId,
                                                )
                                                .firstOrNull,
                                      items: _subCategories,
                                      displayStringForOption: (s) =>
                                          s.subcategoryName,
                                      onChanged: (s) =>
                                          setState(() => _subcategoryId = s?.id),
                                      onAddNew: (text) {
                                        if (_categoryId == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please select a Category first',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }
                                        _addNew<SubCategory>(
                                          'Sub-Category',
                                          text,
                                          (name) => ref
                                              .read(subCategoryRepositoryProvider)
                                              .insert(
                                                SubCategory(
                                                  categoryId: _categoryId!,
                                                  subcategoryName: name,
                                                  priority: 99,
                                                ).toMap(),
                                              )
                                              .then(
                                                (id) => SubCategory(
                                                  id: id,
                                                  categoryId: _categoryId!,
                                                  subcategoryName: name,
                                                  priority: 99,
                                                ),
                                              ),
                                          (s) {
                                            setState(() => _subcategoryId = s.id);
                                            _loadSubs(_categoryId!, s.id);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    AutocompleteField<ExpensePurpose>(
                                      label: 'Expense Purpose',
                                      initialItem: _purposeId == null
                                          ? null
                                          : _purposes
                                                .where((p) => p.id == _purposeId)
                                                .firstOrNull,
                                      items: _purposes,
                                      displayStringForOption: (p) => p.expenseFor,
                                      onChanged: (p) =>
                                          setState(() => _purposeId = p?.id),
                                      onAddNew: (text) => _addNew<ExpensePurpose>(
                                        'Expense Purpose',
                                        text,
                                        (name) => ref
                                            .read(
                                              expensePurposeRepositoryProvider,
                                            )
                                            .insert(
                                              ExpensePurpose(
                                                expenseFor: name,
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => ExpensePurpose(
                                                id: id,
                                                expenseFor: name,
                                                priority: 99,
                                              ),
                                            ),
                                        (p) => setState(() => _purposeId = p.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (_nature != 'TRANSFERS') ...[
                                // 8. Expense Source Section
                                ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  leading: const Icon(
                                    Icons.source,
                                    color: AppColors.primary,
                                  ),
                                  title: const Text(
                                    'Expense Source',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    16,
                                  ),
                                  children: [
                                    AutocompleteField<ExpenseSource>(
                                      label: 'Expense Source',
                                      initialItem: _expenseSourceId == null
                                          ? null
                                          : _expenseSources
                                                .where(
                                                  (s) => s.id == _expenseSourceId,
                                                )
                                                .firstOrNull,
                                      items: _expenseSources,
                                      displayStringForOption: (s) =>
                                          s.expenseSourceName,
                                      onChanged: (s) => setState(
                                        () => _expenseSourceId = s?.id,
                                      ),
                                      onAddNew: (text) => _addNew<ExpenseSource>(
                                        'Expense Source',
                                        text,
                                        (name) => ref
                                            .read(expenseSourceRepositoryProvider)
                                            .insert(
                                              ExpenseSource(
                                                expenseSourceName: name,
                                                priority: 99,
                                              ).toMap(),
                                            )
                                            .then(
                                              (id) => ExpenseSource(
                                                id: id,
                                                expenseSourceName: name,
                                                priority: 99,
                                              ),
                                            ),
                                        (s) => setState(
                                          () => _expenseSourceId = s.id,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Footer
                        if (widget.showSaveRule)
                          Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 16),
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.secondaryContainer,
                              ),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              value: _saveAsRule,
                              onChanged: (v) =>
                                  setState(() => _saveAsRule = v ?? true),
                              title: const Text(
                                'Save as rule for future messages',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'New rules will be created automatically based on inputs above.',
                                style: TextStyle(fontSize: 12),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              visualDensity: VisualDensity.compact,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.label_rounded, size: 18),
                          label: Text(
                            _saving ? 'Saving…' : 'Save Label & Rules',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
