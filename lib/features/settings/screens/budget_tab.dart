import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  bool _isSaving = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  
  // Local state for the text fields. Key: Category ID, Value: Input string
  final Map<int, String> _budgetInputs = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final budgets = await ref.read(budgetRepositoryProvider).getAllSorted();
    final categories = await ref.read(categoryRepositoryProvider).getAllSorted();
    
    _populateLocalInputs(budgets, _selectedMonth.month, _selectedMonth.year);
    
    setState(() {
      _budgets = budgets;
      _categories = categories;
      _loading = false;
    });
  }

  void _populateLocalInputs(List<Budget> budgets, int month, int year) {
    _budgetInputs.clear();
    for (final b in budgets) {
      if (b.categoryId != null && b.budgetFrequency == 'MONTHLY' && b.month == month && b.year == year) {
        _budgetInputs[b.categoryId!] = b.budgetAmount > 0 ? b.budgetAmount.toStringAsFixed(0) : '';
      }
    }
  }

  Budget? _getBudgetForCategory(int categoryId) {
    return _budgets.where((b) => 
      b.categoryId == categoryId && 
      b.budgetFrequency == 'MONTHLY' &&
      b.month == _selectedMonth.month && 
      b.year == _selectedMonth.year
    ).firstOrNull;
  }

  Future<void> _saveAllBudgets() async {
    setState(() => _isSaving = true);
    final repo = ref.read(budgetRepositoryProvider);

    for (final cat in _categories) {
      final inputVal = _budgetInputs[cat.id!] ?? '';
      final amount = double.tryParse(inputVal) ?? 0.0;
      final existingBudget = _getBudgetForCategory(cat.id!);

      if (amount <= 0) {
        if (existingBudget != null && existingBudget.id != null) {
          await repo.deleteBudget(existingBudget.id!);
        }
      } else {
        if (existingBudget != null) {
          await repo.updateBudget(existingBudget.copyWith(budgetAmount: amount));
        } else {
          await repo.insertBudget(Budget(
            categoryId: cat.id!,
            budgetAmount: amount,
            budgetFrequency: 'MONTHLY',
            month: _selectedMonth.month,
            year: _selectedMonth.year,
          ));
        }
      }
    }
    await _loadData();
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Budgets saved for ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),
        backgroundColor: Colors.green,
      ));
    }
  }
  
  void _copyPreviousMonth() {
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _populateLocalInputs(_budgets, prevMonth.month, prevMonth.year);
    setState(() {}); // Re-render the fields with copied values
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Values copied from previous month. Click Save to persist.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          MonthSwiper(
            currentMonth: _selectedMonth,
            onMonthChanged: (newMonth) {
              setState(() {
                _selectedMonth = newMonth;
                _populateLocalInputs(_budgets, _selectedMonth.month, _selectedMonth.year);
              });
            },
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                tooltip: 'Copy Previous Month',
                onPressed: _loading || _isSaving ? null : _copyPreviousMonth,
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                tooltip: 'Save Budgets',
                onPressed: _loading || _isSaving ? null : _saveAllBudgets,
              ),
            ],
            child: _buildCategoriesList(cs),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
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
        if (cat.id == null) return const SizedBox.shrink();
        
        final existingBudget = _getBudgetForCategory(cat.id!);
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
                    key: ValueKey('${_selectedMonth.year}_${_selectedMonth.month}_${cat.id!}'),
                    initialValue: _budgetInputs[cat.id!] ?? '',
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
                    onChanged: (val) {
                      _budgetInputs[cat.id!] = val;
                      // Show an indicator on the UI if it differs from DB
                      final dbVal = existingBudget?.budgetAmount ?? 0.0;
                      final inputNum = double.tryParse(val) ?? 0.0;
                      if (dbVal != inputNum) {
                          // The 'Save' button already handles persistence, we don't auto-save anymore.
                          // Could change input border color if modified to show "unsaved" state if needed.
                      }
                    },
                    textInputAction: TextInputAction.next,
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
