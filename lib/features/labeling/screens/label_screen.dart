import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
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
import '../../../services/sms_listener_service.dart';
import '../../../widgets/glass_card.dart';
import 'label_dialog.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../transactions/screens/upload_statement_screen.dart';

/// Screen with Unlabeled / Labeled tabs for reviewing and labeling transactions.
class LabelScreen extends ConsumerStatefulWidget {
  const LabelScreen({super.key});

  @override
  ConsumerState<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends ConsumerState<LabelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Transaction> _all = [];
  List<Transaction> _unlabeled = [];
  List<Transaction> _autoLabeled = [];
  List<Transaction> _labeled = [];

  // Filters
  int? _filterMonth;
  int? _filterYear;
  int? _filterAccountId;
  int? _filterCardId;
  int? _filterCategoryId;
  int? _filterMerchantId;
  String? _filterType;
  String? _filterNature;
  String? _filterSort;

  // Lookup maps for displaying labels
  Map<int, Category> _categoryMap = {};
  Map<int, SubCategory> _subCategoryMap = {};
  Map<int, Merchant> _merchantMap = {};
  Map<int, Account> _accountMap = {};
  Map<int, model.Card> _cardMap = {};
  Map<int, PaymentMethod> _paymentMethodMap = {};
  Map<int, ExpenseSource> _expenseSourceMap = {};
  Map<int, ExpensePurpose> _purposeMap = {};

