import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../../../services/providers.dart';
import '../../../widgets/month_swiper.dart';
import '../../../widgets/year_swiper.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/budget_total.dart';

class BudgetTab extends ConsumerStatefulWidget {
  const BudgetTab({super.key});

  @override
  ConsumerState<BudgetTab> createState() => _BudgetTabState();
}

enum _BudgetPeriod { monthly, yearly }

class _BudgetTabState extends ConsumerState<BudgetTab> {
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _loading = true;
  bool _isSaving = false;

  _BudgetPeriod _period = _BudgetPeriod.monthly;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedYear = DateTime.now().year;

  double _totalBudgetAmount = 0;
  int? _totalBudgetId;
  
  // Local state for the text fields. Key: Category ID, Value: Input string
  final Map<int, String> _budgetInputs = {};
  final Map<int, String> _annualBudgetInputs = {};
  String _globalBudgetInput = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final budgetRepo = ref.read(budgetRepositoryProvider);
    final totalRepo = ref.read(budgetTotalRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    final budgets = await budgetRepo.getAllSorted();
    final categories = await categoryRepo.getAllSorted();
    
    BudgetTotal? total;
    if (_period == _BudgetPeriod.monthly) {
      total = await totalRepo.getMonthlyTotal(_selectedMonth.month, _selectedMonth.year);
    } else {
      total = await totalRepo.getAnnualTotal(_selectedYear);
    }

    _populateLocalInputs(budgets);
    
    setState(() {
      _budgets = budgets;
      _categories = categories;
      _totalBudgetAmount = total?.budgetAmount ?? 0;
      _totalBudgetId = total?.id;
      _globalBudgetInput = _totalBudgetAmount > 0 ? _totalBudgetAmount.toStringAsFixed(0) : '';
      _loading = false;
    });
  }

  void _populateLocalInputs(List<Budget> budgets) {
    _budgetInputs.clear();
    _annualBudgetInputs.clear();

    for (final b in budgets) {
      if (b.categoryId != null) {
        if (b.budgetFrequency == 'MONTHLY' && b.month == _selectedMonth.month && b.year == _selectedMonth.year) {
          _budgetInputs[b.categoryId!] = b.budgetAmount > 0 ? b.budgetAmount.toStringAsFixed(0) : '';
        } else if (b.budgetFrequency == 'ANNUAL' && b.year == _selectedYear) {
          _annualBudgetInputs[b.categoryId!] = b.budgetAmount > 0 ? b.budgetAmount.toStringAsFixed(0) : '';
        }
      }
    }
  }

  Budget? _getBudgetForCategory(int categoryId, {required String frequency}) {
    if (frequency == 'MONTHLY') {
      return _budgets.where((b) => 
        b.categoryId == categoryId && 
        b.budgetFrequency == 'MONTHLY' &&
        b.month == _selectedMonth.month && 
        b.year == _selectedMonth.year
      ).firstOrNull;
    } else {
      return _budgets.where((b) => 
        b.categoryId == categoryId && 
        b.budgetFrequency == 'ANNUAL' &&
        b.year == _selectedYear
      ).firstOrNull;
    }
  }

  double get _currentPlannedSum {
    double total = 0;
    final isMonthly = _period == _BudgetPeriod.monthly;
    final inputs = isMonthly ? _budgetInputs : _annualBudgetInputs;
    
    for (final cat in _categories.where((c) => c.categoryType == 'EXPENSE')) {
       total += double.tryParse(inputs[cat.id!] ?? '') ?? 0.0;
    }
    return total;
  }

  Future<void> _saveAllBudgets({bool showSnackbar = true}) async {
    final planned = _currentPlannedSum;
    final total = double.tryParse(_globalBudgetInput) ?? 0.0;
    if (total > 0 && planned > total) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sum of categories (₹${planned.toStringAsFixed(0)}) exceeds total budget (₹${total.toStringAsFixed(0)})!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);
    final budgetRepo = ref.read(budgetRepositoryProvider);
    final totalRepo = ref.read(budgetTotalRepositoryProvider);
    final isMonthly = _period == _BudgetPeriod.monthly;

