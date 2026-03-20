import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'labeling_rule_dialog.dart';

class LabelingRulesScreen extends ConsumerStatefulWidget {
  const LabelingRulesScreen({super.key});

  @override
  ConsumerState<LabelingRulesScreen> createState() => _LabelingRulesScreenState();
}

class _LabelingRulesScreenState extends ConsumerState<LabelingRulesScreen> {
  List<LabelingRule> _rules = [];

  Map<int, Category> _categoryMap = {};
  Map<int, SubCategory> _subCategoryMap = {};
  Map<int, Merchant> _merchantMap = {};
  Map<int, PaymentMethod> _paymentMethodMap = {};
  Map<int, ExpenseSource> _expenseSourceMap = {};
  Map<int, ExpensePurpose> _purposeMap = {};
  Map<int, Account> _accountMap = {};
  Map<int, model.Card> _cardMap = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    
    final rulesRepo = ref.read(labelingRuleRepositoryProvider);
    final rules = await rulesRepo.getAllSorted();

    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    final subCats = await ref.read(subCategoryRepositoryProvider).getAll();
    final merchants = await ref.read(merchantRepositoryProvider).getAllSorted();
    final methods = await ref.read(paymentMethodRepositoryProvider).getAllSorted();
    final sources = await ref.read(expenseSourceRepositoryProvider).getAllSorted();
    final purposes = await ref.read(expensePurposeRepositoryProvider).getAllSorted();
    final accounts = await ref.read(accountRepositoryProvider).getAllSorted();
    final cards = await ref.read(cardRepositoryProvider).getAllSorted();

    if (!mounted) return;
    setState(() {
      _rules = rules;
      _categoryMap = {for (final c in categories) c.id!: c};
      _subCategoryMap = {for (final s in subCats) s.id!: s};
      _merchantMap = {for (final m in merchants) m.id!: m};
      _paymentMethodMap = {for (final p in methods) p.id!: p};
      _expenseSourceMap = {for (final s in sources) s.id!: s};
      _purposeMap = {for (final p in purposes) p.id!: p};
      _accountMap = {for (final a in accounts) a.id!: a};
      _cardMap = {for (final c in cards) c.id!: c};
      _isLoading = false;
    });
  }

  Future<void> _deleteRule(int id) async {
    final rulesRepo = ref.read(labelingRuleRepositoryProvider);
    await rulesRepo.delete(id);
    _loadRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRules,
              child: _rules.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No labeling rules defined yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rules.length,
                      itemBuilder: (context, index) {
                        final rule = _rules[index];
                        return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: ListTile(
                        title: Text(
                          rule.keyword,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          [
                            if (rule.transactionType != null) rule.transactionType![0].toUpperCase() + rule.transactionType!.substring(1).toLowerCase(),
                            if (rule.categoryId != null && _categoryMap.containsKey(rule.categoryId)) _categoryMap[rule.categoryId]!.categoryName,
                            if (rule.subcategoryId != null && _subCategoryMap.containsKey(rule.subcategoryId)) _subCategoryMap[rule.subcategoryId]!.subcategoryName,
                            if (rule.merchantId != null && _merchantMap.containsKey(rule.merchantId)) _merchantMap[rule.merchantId]!.merchantName,
                            if (rule.paymentMethodId != null && _paymentMethodMap.containsKey(rule.paymentMethodId)) _paymentMethodMap[rule.paymentMethodId]!.paymentMethodName,
                            if (rule.expenseSourceId != null && _expenseSourceMap.containsKey(rule.expenseSourceId)) _expenseSourceMap[rule.expenseSourceId]!.expenseSourceName,
                            if (rule.purposeId != null && _purposeMap.containsKey(rule.purposeId)) _purposeMap[rule.purposeId]!.expenseFor,
                            if (rule.accountId != null && _accountMap.containsKey(rule.accountId)) _accountMap[rule.accountId]!.accountName,
                            if (rule.cardId != null && _cardMap.containsKey(rule.cardId)) _cardMap[rule.cardId]!.cardName,
                          ].join(', '),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                          onPressed: () => _deleteRule(rule.id!),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => LabelingRuleDialog(
                              rule: rule,
                              onSaved: _loadRules,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => LabelingRuleDialog(
              onSaved: _loadRules,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
