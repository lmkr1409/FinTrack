import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/account.dart';
import '../../../models/category.dart';
import '../../../models/merchant.dart';
import '../../../models/transaction.dart';
import '../../../services/providers.dart';
import '../../../widgets/glass_card.dart';
import 'add_transaction_screen.dart';
import 'delete_transactions_sheet.dart';
import 'upload_statement_screen.dart';
import '../../../services/sms_listener_service.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import 'package:intl/intl.dart';

/// Main Transactions screen with glassmorphic cards and themed accents.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Transaction> _transactions = [];
  Map<int, Category> _categoryMap = {};
  Map<int, Account> _accountMap = {};
  Map<int, Merchant> _merchantMap = {};
  bool _loading = true;

  int? _filterMonth;
  int? _filterYear;
  String? _transactionType;
  int? _filterCategoryId;
  int? _filterAccountId;
  int? _filterMerchantId;
  String? _filterSort;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterMonth = now.month;
    _filterYear = now.year;
    _loadData();
  }

  Future<void> _handleRefresh() async {
    final container = ProviderScope.containerOf(context);
    await SmsListenerService.syncInboxMessages(container);
    await _loadData();
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    _categoryMap = {for (final c in categories) c.id!: c};
    _accountMap = {for (final a in accounts) a.id!: a};
    _merchantMap = {for (final m in merchants) m.id!: m};
    final transactions = await ref.read(transactionRepositoryProvider).getFiltered(
          month: _filterMonth, year: _filterYear, transactionType: _transactionType,
          categoryId: _filterCategoryId, accountId: _filterAccountId, merchantId: _filterMerchantId,
          orderBy: _filterSort,
        );
    setState(() { _transactions = transactions; _loading = false; });
  }

  Future<void> _openAddTransaction() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
    if (added == true) await _loadData();
  }

  Future<void> _openUploadStatement() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const UploadStatementScreen()));
    if (added == true) await _loadData();
  }

  void _openDeleteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DeleteTransactionsSheet(onDeleted: _loadData),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.navIndicator, child: Icon(Icons.edit_rounded, color: AppColors.primary)),
              title: const Text('Manual Entry', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Add a single transaction manually'),
              onTap: () { Navigator.pop(ctx); _openAddTransaction(); },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.navIndicator, child: Icon(Icons.upload_file_rounded, color: AppColors.primary)),
              title: const Text('Upload Statement', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Import from CSV / XLSX bank statement'),
              onTap: () { Navigator.pop(ctx); _openUploadStatement(); },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Transaction txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete transaction of ₹${txn.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.expense), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(transactionRepositoryProvider).deleteTransaction(txn.id!);
      await _loadData();
    }
  }

  Future<void> _editTransaction(Transaction txn) async {
    String type = txn.transactionType;
    final amountController = TextEditingController(text: txn.amount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Transaction'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'DEBIT', child: Text('Expense (Debit)')),
                      DropdownMenuItem(value: 'CREDIT', child: Text('Income (Credit)')),
                      DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      final newAmount = double.parse(amountController.text);
      if (newAmount != txn.amount || type != txn.transactionType || (!txn.labeled && txn.isAutoLabeled)) {
        final updatedTxn = txn.copyWith(
          amount: newAmount,
          transactionType: type,
          labeled: true,
          isAutoLabeled: false,
          updatedTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        );
        await ref.read(transactionRepositoryProvider).updateTransaction(updatedTxn);
        await _loadData();
      }
    }
    
    // Dispose after dialog animation completes to prevent 'used after disposed' exceptions
    Future.delayed(const Duration(milliseconds: 300), () {
      amountController.dispose();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          actions: [],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: _transactions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: const Center(child: Text('No transactions found.', style: TextStyle(color: AppColors.textMuted))),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemCount: _transactions.length,
                            itemBuilder: (context, i) => _buildTxnTile(_transactions[i]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddOptions, child: const Icon(Icons.add)),
    );
  }

  Widget _buildTxnTile(Transaction txn) {
    final cat = txn.categoryId != null ? _categoryMap[txn.categoryId] : null;
    final account = txn.accountId != null ? _accountMap[txn.accountId] : null;
    final merchant = txn.merchantId != null ? _merchantMap[txn.merchantId] : null;
    final isDebit = txn.transactionType == 'DEBIT';
    final isTransfer = txn.transactionType == 'TRANSFER';
    final amountColor = isTransfer ? AppColors.info : (isDebit ? AppColors.expense : AppColors.income);
    return GlassCard(
      child: ListTile(
        onTap: () => _editTransaction(txn),
        leading: CircleAvatar(
          backgroundColor: cat != null ? ColorHelper.fromHex(cat.iconColor).withValues(alpha: 0.15) : AppColors.surfaceContainer,
          child: cat != null
            ? Icon(IconHelper.getIcon(cat.icon), color: ColorHelper.fromHex(cat.iconColor))
            : Icon(
                isTransfer ? Icons.swap_horiz_rounded : (isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                color: isDebit ? AppColors.expense : AppColors.income,
              ),
        ),
        title: Text(
          txn.description ?? (merchant?.merchantName ?? cat?.categoryName ?? txn.transactionType),
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [txn.transactionDate, if (account != null) account.accountName, if (cat != null) cat.categoryName].join(' • '),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${isTransfer ? '' : (isDebit ? '-' : '+')}₹${txn.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: amountColor)),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.expense.withValues(alpha: 0.7)),
            onPressed: () => _confirmDelete(txn),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Delete Transactions Icon Button built into the row for convenience
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete Transactions',
            icon: Icon(Icons.delete_sweep_rounded, color: AppColors.expense.withValues(alpha: 0.8), size: 24),
            onPressed: _openDeleteSheet,
          ),
          const SizedBox(width: 12),
          _buildDropdown<String>(
            context: context,
            hint: 'Sort',
            value: _filterSort,
            items: const [
              DropdownMenuItem(value: 'transaction_date DESC, created_time DESC', child: Text('Date (Newest)')),
              DropdownMenuItem(value: 'transaction_date ASC, created_time ASC', child: Text('Date (Oldest)')),
              DropdownMenuItem(value: 'amount DESC', child: Text('Amount (High-Low)')),
              DropdownMenuItem(value: 'amount ASC', child: Text('Amount (Low-High)')),
            ],
            onChanged: (v) { setState(() => _filterSort = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          _buildDropdown<int>(
            context: context,
            hint: 'Year',
            value: _filterYear,
            items: List.generate(10, (i) => DropdownMenuItem(value: DateTime.now().year - i, child: Text('${DateTime.now().year - i}'))),
            onChanged: (v) { setState(() => _filterYear = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          _buildDropdown<int>(
            context: context,
            hint: 'Month',
            value: _filterMonth,
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMM').format(DateTime(2020, i + 1))))),
            onChanged: (v) { setState(() => _filterMonth = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          _buildDropdown<int>(
            context: context,
            hint: 'Category',
            value: _filterCategoryId,
            items: _categoryMap.values.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))).toList(),
            onChanged: (v) { setState(() => _filterCategoryId = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          _buildDropdown<int>(
            context: context,
            hint: 'Account',
            value: _filterAccountId,
            items: _accountMap.values.map((a) => DropdownMenuItem(value: a.id, child: Text(a.accountName))).toList(),
            onChanged: (v) { setState(() => _filterAccountId = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          _buildDropdown<int>(
            context: context,
            hint: 'Merchant',
            value: _filterMerchantId,
            items: _merchantMap.values.map((m) => DropdownMenuItem(value: m.id, child: Text(m.merchantName))).toList(),
            onChanged: (v) { setState(() => _filterMerchantId = v); _loadData(); },
          ),
          const SizedBox(width: 8),
          _buildDropdown<String>(
            context: context,
            hint: 'Type',
            value: _transactionType,
            items: const [
              DropdownMenuItem(value: 'DEBIT', child: Text('Debit')),
              DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
              DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer')),
            ],
            onChanged: (v) { setState(() => _transactionType = v); _loadData(); },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required BuildContext context,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          items: [
            DropdownMenuItem<T>(value: null, child: Text('All $hint', style: const TextStyle(fontSize: 12))),
            ...items.map((i) => DropdownMenuItem<T>(value: i.value, child: DefaultTextStyle(style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), child: i.child))),
          ],
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        ),
      ),
    );
  }
}
