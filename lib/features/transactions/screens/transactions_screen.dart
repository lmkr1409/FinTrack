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
import 'transaction_filter_sheet.dart';
import 'upload_statement_screen.dart';

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

  String? _startDate;
  String? _endDate;
  String? _transactionType;
  int? _filterCategoryId;
  int? _filterAccountId;
  int? _filterMerchantId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    _endDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    _categoryMap = {for (final c in categories) c.id!: c};
    _accountMap = {for (final a in accounts) a.id!: a};
    _merchantMap = {for (final m in merchants) m.id!: m};
    final transactions = await ref.read(transactionRepositoryProvider).getFiltered(
          startDate: _startDate, endDate: _endDate, transactionType: _transactionType,
          categoryId: _filterCategoryId, accountId: _filterAccountId, merchantId: _filterMerchantId,
        );
    setState(() { _transactions = transactions; _loading = false; });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true,
      builder: (_) => TransactionFilterSheet(
        startDate: _startDate, endDate: _endDate, transactionType: _transactionType,
        categoryId: _filterCategoryId, accountId: _filterAccountId, merchantId: _filterMerchantId,
        categories: _categoryMap.values.toList(), accounts: _accountMap.values.toList(), merchants: _merchantMap.values.toList(),
      ),
    );
    if (result == null) return;
    setState(() {
      _startDate = result['startDate']; _endDate = result['endDate'];
      _transactionType = result['transactionType']; _filterCategoryId = result['categoryId'];
      _filterAccountId = result['accountId']; _filterMerchantId = result['merchantId'];
    });
    await _loadData();
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

  @override
  Widget build(BuildContext context) {
    final activeFilters = <String>[
      ?_transactionType,
      if (_filterCategoryId != null) _categoryMap[_filterCategoryId]?.categoryName ?? '',
      if (_filterAccountId != null) _accountMap[_filterAccountId]?.accountName ?? '',
      if (_filterMerchantId != null) _merchantMap[_filterMerchantId]?.merchantName ?? '',
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          actions: [
            IconButton(
              tooltip: 'Delete Transactions',
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.expense),
              onPressed: _openDeleteSheet,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(children: [
              Expanded(child: Text('${_startDate ?? '...'} → ${_endDate ?? '...'}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              Badge(
                isLabelVisible: activeFilters.isNotEmpty,
                label: Text('${activeFilters.length}'),
                child: IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: _openFilters),
              ),
              IconButton(
                tooltip: 'Delete Transactions',
                icon: Icon(Icons.delete_sweep_rounded, color: AppColors.expense.withValues(alpha: 0.8), size: 22),
                onPressed: _openDeleteSheet,
              ),
            ]),
          ),
          if (activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(spacing: 6, children: activeFilters.map((f) => Chip(label: Text(f))).toList()),
            ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(child: Text('No transactions found.', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 4),
                        itemCount: _transactions.length,
                        itemBuilder: (context, i) => _buildTxnTile(_transactions[i]),
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
        leading: CircleAvatar(
          backgroundColor: cat != null ? ColorHelper.fromHex(cat.iconColor).withValues(alpha: 0.15) : AppColors.surfaceContainer,
          child: Icon(
            cat != null ? IconHelper.getIcon(cat.icon) : (isTransfer ? Icons.swap_horiz_rounded : (isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)),
            color: cat != null ? ColorHelper.fromHex(cat.iconColor) : amountColor,
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
          IconButton(icon: Icon(Icons.delete_outline, size: 18, color: AppColors.expense.withValues(alpha: 0.7)), onPressed: () => _confirmDelete(txn)),
        ]),
      ),
    );
  }
}
