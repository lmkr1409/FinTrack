import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../../../services/providers.dart';
import '../../../widgets/month_swiper.dart';
import '../../../widgets/glass_card.dart';

class BudgetTab extends ConsumerStatefulWidget {
  const BudgetTab({super.key});

  @override
  ConsumerState<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends ConsumerState<BudgetTab> {
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _loading = true;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final budgets = await ref.read(budgetRepositoryProvider).getAllSorted();
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    setState(() {
      _budgets = budgets;
      _categories = categories;
      _loading = false;
    });
  }

  Budget? _getBudgetForCategory(int categoryId) {
    return _budgets.where((b) => 
      b.categoryId == categoryId && 
      b.budgetFrequency == 'MONTHLY' &&
      b.month == _selectedMonth.month && 
      b.year == _selectedMonth.year
    ).firstOrNull;
  }

  Future<void> _saveBudget(int categoryId, String value, Budget? existingBudget) async {
    final amount = double.tryParse(value) ?? 0.0;
    final repo = ref.read(budgetRepositoryProvider);

    if (amount <= 0) {
      if (existingBudget != null && existingBudget.id != null) {
        // Amount is 0 or invalid, delete existing budget for this month
        await repo.deleteBudget(existingBudget.id!);
      }
    } else {
      if (existingBudget != null) {
        // Update
        await repo.updateBudget(existingBudget.copyWith(budgetAmount: amount));
      } else {
        // Insert
        await repo.insertBudget(Budget(
          categoryId: categoryId,
          budgetAmount: amount,
          budgetFrequency: 'MONTHLY',
          month: _selectedMonth.month,
          year: _selectedMonth.year,
        ));
      }
    }
    // Refresh to reflect actual saved state without blocking UI unnecessarily
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: MonthSwiper(
        currentMonth: _selectedMonth,
        onMonthChanged: (newMonth) {
          setState(() => _selectedMonth = newMonth);
        },
        child: _buildCategoriesList(cs),
      ),
    );
  }

  Widget _buildCategoriesList(ColorScheme cs) {
    if (_categories.isEmpty) {
      return Center(child: Text('No categories available.', style: TextStyle(color: cs.onSurfaceVariant)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        final existingBudget = _getBudgetForCategory(cat.id!);
        
        final initialNum = existingBudget?.budgetAmount ?? 0.0;
        final initialText = initialNum > 0 ? initialNum.toStringAsFixed(0) : '';

        return GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorHelper.fromHex(cat.iconColor).withValues(alpha: 0.15),
                  child: Icon(IconHelper.getIcon(cat.icon), color: ColorHelper.fromHex(cat.iconColor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: initialText,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onFieldSubmitted: (val) => _saveBudget(cat.id!, val, existingBudget),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
