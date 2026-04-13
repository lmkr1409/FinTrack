import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../services/providers.dart';
import '../../../services/sms_listener_service.dart';
import '../../../widgets/demo_value.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';
import '../../labeling/screens/label_screen.dart';

/// Dashboards tab — monthly summary with gradient header and glassmorphic cards.
class DashboardsTab extends ConsumerStatefulWidget {
  const DashboardsTab({super.key});

  @override
  ConsumerState<DashboardsTab> createState() => _DashboardsTabState();
}

enum PieChartGrouping { category, paymentMethod, account, card, purpose }

class _DashboardsTabState extends ConsumerState<DashboardsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  double _totalIncome = 0; // Flow Inflow
  double _totalOutflow = 0; // Flow Outflow
  double _totalExpense = 0; // Spending Insights Total
  double _dailySpend = 0;
  double _largestExpense = 0;
  double _spendingTrend = 0;
  bool _isSpendingUp = false;
  Map<String, double> _allocation = {'income': 0, 'expenses': 0, 'investments': 0};
  String _incomeSourceLabel = ''; // Shows which month's income is being used

  List<Map<String, dynamic>> _dailyTrend = [];
  PieChartGrouping _pieChartGrouping = PieChartGrouping.category;
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categoryList = [];
  List<Map<String, dynamic>> _pieChartData = [];
  List<Map<String, dynamic>> _investmentPieData = [];


  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _handleRefresh() async {
    final container = ProviderScope.containerOf(context);
    await SmsListenerService.syncInboxMessages(container);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final start = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
    final end = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
    final prevMonthStart = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
    final prevMonthEnd = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month, 0));

    // Fetch Flow Data (Inflow/Outflow)
    // For inflow, we use a custom method or just getIncomeAllocation's result
    final flowAllocation = await _analytics.getIncomeAllocation(
      start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59),
      widgetKey: 'financial_flow',
    );
    final inflow = flowAllocation['income'] ?? 0.0;
    final outflow = flowAllocation['expenses'] ?? 0.0;

    // Fetch Spending Insights Data
    final expense = await _analytics.totalByNatureAndType('TRANSACTIONS', 'DEBIT', start, end, widgetKey: 'spending_insights');
    final maxExp = await _analytics.largestExpense(start, end, widgetKey: 'spending_insights');
    
    // Fetch Allocation (for the bar chart at bottom)
    final allocation = await _analytics.getIncomeAllocation(
      start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59),
      widgetKey: 'income_allocation',
    );
    
    // Fetch settings to update the label
    final db = await _analytics.database;
    final settingMaps = await db.query('general_settings');
    final settings = {for (var m in settingMaps) m['setting_key'] as String: m['setting_value'] as String};
    final salaryMode = settings['allocation_salary_mode'] ?? 'CURRENT';
    final otherMode = settings['allocation_other_mode'] ?? 'CURRENT';

    final prevMonthName = DateFormat('MMM yyyy').format(DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    final currMonthName = DateFormat('MMM yyyy').format(_selectedMonth);
    
    String incomeLabel = '';
    if (salaryMode == 'PREV' && otherMode == 'PREV') {
      incomeLabel = 'All income from $prevMonthName';
    } else if (salaryMode == 'PREV' && otherMode == 'CURRENT') {
      incomeLabel = 'Salary from $prevMonthName + other from $currMonthName';
    } else if (salaryMode == 'CURRENT' && otherMode == 'PREV') {
      incomeLabel = 'Salary from $currMonthName + other from $prevMonthName';
    } else {
      incomeLabel = 'All income from $currMonthName';
    }

    final prevExpense = await _analytics.totalByNatureAndType(
      'TRANSACTIONS',
      'DEBIT',
      prevMonthStart,
      prevMonthEnd,
      widgetKey: 'spending_insights',
    );
    final now = DateTime.now();
    final daysToDivide =
        (_selectedMonth.year == now.year && _selectedMonth.month == now.month)
        ? (now.day > 0 ? now.day : 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dSpend = expense / daysToDivide;

    final trend = prevExpense > 0
        ? ((expense - prevExpense) / prevExpense) * 100
        : (expense > 0 ? 100.0 : 0.0);

    final dailyTrend = await _analytics.expensePerDay(start, end, widgetKey: 'daily_heatmap');
    final categoryList = await _analytics.expensesByCategory(start, end, widgetKey: 'expense_breakdown');
    final investmentPie = await _analytics.investmentsByCategory(start, end, widgetKey: 'investment_breakdown');
    List<Map<String, dynamic>> pieChartData = [];

    switch (_pieChartGrouping) {
      case PieChartGrouping.category:
        if (_selectedCategoryId != null) {
          pieChartData = await _analytics.expensesBySubCategory(start, end, _selectedCategoryId!, widgetKey: 'expense_breakdown');
        } else {
          pieChartData = categoryList;
        }
        break;
      case PieChartGrouping.paymentMethod:
        pieChartData = await _analytics.expensesByPaymentMethod(start, end);
        break;
      case PieChartGrouping.account:
        pieChartData = await _analytics.expensesByAccount(start, end);
        break;
      case PieChartGrouping.card:
        pieChartData = await _analytics.expensesByCard(start, end);
        break;
      case PieChartGrouping.purpose:
        pieChartData = await _analytics.expensesByPurpose(start, end);
        break;
    }

    setState(() {
      _totalIncome = inflow;
      _totalOutflow = outflow;
      _totalExpense = expense;
      _largestExpense = maxExp;
      _dailySpend = dSpend;
      _spendingTrend = trend.abs();
      _isSpendingUp = trend > 0;

      _dailyTrend = dailyTrend;
      _categoryList = categoryList;
      _pieChartData = pieChartData;
      _investmentPieData = investmentPie;
      _allocation = allocation;
      _incomeSourceLabel = incomeLabel;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(demoModeProvider).valueOrNull ?? false;
    return Scaffold(
      body: MonthSwiper(
        currentMonth: _selectedMonth,
        onMonthChanged: (newMonth) {
          setState(() => _selectedMonth = newMonth);
          _loadData();
        },
        actions: [
          _DemoToggleButton(isDemo: isDemo, onToggle: () => ref.read(demoModeProvider.notifier).toggle()),
        ],
        child: _buildContent(isDemo),
      ),
    );
  }

  Widget _buildContent(bool isDemo) {
    // Only show full screen loader if no data exists and we are loading
    final hasNoData = _totalIncome == 0 && _totalExpense == 0 && _dailyTrend.isEmpty;
    if (_loading && hasNoData) return const Center(child: CircularProgressIndicator());
    
    final net = _totalIncome - _totalOutflow;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
          // ─── Gradient balance header ──────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Balance',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                DemoValue(
                  rawText: '₹${net.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  iconColor: Colors.white70,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Financial Flow ────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Financial Flow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _MiniInsightCard(
                label: 'Inflow',
                value: isDemo ? null : '₹${_totalIncome.toStringAsFixed(0)}',
                color: AppColors.income,
                icon: Icons.arrow_downward_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'CREDIT', initialWidgetKey: 'financial_flow'))),
              ),
              _MiniInsightCard(
                label: 'Outflow',
                value: isDemo ? null : '₹${_totalOutflow.toStringAsFixed(0)}',
                color: AppColors.expense,
                icon: Icons.arrow_upward_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'DEBIT', initialWidgetKey: 'financial_flow'))),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Spending Insights ────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Spending Insights',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _MiniInsightCard(
                label: 'Total Expenses',
                value: isDemo ? null : '₹${_totalExpense.toStringAsFixed(0)}',
                color: AppColors.expense,
                icon: Icons.receipt_long_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'DEBIT', initialWidgetKey: 'spending_insights'))),
              ),
              _MiniInsightCard(
                label: 'Daily Spend',
                value: isDemo ? null : '₹${_dailySpend.toStringAsFixed(0)}',
                color: AppColors.warning,
                icon: Icons.today_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'DEBIT', initialWidgetKey: 'spending_insights'))),
              ),
              _MiniInsightCard(
                label: 'Spending Trend',
                value: '${_isSpendingUp ? '+' : '-'}${_spendingTrend.toStringAsFixed(1)}%',
                color: _isSpendingUp ? AppColors.expense : AppColors.income,
                icon: _isSpendingUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                subLabel: 'vs last month',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'DEBIT', initialWidgetKey: 'spending_insights'))),
              ),
              _MiniInsightCard(
                label: 'Largest Expense',
                value: isDemo ? null : '₹${_largestExpense.toStringAsFixed(0)}',
                color: AppColors.secondary,
                icon: Icons.monetization_on_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialMonth: _selectedMonth.month, initialYear: _selectedMonth.year, initialNature: 'TRANSACTIONS', initialType: 'DEBIT', initialSort: 'amount DESC', initialLimit: 1, initialWidgetKey: 'spending_insights'))),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _CalendarSection(
            title: 'Daily Expenses', 
            data: _dailyTrend, 
            selectedMonth: _selectedMonth,
            isDemo: isDemo,
            onDayTap: (day) {
              final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
                showBackButton: true,
                initialStartDate: '${dateStr}T00:00:00',
                initialEndDate: '${dateStr}T23:59:59',
                initialNature: 'TRANSACTIONS',
                initialType: 'DEBIT',
                initialWidgetKey: 'daily_heatmap',
              )));
            },
          ),
          const SizedBox(height: 20),
          _DynamicPieChartSection(
            grouping: _pieChartGrouping,
            selectedCategoryId: _selectedCategoryId,
            categoryList: _categoryList,
            data: _pieChartData,
            isDemo: isDemo,
            onSliceTap: _pieChartGrouping == PieChartGrouping.category ? (id) {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
                  showBackButton: true,
                  initialMonth: _selectedMonth.month,
                  initialYear: _selectedMonth.year,
                  initialCategoryId: id,
                  initialWidgetKey: 'expense_breakdown',
                )));
              }
            } : null,
            onGroupingChanged: (val) {
              setState(() {
                _pieChartGrouping = val;
                _selectedCategoryId = null; // Reset drill-down
              });
              _loadData();
            },
            onCategoryChanged: (val) {
              setState(() => _selectedCategoryId = val);
              _loadData();
            },
          ),
          const SizedBox(height: 20),

          _buildIncomeAllocation(isDemo),
          const SizedBox(height: 16),

          _buildInvestmentPieChart(isDemo),
          const SizedBox(height: 16),
        ],
      ),
    ),
    if (_loading)
      Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
  }

  Widget _buildIncomeAllocation(bool isDemo) {
    final income = _allocation['income'] ?? 0.0;
    final exp = _allocation['expenses'] ?? 0.0;
    final inv = _allocation['investments'] ?? 0.0;
    
    final totalSpend = exp + inv;
    final hasIncome = income > 0;
    final hasSpend = totalSpend > 0;
    if (!hasIncome && !hasSpend) return const SizedBox.shrink();

    double savings = (income - exp - inv).clamp(0.0, double.infinity);
    final overspent = (exp + inv) > income && income > 0;

    final totalAllocated = exp + inv + savings;
    final expPct = totalAllocated > 0 ? exp / totalAllocated : 0.0;
    final invPct = totalAllocated > 0 ? inv / totalAllocated : 0.0;
    final savPct = totalAllocated > 0 ? savings / totalAllocated : 0.0;

    void goToExpenses() {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
          showBackButton: true,
          initialMonth: _selectedMonth.month,
          initialYear: _selectedMonth.year,
          initialNature: 'TRANSACTIONS',
          initialType: 'DEBIT',
          initialWidgetKey: 'income_allocation',
        )));
      }
    }
    void goToInvestments() {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
          showBackButton: true,
          initialMonth: _selectedMonth.month,
          initialYear: _selectedMonth.year,
          initialNature: 'INVESTMENTS',
        )));
      }
    }
    void goToIncome() {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
          showBackButton: true,
          initialMonth: _selectedMonth.month,
          initialYear: _selectedMonth.year,
          initialNature: 'TRANSACTIONS',
          initialType: 'CREDIT',
        )));
      }
    }

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header row — tap to see all income
        GestureDetector(
          onTap: goToIncome,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income Allocation',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Budget from: $_incomeSourceLabel',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  isDemo
                    ? const Icon(Icons.visibility_off_rounded, size: 14, color: AppColors.textMuted)
                    : Text(
                        '₹${income.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                      ),
                  const SizedBox(width: 4),
                  const Icon(Icons.settings_suggest_rounded, size: 18, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
        if (overspent) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expense),
                const SizedBox(width: 6),
                isDemo
                  ? const Icon(Icons.visibility_off_rounded, size: 12, color: AppColors.expense)
                  : Text(
                      'Overspent by ₹${(exp + inv - income).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.bold),
                    ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Allocation bar — each segment is individually tappable
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (expPct > 0) Expanded(
                  flex: (expPct * 100).toInt().clamp(1, 100),
                  child: GestureDetector(onTap: goToExpenses, child: Container(color: AppColors.expense)),
                ),
                if (invPct > 0) Expanded(
                  flex: (invPct * 100).toInt().clamp(1, 100),
                  child: GestureDetector(onTap: goToInvestments, child: Container(color: Colors.amberAccent)),
                ),
                if (savPct > 0) Expanded(
                  flex: (savPct * 100).toInt().clamp(1, 100),
                  child: Container(color: AppColors.income),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAllocationLegend(AppColors.expense, 'Expenses', exp, expPct, isDemo: isDemo, onTap: goToExpenses),
            _buildAllocationLegend(Colors.amberAccent, 'Invested', inv, invPct, isDemo: isDemo, onTap: goToInvestments),
            _buildAllocationLegend(AppColors.income, 'Savings', savings, savPct, isDemo: isDemo),
          ],
        ),
      ],
    ),
  );
  }

  Widget _buildAllocationLegend(Color color, String label, double amount, double pct, {bool isDemo = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 9, color: color),
              ],
            ],
          ),
          const SizedBox(height: 2),
          isDemo
            ? const Icon(Icons.visibility_off_rounded, size: 12, color: AppColors.textMuted)
            : Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildInvestmentPieChart(bool isDemo) {
    if (_investmentPieData.isEmpty) return const SizedBox.shrink();

    final total = _investmentPieData.fold<double>(
      0,
      (sum, item) => sum + (item['value'] as num).toDouble(),
    );

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Investments Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
              isDemo
                ? const Icon(Icons.visibility_off_rounded, size: 14, color: Colors.amberAccent)
                : Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amberAccent),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
                        final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (idx >= 0 && idx < _investmentPieData.length) {
                          final catId = _investmentPieData[idx]['id'] as int?;
                          if (catId != null) {
                            if (ModalRoute.of(context)?.isCurrent == true) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(
                              showBackButton: true,
                              initialMonth: _selectedMonth.month,
                              initialYear: _selectedMonth.year,
                              initialNature: 'INVESTMENTS',
                              initialCategoryId: catId,
                              initialWidgetKey: 'investment_breakdown',
                            )));
                            }
                          }
                        }
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: _investmentPieData.map((item) {
                      final value = (item['value'] as num).toDouble();
                      final colorHex = item['color'] as String? ?? '#FFC107';
                      final color = ColorHelper.fromHex(colorHex);
                      return PieChartSectionData(
                        color: color,
                        value: value,
                        title: '',
                        radius: 20,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _investmentPieData.map((item) {
                    final name = item['name'] as String? ?? 'Unknown';
                    final value = (item['value'] as num).toDouble();
                    final colorHex = item['color'] as String? ?? '#FFC107';
                    final color = ColorHelper.fromHex(colorHex);
                    final pct = total > 0 ? (value / total * 100) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              isDemo
                                ? Text('${pct.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary))
                                : Text('₹${value.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('${pct.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final String label;
  final String? value; // null = demo mode hidden
  final Color color;
  final IconData icon;
  final String? subLabel;
  final VoidCallback? onTap;
  const _MiniInsightCard({
    required this.label,
    required this.color,
    required this.icon,
    this.value,
    this.subLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          if (onTap != null) onTap!();
        }
      },
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          value == null
            ? Icon(Icons.visibility_off_rounded, size: 18, color: color.withValues(alpha: 0.6))
            : Text(
                value!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    ));
  }
}


class _CalendarSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final DateTime selectedMonth;
  final void Function(int day)? onDayTap;
  final bool isDemo;

  const _CalendarSection({required this.title, required this.data, required this.selectedMonth, this.onDayTap, this.isDemo = false});

  @override
  Widget build(BuildContext context) {
    // Convert data to Map<int, double> where key is day of month
    final Map<int, double> dailyTotals = {};
    double maxTotal = 0.0;
    for (var item in data) {
      final period = item['period'] as String? ?? '';
      if (period.length >= 10) {
        final day = int.tryParse(period.substring(8, 10));
        if (day != null) {
          final total = (item['total'] as num).toDouble();
          dailyTotals[day] = (dailyTotals[day] ?? 0.0) + total;
          if (dailyTotals[day]! > maxTotal) maxTotal = dailyTotals[day]!;
        }
      }
    }

    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    
    // weekday is 1=Monday, 7=Sunday. Subtract 1 so Monday=0, Sunday=6
    final startOffset = firstDayOfMonth.weekday - 1; 

    // Total cells needed for the GridView (padding + days)
    final totalCells = daysInMonth + startOffset;
    final weeks = (totalCells / 7).ceil();

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
          const SizedBox(height: 16),
          // Day initials header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(d, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.9,
            ),
            itemCount: weeks * 7, // Full rows
            itemBuilder: (context, index) {
              if (index < startOffset || index >= startOffset + daysInMonth) {
                return const SizedBox.shrink(); // Empty grid slot
              }

              final day = index - startOffset + 1;
              final amount = dailyTotals[day] ?? 0.0;
              final isToday = DateTime.now().year == selectedMonth.year && 
                              DateTime.now().month == selectedMonth.month && 
                              DateTime.now().day == day;
              
              // Heatmap dynamic coloring logic
              Color cellColor = Colors.transparent;
              Color textColor = AppColors.textPrimary;
              Color amountColor = AppColors.textMuted;
              
              if (amount > 0) {
                // Determine opacity visually so high spend days pop
                final intensity = maxTotal > 0 ? (amount / maxTotal).clamp(0.15, 1.0) : 0.15;
                cellColor = AppColors.primary.withValues(alpha: intensity);
                
                // If it's dark/opaque enough, use white text for contrast
                if (intensity > 0.5) {
                   textColor = Colors.white;
                   amountColor = Colors.white70;
                } else {
                   textColor = AppColors.primary;
                   amountColor = AppColors.primary.withValues(alpha: 0.8);
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (ModalRoute.of(context)?.isCurrent == true) {
                    if (onDayTap != null) onDayTap!(day);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday && amount == 0 
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5) 
                      : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (amount > 0) ...[
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: isDemo
                              ? Icon(Icons.visibility_off_rounded, size: 9, color: amountColor)
                              : Text(
                                  amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: amountColor),
                                ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DynamicPieChartSection extends StatelessWidget {
  final PieChartGrouping grouping;
  final int? selectedCategoryId;
  final List<Map<String, dynamic>> categoryList;
  final List<Map<String, dynamic>> data;
  final ValueChanged<PieChartGrouping> onGroupingChanged;
  final ValueChanged<int?> onCategoryChanged;
  final void Function(int id)? onSliceTap;
  final bool isDemo;

  const _DynamicPieChartSection({
    required this.grouping,
    required this.selectedCategoryId,
    required this.categoryList,
    required this.data,
    required this.onGroupingChanged,
    required this.onCategoryChanged,
    this.onSliceTap,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PieChartGrouping>(
                    value: grouping,
                    isExpanded: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    onChanged: (val) {
                      if (val != null) onGroupingChanged(val);
                    },
                    items: const [
                      DropdownMenuItem(value: PieChartGrouping.category, child: Text('By Category')),
                      DropdownMenuItem(value: PieChartGrouping.paymentMethod, child: Text('By Payment Method')),
                      DropdownMenuItem(value: PieChartGrouping.account, child: Text('By Bank Account')),
                      DropdownMenuItem(value: PieChartGrouping.card, child: Text('By Card')),
                      DropdownMenuItem(value: PieChartGrouping.purpose, child: Text('By Purpose')),
                    ],
                  ),
                ),
              ),
              if (grouping == PieChartGrouping.category && categoryList.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedCategoryId,
                      isExpanded: true,
                      hint: const Text('All', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      onChanged: onCategoryChanged,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Categories')),
                        ...categoryList.where((c) => c['id'] != null).map((cat) {
                          final id = cat['id'] as int;
                          final name = cat['name'] as String? ?? 'Unknown';
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No data found.', style: TextStyle(color: AppColors.textMuted))))
          else
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
                          final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          if (idx >= 0 && idx < data.length) {
                            final id = data[idx]['id'] as int?;
                            if (id != null && onSliceTap != null) {
                              onSliceTap!(id);
                            }
                          }
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: data.map((item) {
                        final value = (item['value'] as num).toDouble();
                        final colorHex = item['color'] as String? ?? '#9E9E9E';
                        final color = ColorHelper.fromHex(colorHex);
                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title: '',
                          radius: 20,
                          badgeWidget: null,
                          titlePositionPercentageOffset: 0.55,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Custom Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.map((item) {
                      final name = item['name'] as String? ?? 'Unknown';
                      final value = (item['value'] as num).toDouble();
                      final colorHex = item['color'] as String? ?? '#9E9E9E';
                      final color = ColorHelper.fromHex(colorHex);
                      final total = data.fold<double>(0, (s, e) => s + (e['value'] as num).toDouble());
                      final pct = total > 0 ? (value / total * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                            Text(
                              isDemo ? '${pct.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Small toggle button rendered inside the MonthSwiper header (right-aligned).
class _DemoToggleButton extends StatelessWidget {
  final bool isDemo;
  final VoidCallback onToggle;
  const _DemoToggleButton({required this.isDemo, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDemo ? 'Masking ON — tap to show details' : 'Hide sensitive details',
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDemo
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDemo
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDemo ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 14,
                color: isDemo ? AppColors.primary : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                'Hide Details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDemo ? AppColors.primary : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
