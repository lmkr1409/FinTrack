import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/category.dart';
import '../../../models/expense_purpose.dart';
import '../../../models/investment_goal.dart';
import '../../../models/merchant.dart';
import '../../../models/sub_category.dart';
import '../../../services/analytics_service.dart';
import '../../../services/providers.dart';
import '../../../widgets/glass_card.dart';

class GoalTab extends ConsumerStatefulWidget {
  const GoalTab({super.key});

  @override
  ConsumerState<GoalTab> createState() => _GoalTabState();
}

class _GoalTabState extends ConsumerState<GoalTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;

  List<InvestmentGoal> _goals = [];
  List<Category> _investmentCategories = [];
  List<SubCategory> _allSubCategories = [];
  List<ExpensePurpose> _allPurposes = [];
  List<Merchant> _merchants = [];

  // progress cache (key: goalId, value: savedAmount)
  final Map<int, double> _progressCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final goalRepo = ref.read(investmentGoalRepositoryProvider);
    final catRepo = ref.read(categoryRepositoryProvider);
    final subCatRepo = ref.read(subCategoryRepositoryProvider);
    final purposeRepo = ref.read(expensePurposeRepositoryProvider);

    final goals = await goalRepo.getAllGoalsWithMetadata();
    final allCats = await catRepo.getAllSorted();
    final invCats = allCats.where((c) => c.categoryType == 'INVESTMENTS').toList();
    final allSubs = await subCatRepo.getAllSorted();
    final allPurps = await purposeRepo.getAllSorted();
    final allMerchants = await ref.read(merchantRepositoryProvider).getAllSorted();

    // Fetch progress for each goal up to NOW
    final now = DateTime.now();
    final progressMap = <int, double>{};
    final progressList = await _analytics.getGoalProgress(now.month, now.year);
    for (var p in progressList) {
      progressMap[p['goal_id'] as int] = (p['saved_amount'] as num).toDouble();
    }

    setState(() {
      _goals = goals;
      _investmentCategories = invCats;
      _allSubCategories = allSubs;
      _allPurposes = allPurps;
      _merchants = allMerchants;
      _progressCache.clear();
      _progressCache.addAll(progressMap);
      _loading = false;
    });
  }

  Future<void> _showGoalDialog({InvestmentGoal? editGoal}) async {
    final nameCtrl = TextEditingController(text: editGoal?.goalName ?? '');
    final amountCtrl = TextEditingController(text: (editGoal != null && editGoal.targetAmount > 0) ? editGoal.targetAmount.toStringAsFixed(0) : '');
    
    int? selectedCategory = editGoal?.categoryId;
    int? selectedSubcategory = editGoal?.subcategoryId;
    int? selectedPurpose = editGoal?.purposeId;
    int? selectedMerchant = editGoal?.merchantId;

    if (_investmentCategories.isNotEmpty && selectedCategory == null) {
      selectedCategory = _investmentCategories.first.id;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Filter subcategories based on the currently selected category
          final matchingSubs = _allSubCategories.where((s) => s.categoryId == selectedCategory).toList();
          
          // Ensure selected subcategory is valid for the current category
          if (selectedSubcategory != null && !matchingSubs.any((s) => s.id == selectedSubcategory)) {
            selectedSubcategory = null;
          }

          return AlertDialog(
            title: Text(editGoal == null ? 'Add Investment Goal' : 'Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Goal Name', border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Target Amount (₹)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Investment Category', border: OutlineInputBorder()),
                    items: _investmentCategories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.categoryName));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // SubCategory Dropdown (Optional)
                  DropdownButtonFormField<int?>(
                    value: selectedSubcategory,
                    decoration: const InputDecoration(labelText: 'SubCategory (Optional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- None --')),
                      ...matchingSubs.map((s) {
                        return DropdownMenuItem(value: s.id, child: Text(s.subcategoryName));
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedSubcategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Purpose Dropdown (Optional)
                  DropdownButtonFormField<int?>(
                    value: selectedPurpose,
                    decoration: const InputDecoration(labelText: 'Purpose (Optional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- None --')),
                      ..._allPurposes.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text(p.expenseFor));
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedPurpose = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Merchant Dropdown (New)
                  DropdownButtonFormField<int?>(
                    value: selectedMerchant,
                    decoration: const InputDecoration(labelText: 'Investment Platform (Recommended)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- None --')),
                      ..._merchants.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text(m.merchantName));
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedMerchant = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  if (double.tryParse(amountCtrl.text) == null || double.parse(amountCtrl.text) <= 0) return;
                  if (selectedCategory == null) return;
                  Navigator.pop(ctx, true);
                },
                child: Text(editGoal == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final targetAmount = double.parse(amountCtrl.text);
      final repo = ref.read(investmentGoalRepositoryProvider);

      if (editGoal != null) {
        await repo.updateGoal(editGoal.copyWith(
          goalName: nameCtrl.text.trim(),
          targetAmount: targetAmount,
          categoryId: selectedCategory,
          subcategoryId: selectedSubcategory,
          purposeId: selectedPurpose,
          merchantId: selectedMerchant,
        ));
      } else {
        await repo.insertGoal(InvestmentGoal(
          goalName: nameCtrl.text.trim(),
          targetAmount: targetAmount,
          categoryId: selectedCategory!,
          subcategoryId: selectedSubcategory,
          purposeId: selectedPurpose,
          merchantId: selectedMerchant,
        ));
      }
      _loadData();
    }
  }

  void _confirmDeleteGoal(InvestmentGoal goal) async {
    final savedInfo = _progressCache[goal.id] ?? 0.0;
    if (savedInfo < goal.targetAmount && goal.targetAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal cannot be deleted until it is fully funded.'),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.goalName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete')
          ),
        ],
      )
    );

    if (confirmed == true) {
      await ref.read(investmentGoalRepositoryProvider).deleteGoal(goal.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_investmentCategories.isEmpty) {
      return const Center(child: Text('No investment categories available.', style: TextStyle(color: Colors.white70)));
    }

    return Scaffold(
      body: _goals.isEmpty
          ? const Center(child: Text('No custom investment goals defined.', style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 4),
              itemCount: _goals.length,
              itemBuilder: (context, i) {
                final goal = _goals[i];
                final subName = _allSubCategories.where((s) => s.id == goal.subcategoryId).firstOrNull?.subcategoryName;
                final purposeName = _allPurposes.where((p) => p.id == goal.purposeId).firstOrNull?.expenseFor;
                
                final savedAmt = _progressCache[goal.id] ?? 0.0;
                final progressRaw = goal.targetAmount > 0 ? (savedAmt / goal.targetAmount) : 0.0;
                final progress = progressRaw.clamp(0.0, 1.0);

                final String mappings = [
                  if (goal.merchantName != null) goal.merchantName!,
                  goal.categoryName ?? 'Unknown',
                  if (subName != null) subName,
                  if (purposeName != null) purposeName,
                ].join(' > ');

                return GlassCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: ColorHelper.fromHex(goal.iconColor ?? '#FF9800').withValues(alpha: 0.2),
                              child: Icon(IconHelper.getIcon(goal.icon ?? 'star'), color: ColorHelper.fromHex(goal.iconColor ?? '#FF9800'), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(goal.goalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                Text(mappings, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                              ],
                            )),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                              onPressed: () => _showGoalDialog(editGoal: goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                              onPressed: () => _confirmDeleteGoal(goal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress: ${(progressRaw * 100).toStringAsFixed(1)}%', style: TextStyle(color: (progressRaw >= 1) ? AppColors.income : Colors.amberAccent, fontWeight: FontWeight.bold)),
                            Text('₹${savedAmt.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            color: (progressRaw >= 1) ? AppColors.income : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
