import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/payment_method.dart';
import '../../../models/transaction_rule.dart';
import '../../../services/providers.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/widgets/autocomplete_field.dart';

class TransactionRuleDialog extends ConsumerStatefulWidget {
  final TransactionRule? rule;
  final String ruleType; 
  final VoidCallback onSaved;

  const TransactionRuleDialog({
    super.key, 
    this.rule, 
    required this.ruleType, 
    required this.onSaved,
  });

  @override
  ConsumerState<TransactionRuleDialog> createState() => _TransactionRuleDialogState();
}

class _TransactionRuleDialogState extends ConsumerState<TransactionRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patternCtrl = TextEditingController();

  String? _mappedType;
  int? _paymentMethodId;
  int? _accountId;
  int? _cardId;

  // Lookup lists
  List<PaymentMethod> _paymentMethods = [];
  List<Account> _accounts = [];
  List<model.Card> _cards = [];
  
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      final r = widget.rule!;
      _patternCtrl.text = r.pattern;
      _mappedType = r.mappedType;
      _paymentMethodId = r.paymentMethodId;
      _accountId = r.accountId;
      _cardId = r.cardId;
    }
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();

    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
      _accounts = accounts;
      _cards = cards;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Additional validation based on type
    if (widget.ruleType == 'TRANSACTION_TYPE' && _mappedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Mapped Type')));
      return;
    }
    if (widget.ruleType == 'PAYMENT_METHOD' && _paymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Payment Method')));
      return;
    }
    if (widget.ruleType == 'ACCOUNT' && _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an Account')));
      return;
    }
    if (widget.ruleType == 'CARD' && _cardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Card')));
      return;
    }

    setState(() => _saving = true);

    final ruleMap = <String, dynamic>{
      if (widget.rule != null) 'rule_id': widget.rule!.id,
      'rule_type': widget.ruleType,
      'pattern': _patternCtrl.text.trim(),
      'mapped_type': _mappedType,
      'payment_method_id': _paymentMethodId,
      'account_id': _accountId,
      'card_id': _cardId,
      'updated_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    final repo = ref.read(transactionRuleRepositoryProvider);
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

  String _getDialogTitle() {
    switch(widget.ruleType) {
      case 'AMOUNT_REGEX': return 'Amount Regex Rule';
      case 'BANK_SENDER': return 'Bank Sender Rule';
      case 'TRANSACTION_TYPE': return 'Transaction Type Rule';
      case 'PAYMENT_METHOD': return 'Payment Method Rule';
      case 'ACCOUNT': return 'Account Rule';
      case 'CARD': return 'Card Rule';
      default: return 'Transaction Rule';
    }
  }

  IconData _getDialogIcon() {
    switch(widget.ruleType) {
      case 'AMOUNT_REGEX': return Icons.data_object;
      case 'BANK_SENDER': return Icons.business;
      case 'TRANSACTION_TYPE': return Icons.swap_horiz;
      case 'PAYMENT_METHOD': return Icons.payment;
      case 'ACCOUNT': return Icons.account_balance;
      case 'CARD': return Icons.credit_card;
      default: return Icons.rule;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final colorScheme = Theme.of(context).colorScheme;

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
                  child: Icon(_getDialogIcon(), color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.rule == null ? 'New ${_getDialogTitle()}' : 'Edit ${_getDialogTitle()}',
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).viewInsets.bottom),
                children: [
                  TextFormField(
                    controller: _patternCtrl,
                    decoration: InputDecoration(
                      labelText: widget.ruleType == 'AMOUNT_REGEX' ? 'Regular Expression' : 'Keyword Pattern',
                      hintText: widget.ruleType == 'AMOUNT_REGEX' ? 'e.g. INR\\s*(\\d+)' : (widget.ruleType == 'BANK_SENDER' ? 'e.g. HDFCBK' : 'e.g. debited'),
                      prefixIcon: const Icon(Icons.key_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a pattern' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  if (widget.ruleType != 'AMOUNT_REGEX' && widget.ruleType != 'BANK_SENDER') ...[
                    const Text('Mapping', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                  ],
                  
                  if (widget.ruleType == 'TRANSACTION_TYPE')
                    DropdownButtonFormField<String?>(
                      initialValue: _mappedType,
                      decoration: const InputDecoration(labelText: 'Transaction Type', prefixIcon: Icon(Icons.swap_horiz_rounded)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Select Type')),
                        DropdownMenuItem(value: 'DEBIT', child: Text('Debit (Expense)')),
                        DropdownMenuItem(value: 'CREDIT', child: Text('Credit (Income)')),
                        DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer')),
                      ],
                      onChanged: (val) => setState(() => _mappedType = val),
                    ),
                  
                  if (widget.ruleType == 'PAYMENT_METHOD')
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
                  
                  if (widget.ruleType == 'ACCOUNT')
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
                  
                  if (widget.ruleType == 'CARD')
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