    // 1. Save Total Budget (Global Cap)
    final amountT = double.tryParse(_globalBudgetInput) ?? 0.0;
    if (amountT <= 0) {
      if (_totalBudgetId != null) await totalRepo.deleteTotal(_totalBudgetId!);
    } else {
      if (_totalBudgetId != null) {
        await totalRepo.updateTotal(BudgetTotal(
          id: _totalBudgetId,
          budgetAmount: amountT,
          budgetFrequency: isMonthly ? 'MONTHLY' : 'ANNUAL',
          month: isMonthly ? _selectedMonth.month : null,
          year: isMonthly ? _selectedMonth.year : _selectedYear,
        ));
      } else {
        await totalRepo.insertTotal(BudgetTotal(
          budgetAmount: amountT,
          budgetFrequency: isMonthly ? 'MONTHLY' : 'ANNUAL',
          month: isMonthly ? _selectedMonth.month : null,
          year: isMonthly ? _selectedMonth.year : _selectedYear,
        ));
      }
    }

    // 2. Save Category Budgets
    for (final cat in _categories.where((c) => c.categoryType == 'EXPENSE')) {
      if (isMonthly) {
        final val = _budgetInputs[cat.id!] ?? '';
        final amount = double.tryParse(val) ?? 0.0;
        final existing = _getBudgetForCategory(cat.id!, frequency: 'MONTHLY');

        if (amount <= 0) {
          if (existing != null && existing.id != null) await budgetRepo.deleteBudget(existing.id!);
        } else {
          if (existing != null) {
            await budgetRepo.updateBudget(existing.copyWith(budgetAmount: amount));
          } else {
            await budgetRepo.insertBudget(Budget(
              categoryId: cat.id!,
              budgetAmount: amount,
              budgetFrequency: 'MONTHLY',
              month: _selectedMonth.month,
              year: _selectedMonth.year,
            ));
          }
        }
      } else {
        final val = _annualBudgetInputs[cat.id!] ?? '';
        final amount = double.tryParse(val) ?? 0.0;
        final existing = _getBudgetForCategory(cat.id!, frequency: 'ANNUAL');

        if (amount <= 0) {
          if (existing != null && existing.id != null) await budgetRepo.deleteBudget(existing.id!);
        } else {
          if (existing != null) {
            await budgetRepo.updateBudget(existing.copyWith(budgetAmount: amount));
          } else {
            await budgetRepo.insertBudget(Budget(
              categoryId: cat.id!,
              budgetAmount: amount,
              budgetFrequency: 'ANNUAL',
              year: _selectedYear,
            ));
          }
        }
      }
    }

    await _loadData();
    setState(() => _isSaving = false);
    
