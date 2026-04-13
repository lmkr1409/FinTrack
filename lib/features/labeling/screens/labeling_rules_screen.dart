import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/account.dart';
import '../../../models/card.dart' as model;
import '../../../models/category.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/merchant.dart';
import '../../../models/payment_method.dart';
import '../../../models/sub_category.dart';
import '../../../models/merchant_rule.dart';
import '../../../models/transaction_rule.dart';
import '../../../services/providers.dart';
import '../../../services/labeling_rules_service.dart';
import 'merchant_rule_dialog.dart';
import 'transaction_rule_dialog.dart';

class LabelingRulesScreen extends ConsumerStatefulWidget {
  const LabelingRulesScreen({super.key});

  @override
  ConsumerState<LabelingRulesScreen> createState() => _LabelingRulesScreenState();
}

enum _RulesSegment { transactions, merchants }
enum _MerchantNature { transactions, transfers, investments, common }

class _LabelingRulesScreenState extends ConsumerState<LabelingRulesScreen> {
  _RulesSegment _segment = _RulesSegment.transactions;
  List<MerchantRule> _mRules = [];
  List<TransactionRule> _tRules = [];

  Map<int, Category> _categoryMap = {};
  Map<int, SubCategory> _subCategoryMap = {};
  Map<int, Merchant> _merchantMap = {};
  Map<int, PaymentMethod> _paymentMethodMap = {};
  Map<int, ExpensePurpose> _purposeMap = {};
  Map<int, Account> _accountMap = {};
  Map<int, model.Card> _cardMap = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules({bool showLoading = false}) async {
    if (showLoading) setState(() => _isLoading = true);
    final mRepo = ref.read(merchantRuleRepositoryProvider);
    final mRules = await mRepo.getAllSorted();
    
    final tRepo = ref.read(transactionRuleRepositoryProvider);
    final tRules = await tRepo.getAllSorted();

    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final subCats = await ref.read(subCategoryRepositoryProvider).getAll();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();

    if (!mounted) return;
    setState(() {
      _mRules = mRules;
      _tRules = tRules;
      _categoryMap = {for (final c in categories) c.id!: c};
      _subCategoryMap = {for (final s in subCats) s.id!: s};
      _merchantMap = {for (final m in merchants) m.id!: m};
      _paymentMethodMap = {for (final p in methods) p.id!: p};
      _purposeMap = {for (final p in purposes) p.id!: p};
      _accountMap = {for (final a in accounts) a.id!: a};
      _cardMap = {for (final c in cards) c.id!: c};
      _isLoading = false;
    });
  }

  Future<void> _deleteMerchantRule(int id) async {
    await ref.read(merchantRuleRepositoryProvider).delete(id);
    _loadRules();
  }

  Future<void> _deleteTransactionRule(int id) async {
    await ref.read(transactionRuleRepositoryProvider).delete(id);
    _loadRules();
  }

