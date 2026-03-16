import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../../../widgets/glass_card.dart';
import 'label_dialog.dart';

/// Screen with Unlabeled / Labeled tabs for reviewing and labeling transactions.
class LabelScreen extends ConsumerStatefulWidget {
  const LabelScreen({super.key});

  @override
  ConsumerState<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends ConsumerState<LabelScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Transaction> _unlabeled = [];
  List<Transaction> _labeled = [];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final repo = ref.read(transactionRepositoryProvider);
    final unlabeled = await repo.getFiltered(labeled: false);
    final labeled = await repo.getFiltered(labeled: true);

    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final subCats = await ref.read(subCategoryRepositoryProvider).getAll();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final sources = await ref.read(expenseSourceRepositoryProvider).getAllSorted();
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();

    if (!mounted) return;
    setState(() {
      _unlabeled = unlabeled;
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

  void _openLabelDialog(Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LabelDialog(transaction: txn, onSaved: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Unlabeled (${_unlabeled.length})'),
            Tab(text: 'Labeled (${_labeled.length})'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_unlabeled, isLabeled: false),
                _buildList(_labeled, isLabeled: true),
              ],
            ),
    );
  }

  Widget _buildList(List<Transaction> items, {required bool isLabeled}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLabeled ? Icons.check_circle_outline_rounded : Icons.label_off_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              isLabeled ? 'No labeled transactions yet.' : 'All transactions are labeled!',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16, top: 4),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildTile(items[i], isLabeled: isLabeled),
      ),
    );
  }

  Widget _buildTile(Transaction txn, {required bool isLabeled}) {
    final cat = txn.categoryId != null ? _categoryMap[txn.categoryId] : null;
    final sub = txn.subcategoryId != null ? _subCategoryMap[txn.subcategoryId] : null;
    final merchant = txn.merchantId != null ? _merchantMap[txn.merchantId] : null;
    final account = txn.accountId != null ? _accountMap[txn.accountId] : null;
    final card = txn.cardId != null ? _cardMap[txn.cardId] : null;
    final method = txn.paymentMethodId != null ? _paymentMethodMap[txn.paymentMethodId] : null;
    final source = txn.expenseSourceId != null ? _expenseSourceMap[txn.expenseSourceId] : null;
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
        onTap: () => _openLabelDialog(txn),
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
                      ? ColorHelper.fromHex(cat.iconColor).withValues(alpha: 0.15)
                      : AppColors.surfaceContainer,
                  child: Icon(
                    cat != null ? IconHelper.getIcon(cat.icon) : (isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                    size: 18,
                    color: cat != null ? ColorHelper.fromHex(cat.iconColor) : amountColor,
                  ),
                ),
              ),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.description ?? txn.transactionType,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (labelParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(labelParts.join(' › '),
                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(metaParts.join(' • '),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Amount + label button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}₹${formatter.format(txn.amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isLabeled ? Icons.label_rounded : Icons.label_outline_rounded,
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
}