    if (mounted && showSnackbar) {
      final periodText = isMonthly ? DateFormat('MMMM yyyy').format(_selectedMonth) : 'Year $_selectedYear';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Budgets saved for $periodText'),
        backgroundColor: Colors.green,
      ));
    }
  }
  
  Future<void> _copyPreviousMonthAndSave() async {
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    bool copiedAny = false;

    // Note: We'd need to fetch actual data from DB for previous month caps if not loaded.
    // For now, mirroring previous behavior where we copy loaded category budgets.
    
    for (final b in _budgets) {
      if (b.categoryId != null && b.budgetFrequency == 'MONTHLY' && b.month == prevMonth.month && b.year == prevMonth.year) {
        if (b.budgetAmount > 0) {
          _budgetInputs[b.categoryId!] = b.budgetAmount.toStringAsFixed(0);
          copiedAny = true;
        }
      }
    }

    if (copiedAny) {
      await _saveAllBudgets(showSnackbar: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Previous month budgets accurately copied and saved!'),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No budgets found in the previous month to copy.'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final planned = _currentPlannedSum;
    final total = double.tryParse(_globalBudgetInput) ?? 0.0;
    final isExceeded = total > 0 && planned > total;

    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_BudgetPeriod>(
              segments: const [
                ButtonSegment(value: _BudgetPeriod.monthly, label: Text('Monthly'), icon: Icon(Icons.calendar_month_rounded, size: 18)),
                ButtonSegment(value: _BudgetPeriod.yearly, label: Text('Yearly'), icon: Icon(Icons.calendar_today_rounded, size: 18)),
              ],
              selected: {_period},
              onSelectionChanged: (s) {
                setState(() {
                  _period = s.first;
                });
                _loadData();
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _period == _BudgetPeriod.monthly 
                 ? MonthSwiper(
                    currentMonth: _selectedMonth,
                    onMonthChanged: (newMonth) {
                      setState(() {
                        _selectedMonth = newMonth;
                      });
                      _loadData(); // Re-populate for new month
                    },
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                        tooltip: 'Copy Previous Month',
                        onPressed: _loading || _isSaving ? null : _copyPreviousMonthAndSave,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        tooltip: 'Save Budgets',
                        onPressed: _loading || _isSaving ? null : _saveAllBudgets,
                      ),
                    ],
                    child: Column(
                      children: [
                        _buildGlobalBudgetCard(cs),
                        Expanded(child: _buildCategoriesList(cs, isExceeded: isExceeded)),
                      ],
                    ),
                  )
                : YearSwiper(
                    currentYear: _selectedYear,
                    onYearChanged: (newYear) {
                      setState(() {
                        _selectedYear = newYear;
                      });
                      _loadData(); // Re-populate for new year
                    },
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        tooltip: 'Save Budgets',
                        onPressed: _loading || _isSaving ? null : _saveAllBudgets,
                      ),
                    ],
                    child: Column(
                      children: [
                        _buildGlobalBudgetCard(cs),
                        Expanded(child: _buildCategoriesList(cs, isExceeded: isExceeded)),
                      ],
                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(ColorScheme cs, {required bool isExceeded}) {
    const cType = 'EXPENSE';
    final filteredCategories = _categories.where((c) => c.categoryType == cType).toList();
    final isMonthly = _period == _BudgetPeriod.monthly;

    if (filteredCategories.isEmpty) {
      return const Center(child: Text('No Expense categories available.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: filteredCategories.length,
      itemBuilder: (context, i) {
        final cat = filteredCategories[i];
        if (cat.id == null) return const SizedBox.shrink();
        
        return GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ColorHelper.fromHex(cat.iconColor).withValues(alpha: 0.15),
                  child: Icon(IconHelper.getIcon(cat.icon), color: ColorHelper.fromHex(cat.iconColor), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                    child: _buildCompactBudgetInput(
                      initialValue: isMonthly 
                        ? (_budgetInputs[cat.id!] ?? '') 
                        : (_annualBudgetInputs[cat.id!] ?? ''),
                      isExceeded: isExceeded,
                      onChanged: (val) {
                        if (isMonthly) {
                          _budgetInputs[cat.id!] = val;
                        } else {
                          _annualBudgetInputs[cat.id!] = val;
                        }
                        setState(() {}); // Refresh planned sum
                      },
                      cs: cs,
                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlobalBudgetCard(ColorScheme cs) {
    final planned = _currentPlannedSum;
    final total = double.tryParse(_globalBudgetInput) ?? 0.0;
    final isExceeded = total > 0 && planned > total;
    final isMonthly = _period == _BudgetPeriod.monthly;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMonthly ? 'Total Monthly Budget' : 'Total Yearly Budget', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  if (total > 0)
                    Text(
                      'Planned: ₹${planned.toStringAsFixed(0)} | ${isExceeded ? 'Exceeded' : '₹${(total - planned).toStringAsFixed(0)} left'}',
                      style: TextStyle(color: isExceeded ? Colors.redAccent : Colors.white60, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (isExceeded)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
              ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: _buildCompactBudgetInput(
                initialValue: _globalBudgetInput,
                isExceeded: isExceeded,
                onChanged: (val) => setState(() => _globalBudgetInput = val),
                cs: cs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBudgetInput({
    required String initialValue,
    required Function(String) onChanged,
    required ColorScheme cs,
    bool isExceeded = false,
  }) {
    final color = isExceeded ? Colors.redAccent : Colors.white;
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.end,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: color.withValues(alpha: 0.2)),
        prefixText: '₹ ',
        prefixStyle: TextStyle(color: isExceeded ? Colors.redAccent.withOpacity(0.7) : Colors.white70, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: InputBorder.none,
      ),
      onChanged: onChanged,
    );
  }
}
