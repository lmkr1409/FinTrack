import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/payment_method.dart';
import '../../../services/providers.dart';

/// Accounts, Cards & Payment Methods CRUD tab.
/// Uses a segmented button to switch between the three views.
class AccountsPaymentsTab extends ConsumerStatefulWidget {
  const AccountsPaymentsTab({super.key});

  @override
  ConsumerState<AccountsPaymentsTab> createState() => _AccountsPaymentsTabState();
}

enum _Segment { accounts, cards, payments }

class _AccountsPaymentsTabState extends ConsumerState<AccountsPaymentsTab> {
  _Segment _segment = _Segment.accounts;

  List<Account> _accounts = [];
  List<model.Card> _cards = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    setState(() {
      _accounts = accounts;
      _cards = cards;
      _paymentMethods = methods;
      _loading = false;
    });
  }

  // ─── Account Dialogs ────────────────────────────────────

  Future<void> _showAccountDialog({Account? account}) async {
    final nameCtrl = TextEditingController(text: account?.accountName ?? '');
    final balCtrl = TextEditingController(text: account?.balance.toString() ?? '0');
    final iconCtrl = TextEditingController(text: account?.icon ?? 'account_balance');
    final colorCtrl = TextEditingController(text: account?.iconColor ?? '#1E88E5');
    final isEdit = account != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Account' : 'Add Account'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: balCtrl, decoration: const InputDecoration(labelText: 'Balance', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: iconCtrl, decoration: InputDecoration(labelText: 'Icon Name', border: const OutlineInputBorder(), suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)))),
            const SizedBox(height: 12),
            TextField(controller: colorCtrl, decoration: InputDecoration(labelText: 'Icon Color (hex)', border: const OutlineInputBorder(), suffixIcon: CircleAvatar(radius: 12, backgroundColor: ColorHelper.fromHex(colorCtrl.text)))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(accountRepositoryProvider);
    if (isEdit) {
      await repo.updateAccount(account.copyWith(accountName: name, balance: double.tryParse(balCtrl.text) ?? 0, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertAccount(Account(accountName: name, balance: double.tryParse(balCtrl.text) ?? 0, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${account.accountName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountRepositoryProvider).deleteAccount(account.id!);
      await _loadData();
    }
  }

  // ─── Card Dialogs ──────────────────────────────────────

  Future<void> _showCardDialog({model.Card? card}) async {
    final nameCtrl = TextEditingController(text: card?.cardName ?? '');
    final numberCtrl = TextEditingController(text: card?.cardNumber ?? '');
    final expiryCtrl = TextEditingController(text: card?.cardExpiryDate ?? '');
    final iconCtrl = TextEditingController(text: card?.icon ?? 'credit_card');
    final colorCtrl = TextEditingController(text: card?.iconColor ?? '#1E88E5');
    String selectedType = card?.cardType ?? 'CREDIT';
    String selectedNetwork = card?.cardNetwork ?? 'VISA';
    int? selectedAccountId = card?.accountId;
    final isEdit = card != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Card' : 'Add Card'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Card Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Card Type', border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: 'CREDIT', child: Text('Credit')), DropdownMenuItem(value: 'DEBIT', child: Text('Debit'))],
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Card Number', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry (YYYY-MM-DD)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedNetwork,
                decoration: const InputDecoration(labelText: 'Network', border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: 'VISA', child: Text('Visa')), DropdownMenuItem(value: 'MASTERCARD', child: Text('Mastercard')), DropdownMenuItem(value: 'RUPAY', child: Text('RuPay'))],
                onChanged: (v) => setDialogState(() => selectedNetwork = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedAccountId,
                decoration: const InputDecoration(labelText: 'Linked Account', border: OutlineInputBorder()),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ..._accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.accountName)))],
                onChanged: (v) => setDialogState(() => selectedAccountId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: iconCtrl, decoration: InputDecoration(labelText: 'Icon Name', border: const OutlineInputBorder(), suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)))),
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
    final repo = ref.read(cardRepositoryProvider);
    if (isEdit) {
      await repo.updateCard(card.copyWith(cardName: name, cardType: selectedType, cardNumber: numberCtrl.text.trim(), cardExpiryDate: expiryCtrl.text.trim(), cardNetwork: selectedNetwork, accountId: selectedAccountId, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertCard(model.Card(cardName: name, cardType: selectedType, cardNumber: numberCtrl.text.trim(), cardExpiryDate: expiryCtrl.text.trim(), cardNetwork: selectedNetwork, balance: 0, accountId: selectedAccountId, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeleteCard(model.Card card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Delete "${card.cardName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cardRepositoryProvider).deleteCard(card.id!);
      await _loadData();
    }
  }

  // ─── Payment Method Dialogs ─────────────────────────────

  Future<void> _showPaymentMethodDialog({PaymentMethod? method}) async {
    final nameCtrl = TextEditingController(text: method?.paymentMethodName ?? '');
    final iconCtrl = TextEditingController(text: method?.icon ?? 'payments');
    final colorCtrl = TextEditingController(text: method?.iconColor ?? '#607D8B');
    final isEdit = method != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Method Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: iconCtrl, decoration: InputDecoration(labelText: 'Icon Name', border: const OutlineInputBorder(), suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)))),
            const SizedBox(height: 12),
            TextField(controller: colorCtrl, decoration: InputDecoration(labelText: 'Icon Color (hex)', border: const OutlineInputBorder(), suffixIcon: CircleAvatar(radius: 12, backgroundColor: ColorHelper.fromHex(colorCtrl.text)))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Update' : 'Add')),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(paymentMethodRepositoryProvider);
    if (isEdit) {
      await repo.updatePaymentMethod(method.copyWith(paymentMethodName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    } else {
      await repo.insertPaymentMethod(PaymentMethod(paymentMethodName: name, icon: iconCtrl.text.trim(), iconColor: colorCtrl.text.trim()));
    }
    await _loadData();
  }

  Future<void> _confirmDeletePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Delete "${method.paymentMethodName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(paymentMethodRepositoryProvider).deletePaymentMethod(method.id!);
      await _loadData();
    }
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_Segment>(
              segments: const [
                ButtonSegment(value: _Segment.accounts, label: Text('Accounts'), icon: Icon(Icons.account_balance_rounded, size: 18)),
                ButtonSegment(value: _Segment.cards, label: Text('Cards'), icon: Icon(Icons.credit_card_rounded, size: 18)),
                ButtonSegment(value: _Segment.payments, label: Text('Payments'), icon: Icon(Icons.payments_rounded, size: 18)),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          // List content
          Expanded(child: _buildSegmentContent(colorScheme)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_segment) {
            case _Segment.accounts:
              _showAccountDialog();
            case _Segment.cards:
              _showCardDialog();
            case _Segment.payments:
              _showPaymentMethodDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSegmentContent(ColorScheme cs) {
    switch (_segment) {
      case _Segment.accounts:
        return _buildAccountsList(cs);
      case _Segment.cards:
        return _buildCardsList(cs);
      case _Segment.payments:
        return _buildPaymentMethodsList(cs);
    }
  }

  Widget _buildAccountsList(ColorScheme cs) {
    if (_accounts.isEmpty) return Center(child: Text('No accounts yet.', style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _accounts.length,
      itemBuilder: (context, i) {
        final a = _accounts[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromHex(a.iconColor).withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(a.icon), color: ColorHelper.fromHex(a.iconColor)),
            ),
            title: Text(a.accountName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Balance: ₹${a.balance.toStringAsFixed(2)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showAccountDialog(account: a)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeleteAccount(a)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildCardsList(ColorScheme cs) {
    if (_cards.isEmpty) return Center(child: Text('No cards yet.', style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _cards.length,
      itemBuilder: (context, i) {
        final c = _cards[i];
        final linkedAccount = _accounts.where((a) => a.id == c.accountId).firstOrNull;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromHex(c.iconColor).withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(c.icon), color: ColorHelper.fromHex(c.iconColor)),
            ),
            title: Text(c.cardName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.cardType} • ${c.cardNetwork}${linkedAccount != null ? ' • ${linkedAccount.accountName}' : ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showCardDialog(card: c)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeleteCard(c)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsList(ColorScheme cs) {
    if (_paymentMethods.isEmpty) return Center(child: Text('No payment methods yet.', style: TextStyle(color: cs.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, i) {
        final m = _paymentMethods[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorHelper.fromHex(m.iconColor).withValues(alpha: 0.15),
              child: Icon(IconHelper.getIcon(m.icon), color: ColorHelper.fromHex(m.iconColor)),
            ),
            title: Text(m.paymentMethodName, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showPaymentMethodDialog(method: m)),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: cs.error), onPressed: () => _confirmDeletePaymentMethod(m)),
            ]),
          ),
        );
      },
    );
  }
}