  void _openMerchantDialog([MerchantRule? rule]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => MerchantRuleDialog(
        rule: rule,
        onSaved: _loadRules,
      ),
    );
  }

  void _openTransactionDialog(String ruleType, [TransactionRule? rule]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => TransactionRuleDialog(
        ruleType: ruleType,
        rule: rule,
        onSaved: _loadRules,
      ),
    );
  }

  Widget _buildGroupCard(String groupName, List<TransactionRule> groupRules, String ruleType) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
               groupName,
               style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
             ),
             const SizedBox(height: 8),
             if (groupRules.isEmpty)
               const Text('No keywords mapped yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
             else
               Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: groupRules.map((r) => InputChip(
                   label: Text(r.pattern),
                   onDeleted: () => _deleteTransactionRule(r.id!),
                   onPressed: () => _openTransactionDialog(ruleType, r),
                   deleteIconColor: AppColors.expense,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 )).toList(),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleListTile(TransactionRule rule, String ruleType) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ListTile(
        title: Text(rule.pattern, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
          'Extracts Amount',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.expense),
          onPressed: () => _deleteTransactionRule(rule.id!),
        ),
        onTap: () => _openTransactionDialog(ruleType, rule),
      ),
    );
  }

  Widget _buildTransactionSection(String title, String ruleType, IconData icon) {
    final rules = _tRules.where((r) => r.ruleType == ruleType).toList();
    
    Widget content;
    
    if (ruleType == 'AMOUNT_REGEX') {
      if (rules.isEmpty) {
        content = const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No regex rules defined yet.', style: TextStyle(color: AppColors.textMuted)),
        );
      } else {
        content = Column(
          children: rules.map((r) => _buildRuleListTile(r, ruleType)).toList(),
        );
      }
    } else if (ruleType == 'TRANSACTION_TYPE') {
      final types = ['DEBIT', 'CREDIT', 'TRANSFER'];
      content = Column(
        children: types.map((type) {
          final groupRules = rules.where((r) => r.mappedType == type).toList();
          return _buildGroupCard(type, groupRules, ruleType);
        }).toList(),
      );
    } else if (ruleType == 'PAYMENT_METHOD') {
      if (_paymentMethodMap.isEmpty) {
        content = const Padding(padding: EdgeInsets.all(16), child: Text('No Payment Methods exist yet.', style: TextStyle(color: AppColors.textMuted)));
      } else {
        content = Column(
          children: _paymentMethodMap.values.map((pm) {
            final groupRules = rules.where((r) => r.paymentMethodId == pm.id).toList();
            return _buildGroupCard(pm.paymentMethodName, groupRules, ruleType);
          }).toList(),
        );
      }
    } else if (ruleType == 'BANK_SENDER') {
      if (rules.isEmpty) {
        content = const Padding(padding: EdgeInsets.all(16), child: Text('No Bank Senders exist yet.', style: TextStyle(color: AppColors.textMuted)));
      } else {
        content = _buildGroupCard('Approved Bank Senders', rules, ruleType);
      }
    } else if (ruleType == 'ACCOUNT') {
      if (_accountMap.isEmpty) {
        content = const Padding(padding: EdgeInsets.all(16), child: Text('No Accounts exist yet.', style: TextStyle(color: AppColors.textMuted)));
      } else {
        content = Column(
          children: _accountMap.values.map((acct) {
            final groupRules = rules.where((r) => r.accountId == acct.id).toList();
            return _buildGroupCard(acct.accountName, groupRules, ruleType);
          }).toList(),
        );
      }
    } else if (ruleType == 'CARD') {
      if (_cardMap.isEmpty) {
        content = const Padding(padding: EdgeInsets.all(16), child: Text('No Cards exist yet.', style: TextStyle(color: AppColors.textMuted)));
      } else {
        content = Column(
          children: _cardMap.values.map((card) {
            final groupRules = rules.where((r) => r.cardId == card.id).toList();
            return _buildGroupCard(card.cardName, groupRules, ruleType);
          }).toList(),
        );
      }
    } else {
      content = const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [content, const SizedBox(height: 12)],
      ),
    );
  }

  Widget _buildMerchantKeywordCard(MerchantRule rule) {
    final subtitle = [
      if (rule.categoryId != null && _categoryMap.containsKey(rule.categoryId)) _categoryMap[rule.categoryId]!.categoryName,
      if (rule.subcategoryId != null && _subCategoryMap.containsKey(rule.subcategoryId)) _subCategoryMap[rule.subcategoryId]!.subcategoryName,
      if (rule.purposeId != null && _purposeMap.containsKey(rule.purposeId)) _purposeMap[rule.purposeId]!.expenseFor,
    ].where((e) => e.isNotEmpty).join('  ›  ');

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
        title: Text(rule.keyword, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () => _openMerchantDialog(rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteMerchantRule(rule.id!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNatureSection(String title, _MerchantNature nature, IconData icon, Map<int?, List<MerchantRule>> merchants) {
    if (merchants.isEmpty) return const SizedBox.shrink();

    // Sort merchants alphabetically; "Unassigned" goes last
    final sortedKeys = merchants.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = _merchantMap[a]?.merchantName ?? '';
        final nameB = _merchantMap[b]?.merchantName ?? '';
        return nameA.compareTo(nameB);
      });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: nature == _MerchantNature.transactions, // Expand transactions by default if present
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: sortedKeys.map((merchantId) {
          final rules = merchants[merchantId]!;
          final merchantName = merchantId != null && _merchantMap.containsKey(merchantId)
              ? _merchantMap[merchantId]!.merchantName
              : 'Unassigned';

          return Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.store_rounded, color: AppColors.primary, size: 20),
                title: Text(merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  '${rules.length} keyword${rules.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                initiallyExpanded: false,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: rules.map(_buildMerchantKeywordCard).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMerchantTab() {
    if (_mRules.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRules,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 100),
            Center(child: Text('No merchant rules defined yet.')),
          ],
        ),
      );
    }

    // 1. Group rules by merchantId first
    final Map<int?, List<MerchantRule>> merchantGroups = {};
    for (final rule in _mRules) {
      merchantGroups.putIfAbsent(rule.merchantId, () => []).add(rule);
    }

    // 2. Classify each merchant into a nature
    final Map<_MerchantNature, Map<int?, List<MerchantRule>>> natureGroups = {
      _MerchantNature.transactions: {},
      _MerchantNature.transfers: {},
      _MerchantNature.investments: {},
      _MerchantNature.common: {},
    };

    merchantGroups.forEach((merchantId, rules) {
      final natures = rules.map((r) {
        if (r.categoryId == null) return 'NONE';
        return _categoryMap[r.categoryId]?.categoryType ?? 'NONE';
      }).toSet();

      _MerchantNature targetNature;
      
      // If merchant has rules in multiple natures, move to Common
      if (natures.length > 1) {
        targetNature = _MerchantNature.common;
      } else if (natures.isEmpty || natures.first == 'NONE') {
        targetNature = _MerchantNature.common;
      } else {
        final natureStr = natures.first;
        if (natureStr == 'TRANSACTIONS') {
          targetNature = _MerchantNature.transactions;
        } else if (natureStr == 'TRANSFERS') {
          targetNature = _MerchantNature.transfers;
        } else if (natureStr == 'INVESTMENTS') {
          targetNature = _MerchantNature.investments;
        } else {
          targetNature = _MerchantNature.common;
        }
      }

      natureGroups[targetNature]![merchantId] = rules;
    });

    return RefreshIndicator(
      onRefresh: _loadRules,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
        children: [
          _buildNatureSection('Transactions', _MerchantNature.transactions, Icons.receipt_long_rounded, natureGroups[_MerchantNature.transactions]!),
          _buildNatureSection('Transfers', _MerchantNature.transfers, Icons.swap_horiz_rounded, natureGroups[_MerchantNature.transfers]!),
          _buildNatureSection('Investments', _MerchantNature.investments, Icons.trending_up_rounded, natureGroups[_MerchantNature.investments]!),
          _buildNatureSection('Common', _MerchantNature.common, Icons.category_rounded, natureGroups[_MerchantNature.common]!),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<_RulesSegment>(
                    segments: const [
                      ButtonSegment(value: _RulesSegment.transactions, label: Text('Transactions'), icon: Icon(Icons.receipt_long_rounded, size: 18)),
                      ButtonSegment(value: _RulesSegment.merchants, label: Text('Merchants'), icon: Icon(Icons.store_rounded, size: 18)),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (s) => setState(() => _segment = s.first),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  tooltip: _segment == _RulesSegment.transactions ? 'Apply Transaction Rules' : 'Apply Merchant Rules',
                  onPressed: () => LabelingRulesService.promptAndApplyRules(
                    context, 
                    ref, 
                    applyTransactions: _segment == _RulesSegment.transactions,
                    applyMerchants: _segment == _RulesSegment.merchants,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _segment == _RulesSegment.transactions
                ? RefreshIndicator(
                    onRefresh: _loadRules,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        _buildTransactionSection('Amount Regexes', 'AMOUNT_REGEX', Icons.data_object),
                        _buildTransactionSection('Transaction Types', 'TRANSACTION_TYPE', Icons.swap_horiz),
                        _buildTransactionSection('Payment Methods', 'PAYMENT_METHOD', Icons.payment),
                        _buildTransactionSection('Bank Senders', 'BANK_SENDER', Icons.business),
                        _buildTransactionSection('Accounts', 'ACCOUNT', Icons.account_balance),
                        _buildTransactionSection('Cards', 'CARD', Icons.credit_card),
                      ],
                    ),
                  )
                : _buildMerchantTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_segment == _RulesSegment.transactions) {
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Add Transaction Rule...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(title: const Text('Amount Regex'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('AMOUNT_REGEX'); }),
                    ListTile(title: const Text('Transaction Type'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('TRANSACTION_TYPE'); }),
                    ListTile(title: const Text('Payment Method'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('PAYMENT_METHOD'); }),
                    ListTile(title: const Text('Bank Sender'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('BANK_SENDER'); }),
                    ListTile(title: const Text('Account'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('ACCOUNT'); }),
                    ListTile(title: const Text('Card'), onTap: () { Navigator.pop(dialogCtx); _openTransactionDialog('CARD'); }),
                  ],
                ),
              )
            );
          } else {
            _openMerchantDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }
}