  bool _loading = true;
  bool _isSyncing = false;
  int _syncTotal = 0;
  int _syncCurrent = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final container = ProviderScope.containerOf(context);
    await SmsListenerService.syncInboxMessages(container);
    await _loadData();
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);

    final repo = ref.read(transactionRepositoryProvider);

    final all = await repo.getFiltered(
      month: _filterMonth,
      year: _filterYear,
      accountId: _filterAccountId,
      cardId: _filterCardId,
      categoryId: _filterCategoryId,
      merchantId: _filterMerchantId,
      transactionType: _filterType,
      nature: _filterNature,
      orderBy: _filterSort,
    );
    final unlabeled = await repo.getFiltered(
      labeled: false,
      isAutoLabeled: false,
      month: _filterMonth,
      year: _filterYear,
      accountId: _filterAccountId,
      cardId: _filterCardId,
      categoryId: _filterCategoryId,
      merchantId: _filterMerchantId,
      transactionType: _filterType,
      nature: _filterNature,
      orderBy: _filterSort,
    );
    final autoLabeled = await repo.getFiltered(
      labeled: false,
      isAutoLabeled: true,
      month: _filterMonth,
      year: _filterYear,
      accountId: _filterAccountId,
      cardId: _filterCardId,
      categoryId: _filterCategoryId,
      merchantId: _filterMerchantId,
      transactionType: _filterType,
      nature: _filterNature,
      orderBy: _filterSort,
    );
    final labeled = await repo.getFiltered(
      labeled: true,
      month: _filterMonth,
      year: _filterYear,
      accountId: _filterAccountId,
      cardId: _filterCardId,
      categoryId: _filterCategoryId,
      merchantId: _filterMerchantId,
      transactionType: _filterType,
      nature: _filterNature,
      orderBy: _filterSort,
    );

    final categories = await ref
        .read(categoryRepositoryProvider)
        .getAllSorted();
    final subCats = await ref.read(subCategoryRepositoryProvider).getAll();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final methods = await ref
        .read(paymentMethodRepositoryProvider)
        .getAllSorted();
    final sources = await ref
        .read(expenseSourceRepositoryProvider)
        .getAllSorted();
    final purposes = await ref
        .read(expensePurposeRepositoryProvider)
        .getAllSorted();

    if (!mounted) return;
    setState(() {
      _all = all;
      _unlabeled = unlabeled;
      _autoLabeled = autoLabeled;
      _labeled = labeled;
      _categoryMap = {for (final c in categories) c.id!: c};
      _subCategoryMap = {for (final s in subCats) s.id!: s};
      _merchantMap = {for (final m in merchants) m.id!: m};
      _accountMap = {for (final a in accounts) a.id!: a};
      _cardMap = {for (final c in cards) c.id!: c};
      _paymentMethodMap = {for (final p in methods) p.id!: p};
      _expenseSourceMap = {for (final s in sources) s.id!: s};
      _purposeMap = {for (final p in purposes) p.id!: p};
      _loading = false;
    });
  }

  void _openLabelDialog(Transaction txn, {bool isLabeledTab = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LabelDialog(
        transaction: txn,
        onSaved: _loadData,
        showSaveRule: !isLabeledTab,
      ),
    );
  }

  Future<void> _exportFastText() async {
    if (_labeled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No labeled data to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    for (final txn in _labeled) {
      final cat = txn.categoryId != null
          ? _categoryMap[txn.categoryId]?.categoryName.replaceAll(' ', '')
          : 'None';
      final sub = txn.subcategoryId != null
          ? _subCategoryMap[txn.subcategoryId]?.subcategoryName.replaceAll(
              ' ',
              '',
            )
          : 'None';
      final merchant = txn.merchantId != null
          ? _merchantMap[txn.merchantId]?.merchantName.replaceAll(' ', '')
          : 'None';
      final method = txn.paymentMethodId != null
          ? _paymentMethodMap[txn.paymentMethodId]?.paymentMethodName
                .replaceAll(' ', '')
          : 'None';

      final type = txn.transactionType.replaceAll(' ', '');
      final desc =
          txn.description?.replaceAll('\n', ' ').replaceAll('\r', '') ?? '';

      buffer.writeln(
        '__label__${type}_${cat}_${sub}_${merchant}_$method $desc',
      );
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/fintrack_fasttext.txt');
      await file.writeAsString(buffer.toString());

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'FinTrack Labeled Dataset');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildActionBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_all, isLabeled: false, isAllTab: true),
                        _buildList(_unlabeled, isLabeled: false),
                        _buildList(_autoLabeled, isLabeled: false),
                        _buildList(_labeled, isLabeled: true, isLabeledTab: true),
                      ],
                    ),
                  ),
                  if (_isSyncing)
                    _buildSyncProgressOverlay(),
                ],
              ),
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : (tabIndex == 3
              ? FloatingActionButton.small(
                  onPressed: _exportFastText,
                  tooltip: 'Export FastText Data',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.download_rounded),
                )
              : null),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          _tabController.animateTo(index);
          setState(() {});
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt_rounded),
            label: 'All (${_all.length})',
          ),
          NavigationDestination(
            icon: const Icon(Icons.label_off_outlined),
            selectedIcon: const Icon(Icons.label_off_rounded),
            label: 'Unlabeled (${_unlabeled.length})',
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: 'Auto (${_autoLabeled.length})',
          ),
          NavigationDestination(
            icon: const Icon(Icons.label_outlined),
            selectedIcon: const Icon(Icons.label_rounded),
            label: 'Labeled (${_labeled.length})',
          ),
        ],
      ),
    );
  }

  // ── Action bar: filter chip summary + icons ──────────────────────────────
  Widget _buildActionBar() {
    final hasFilters = _filterMonth != null ||
        _filterYear != null ||
        _filterAccountId != null ||
        _filterCardId != null ||
        _filterCategoryId != null ||
        _filterMerchantId != null ||
        _filterType != null ||
        _filterNature != null ||
        _filterSort != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: hasFilters
                ? Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (_filterYear != null)
                        _chip('$_filterYear', () {
                          setState(() => _filterYear = null);
                          _loadData();
                        }),
                      if (_filterMonth != null)
                        _chip(
                          DateFormat('MMM').format(DateTime(2020, _filterMonth!)),
                          () {
                            setState(() => _filterMonth = null);
                            _loadData();
                          },
                        ),
                      if (_filterAccountId != null)
                        _chip(
                          _accountMap[_filterAccountId]?.accountName ?? 'Account',
                          () {
                            setState(() => _filterAccountId = null);
                            _loadData();
                          },
                        ),
                      if (_filterCardId != null)
                        _chip(
                          _cardMap[_filterCardId]?.cardName ?? 'Card',
                          () {
                            setState(() => _filterCardId = null);
                            _loadData();
                          },
                        ),
                      if (_filterCategoryId != null)
                        _chip(
                          _categoryMap[_filterCategoryId]?.categoryName ?? 'Category',
                          () {
                            setState(() => _filterCategoryId = null);
                            _loadData();
                          },
                        ),
                      if (_filterMerchantId != null)
                        _chip(
                          _merchantMap[_filterMerchantId]?.merchantName ?? 'Merchant',
                          () {
                            setState(() => _filterMerchantId = null);
                            _loadData();
                          },
                        ),
                      if (_filterType != null)
                        _chip(_filterType!, () {
                          setState(() => _filterType = null);
                          _loadData();
                        }),
                      if (_filterNature != null)
                        _chip(_filterNature!, () {
                          setState(() => _filterNature = null);
                          _loadData();
                        }),
                      if (_filterSort != null)
                        _chip(
                          _filterSort!.contains('DESC') && _filterSort!.contains('date')
                              ? 'Date ↓'
                              : _filterSort!.contains('ASC') && _filterSort!.contains('date')
                                  ? 'Date ↑'
                                  : _filterSort!.contains('DESC')
                                      ? 'Amount ↓'
                                      : 'Amount ↑',
                          () {
                            setState(() => _filterSort = null);
                            _loadData();
                          },
                        ),
                    ],
                  )
                : Text(
                    [
                      'All transactions',
                      'Unlabeled transactions',
                      'Auto-labeled transactions',
                      'Labeled transactions'
                    ][_tabController.index],
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: hasFilters ? AppColors.primary : AppColors.textSecondary,
            ),
            tooltip: 'Filters',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary),
            tooltip: 'Hard Reload',
            onPressed: _showHardReloadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.expense),
            tooltip: 'Bulk Delete',
            onPressed: _showDeleteSheet,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  // ── Filter dialog ─────────────────────────────────────────────────────────
  void _showFilterDialog() {
    // Local shadow copies so we can cancel
    int? month = _filterMonth;
    int? year = _filterYear;
    int? accountId = _filterAccountId;
    int? cardId = _filterCardId;
    int? categoryId = _filterCategoryId;
    int? merchantId = _filterMerchantId;
    String? type = _filterType;
    String? nature = _filterNature;
    String? sort = _filterSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget row(String label, Widget child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Expanded(child: child),
                  ],
                ),
              );

          Widget drop<T>({
            required String hint,
            required T? value,
            required List<DropdownMenuItem<T>> items,
            required ValueChanged<T?> onChanged,
          }) =>
              DropdownButtonFormField<T>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                items: [
                  DropdownMenuItem<T>(
                      value: null,
                      child: Text('All',
                          style: const TextStyle(fontSize: 12))),
                  ...items,
                ],
                onChanged: (v) => setLocal(() => onChanged(v)),
              );

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Filters',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  // Sort
                  row(
                    'Sort',
                    Row(
                      children: [
                        // Date sort
                        _sortChip(
                          label: 'Date',
                          ascValue: 'transaction_date ASC, created_time ASC',
                          descValue: 'transaction_date DESC, created_time DESC',
                          current: sort,
                          onSelect: (v) => setLocal(() => sort = v),
                        ),
                        const SizedBox(width: 8),
                        // Amount sort
                        _sortChip(
                          label: 'Amount',
                          ascValue: 'amount ASC',
                          descValue: 'amount DESC',
                          current: sort,
                          onSelect: (v) => setLocal(() => sort = v),
                        ),
                      ],
                    ),
                  ),
                  row(
                    'Year',
                    drop<int>(
                      hint: 'Year',
                      value: year,
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: DateTime.now().year - i,
                          child: Text('${DateTime.now().year - i}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      onChanged: (v) => year = v,
                    ),
                  ),
                  row(
                    'Month',
                    drop<int>(
                      hint: 'Month',
                      value: month,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            DateFormat('MMM').format(DateTime(2020, i + 1)),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      onChanged: (v) => month = v,
                    ),
                  ),
                  row(
                    'Account',
                    drop<int>(
                      hint: 'Account',
                      value: accountId,
                      items: _accountMap.values
                          .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.accountName,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => accountId = v,
                    ),
                  ),
                  row(
                    'Card',
                    drop<int>(
                      hint: 'Card',
                      value: cardId,
                      items: _cardMap.values
                          .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.cardName,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => cardId = v,
                    ),
                  ),
                  row(
                    'Category',
                    drop<int>(
                      hint: 'Category',
                      value: categoryId,
                      items: _categoryMap.values
                          .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.categoryName,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => categoryId = v,
                    ),
                  ),
                  row(
                    'Merchant',
                    drop<int>(
                      hint: 'Merchant',
                      value: merchantId,
                      items: _merchantMap.values
                          .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.merchantName,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => merchantId = v,
                    ),
                  ),
                  row(
                    'Type',
                    drop<String>(
                      hint: 'Physical Type',
                      value: type,
                      items: const [
                        DropdownMenuItem(
                            value: 'DEBIT',
                            child: Text('Debit (Out)',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(
                            value: 'CREDIT',
                            child: Text('Credit (In)',
                                style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => type = v,
                    ),
                  ),
                  row(
                    'Nature',
                    drop<String>(
                      hint: 'Nature',
                      value: nature,
                      items: const [
                        DropdownMenuItem(
                            value: 'TRANSACTIONS',
                            child: Text('Transactions',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(
                            value: 'TRANSFERS',
                            child: Text('Transfers',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(
                            value: 'INVESTMENTS',
                            child: Text('Investments',
                                style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => nature = v,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterMonth = null;
                            _filterYear = null;
                            _filterAccountId = null;
                            _filterCardId = null;
                            _filterCategoryId = null;
                            _filterMerchantId = null;
                            _filterType = null;
                            _filterSort = null;
                          });
                          _loadData();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _filterMonth = month;
                            _filterYear = year;
                            _filterAccountId = accountId;
                            _filterCardId = cardId;
                            _filterCategoryId = categoryId;
                            _filterMerchantId = merchantId;
                            _filterType = type;
                            _filterNature = nature;
                            _filterSort = sort;
                          });
                          _loadData();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Small toggle button pair for ascending/descending sort.
  Widget _sortChip({
    required String label,
    required String ascValue,
    required String descValue,
    required String? current,
    required ValueChanged<String?> onSelect,
  }) {
    final isAsc = current == ascValue;
    final isDesc = current == descValue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        _sortBtn(
          icon: Icons.arrow_upward_rounded,
          active: isAsc,
          onTap: () => onSelect(isAsc ? null : ascValue),
        ),
        _sortBtn(
          icon: Icons.arrow_downward_rounded,
          active: isDesc,
          onTap: () => onSelect(isDesc ? null : descValue),
        ),
      ],
    );
  }

  Widget _sortBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  // ── Delete bottom sheet ───────────────────────────────────────────────────
  void _showDeleteSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: AppColors.expense),
                    SizedBox(width: 8),
                    Text('Bulk Delete',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.date_range_rounded),
                title: const Text('Delete by Date Range'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteByDateRangeFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_rounded),
                title: const Text('Delete by Category'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteByCategoryFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_rounded),
                title: const Text('Delete by Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteByAccountFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card_rounded),
                title: const Text('Delete by Card'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteByCardFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
                title: const Text('Delete All Transactions', style: TextStyle(color: AppColors.expense)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAllFlow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                title: const Text('Hard Reload', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showHardReloadDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(String message, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await action();
  }

  void _deleteByDateRangeFlow() async {
    DateTime? start;
    DateTime? end;

    Future<DateTime?> pickDate(String label) => showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime.now(),
          helpText: label,
        );

    start = await pickDate('Select start date');
    if (start == null || !mounted) return;
    end = await pickDate('Select end date');
    if (end == null || !mounted) return;

    final fmt = DateFormat('yyyy-MM-dd');
    final s = fmt.format(start);
    final e = fmt.format(end);

    await _confirm(
      'Delete all transactions from $s to $e?',
      () async {
        final repo = ref.read(transactionRepositoryProvider);
        final count = await repo.deleteByDateRange(s, e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted $count transaction(s).')));
          _loadData();
        }
      },
    );
  }

  void _deleteByCategoryFlow() async {
    final categories = _categoryMap.values.toList();
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No categories found.')));
      return;
    }
    Category? selected;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Select Category'),
          content: DropdownButtonFormField<Category>(
            isExpanded: true,
            hint: const Text('Category'),
            items: categories
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c.categoryName)))
                .toList(),
            onChanged: (v) => set(() => selected = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null || !mounted) return;
    await _confirm(
      'Delete all transactions in "${selected!.categoryName}"?',
      () async {
        final repo = ref.read(transactionRepositoryProvider);
        final count = await repo.deleteByCategoryId(selected!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted $count transaction(s).')));
          _loadData();
        }
      },
    );
  }

  void _deleteByAccountFlow() async {
    final accounts = _accountMap.values.toList();
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No accounts found.')));
      return;
    }
    int? selectedId;
    String? selectedName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Select Account'),
          content: DropdownButtonFormField<int>(
            isExpanded: true,
            hint: const Text('Account'),
            items: accounts
                .map((a) => DropdownMenuItem(
                    value: a.id, child: Text(a.accountName)))
                .toList(),
            onChanged: (v) => set(() {
              selectedId = v;
              selectedName = accounts.firstWhere((a) => a.id == v).accountName;
            }),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: selectedId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selectedId == null || !mounted) return;
    await _confirm(
      'Delete all transactions for account "$selectedName"?',
      () async {
        final repo = ref.read(transactionRepositoryProvider);
        final count = await repo.deleteByAccountId(selectedId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted $count transaction(s).')));
          _loadData();
        }
      },
    );
  }

  void _deleteByCardFlow() async {
    final cards = _cardMap.values.toList();
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cards found.')));
      return;
    }
    int? selectedId;
    String? selectedName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Select Card'),
          content: DropdownButtonFormField<int>(
            isExpanded: true,
            hint: const Text('Card'),
            items: cards
                .map((c) => DropdownMenuItem(
                    value: c.id, child: Text(c.cardName)))
                .toList(),
            onChanged: (v) => set(() {
              selectedId = v;
              selectedName = cards.firstWhere((c) => c.id == v).cardName;
            }),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: selectedId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selectedId == null || !mounted) return;
    await _confirm(
      'Delete all transactions for card "$selectedName"?',
      () async {
        final repo = ref.read(transactionRepositoryProvider);
        final count = await repo.deleteByCardId(selectedId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted $count transaction(s).')));
          _loadData();
        }
      },
    );
  }

  void _deleteAllFlow() async {
    await _confirm(
      'Are you sure you want to delete ALL transactions? This cannot be undone.',
      () async {
        final repo = ref.read(transactionRepositoryProvider);
        final count = await repo.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted $count transaction(s).')));
          _loadData();
        }
      },
    );
  }

  Future<void> _openAddTransaction() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (added == true) await _loadData();
  }

  Future<void> _openUploadStatement() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UploadStatementScreen()),
    );
    if (added == true) await _loadData();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.navIndicator,
                  child: Icon(Icons.edit_rounded, color: AppColors.primary),
                ),
                title: const Text('Manual Entry',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Add a single transaction manually'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddTransaction();
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.navIndicator,
                  child: Icon(Icons.upload_file_rounded, color: AppColors.primary),
                ),
                title: const Text('Upload Statement',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Import from CSV / XLSX bank statement'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openUploadStatement();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSingle(Transaction txn) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Delete transaction of ₹${txn.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(transactionRepositoryProvider).deleteTransaction(txn.id!);
      await _loadData();
    }
  }

  Widget _buildList(
    List<Transaction> items, {
    required bool isLabeled,
    bool isAllTab = false,
    bool isLabeledTab = false,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAllTab
                          ? Icons.receipt_long_rounded
                          : (isLabeled
                              ? Icons.check_circle_outline_rounded
                              : Icons.label_off_outlined),
                      size: 56,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAllTab
                          ? 'No transactions found.'
                          : (isLabeled
                              ? 'No labeled transactions yet.'
                              : 'All transactions are labeled!'),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80, top: 4),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildTile(
          items[i],
          isLabeled: isLabeled,
          isAllTab: isAllTab,
          isLabeledTab: isLabeledTab,
        ),
      ),
    );
  }

  Widget _buildTile(
    Transaction txn, {
    required bool isLabeled,
    bool isAllTab = false,
    bool isLabeledTab = false,
  }) {
    final cat = txn.categoryId != null ? _categoryMap[txn.categoryId] : null;
    final sub = txn.subcategoryId != null
        ? _subCategoryMap[txn.subcategoryId]
        : null;
    final merchant = txn.merchantId != null
        ? _merchantMap[txn.merchantId]
        : null;
    final account = txn.accountId != null ? _accountMap[txn.accountId] : null;
    final card = txn.cardId != null ? _cardMap[txn.cardId] : null;
    final method = txn.paymentMethodId != null
        ? _paymentMethodMap[txn.paymentMethodId]
        : null;
    final source = txn.expenseSourceId != null
        ? _expenseSourceMap[txn.expenseSourceId]
        : null;
    final purpose = txn.purposeId != null ? _purposeMap[txn.purposeId] : null;

    final isDebit = txn.transactionType == 'DEBIT';
    final amountColor = isDebit ? AppColors.expense : AppColors.income;
    final formatter = NumberFormat('#,##0.00', 'en_IN');

    // Build a subtitle from available label data
    final labelParts = <String>[
      if (cat != null) cat.categoryName,
      if (sub != null) sub.subcategoryName,
      if (merchant != null) merchant.merchantName,
    ];
    final metaParts = <String>[
      txn.transactionDate,
      if (account != null) account.accountName,
      if (card != null) card.cardName,
      if (method != null) method.paymentMethodName,
      if (source != null) source.expenseSourceName,
      if (purpose != null) purpose.expenseFor,
    ];

    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLabelDialog(txn, isLabeledTab: isLabeledTab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: cat != null
                      ? ColorHelper.fromHex(
                          cat.iconColor,
                        ).withValues(alpha: 0.15)
                      : (txn.nature == 'TRANSFERS'
                          ? (isDebit ? AppColors.expense : AppColors.income)
                              .withValues(alpha: 0.15)
                          : AppColors.surfaceContainer),
                  child: cat != null
                      ? Icon(
                          IconHelper.getIcon(cat.icon),
                          color: ColorHelper.fromHex(cat.iconColor),
                        )
                      : (txn.nature == 'TRANSFERS'
                          ? Icon(
                              Icons.swap_horiz_rounded,
                              color: isDebit ? AppColors.expense : AppColors.income,
                            )
                          : Icon(
                              isDebit
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: isDebit ? AppColors.expense : AppColors.income,
                            )),
                ),
              ),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.description ?? txn.transactionType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (labelParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          labelParts.join(' › '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        metaParts.join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount + controls
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}₹${formatter.format(txn.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isAllTab)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.expense.withValues(alpha: 0.7),
                      ),
                      onPressed: () => _confirmDeleteSingle(txn),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    )
                  else
                    Icon(
                      isLabeled
                          ? Icons.label_rounded
                          : Icons.label_outline_rounded,
                      size: 16,
                      color: isLabeled ? AppColors.primary : AppColors.textMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHardReloadDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'RELOAD FROM DATE',
    );
    if (picked == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            SizedBox(width: 8),
            Text('Hard Reload'),
          ],
        ),
        content: Text(
          'This will DELETE all existing transactions from ${DateFormat('yyyy-MM-dd').format(picked)} onwards and re-scan your SMS inbox. '
          'Manual labels and custom categorizations for this period will be LOST.\n\nProceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hard Reload'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        _isSyncing = true;
        _syncTotal = 0;
        _syncCurrent = 0;
      });

      final container = ProviderScope.containerOf(context);
      await SmsListenerService.hardReloadSync(
        container,
        picked,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _syncCurrent = current;
              _syncTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isSyncing = false);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hard reload completed successfully.')),
        );
      }
    }
  }

  Widget _buildSyncProgressOverlay() {
    double progress = _syncTotal > 0 ? _syncCurrent / _syncTotal : 0.0;
    return Container(
      color: Colors.black54,
      child: Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Hard Reloading...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Deleting existing records and re-syncing SMS',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (_syncTotal > 0) ...[
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('$_syncCurrent / $_syncTotal (${(progress * 100).round()}%)'),
                ] else
                  const Text('Initializing...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
