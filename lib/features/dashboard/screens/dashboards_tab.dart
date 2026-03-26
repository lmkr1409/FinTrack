import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../services/sms_listener_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

/// Dashboards tab — monthly summary with gradient header and glassmorphic cards.
class DashboardsTab extends StatefulWidget {
  const DashboardsTab({super.key});

  @override
  State<DashboardsTab> createState() => _DashboardsTabState();
}

enum PieChartGrouping { category, paymentMethod, account, card, purpose }

class _DashboardsTabState extends State<DashboardsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  int _transactionCount = 0;
  double _dailySpend = 0;
  double _largestExpense = 0;
  double _spendingTrend = 0;
  bool _isSpendingUp = false;

  List<Map<String, dynamic>> _dailyTrend = [];
  PieChartGrouping _pieChartGrouping = PieChartGrouping.category;
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categoryList = [];
  List<Map<String, dynamic>> _pieChartData = [];


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

    final income = await _analytics.totalByType('CREDIT', start, end);
    final expense = await _analytics.totalByType('DEBIT', start, end);
    final tCount = await _analytics.transactionCount(start, end);
    final maxExp = await _analytics.largestExpense(start, end);

    final prevExpense = await _analytics.totalByType(
      'DEBIT',
      prevMonthStart,
      prevMonthEnd,
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

    final dailyTrend = await _analytics.expensePerDay(start, end);
    final categoryList = await _analytics.expensesByCategory(start, end);
    List<Map<String, dynamic>> pieChartData = [];

    switch (_pieChartGrouping) {
      case PieChartGrouping.category:
        if (_selectedCategoryId != null) {
          pieChartData = await _analytics.expensesBySubCategory(start, end, _selectedCategoryId!);
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
      _totalIncome = income;
      _totalExpense = expense;
      _transactionCount = tCount;
      _largestExpense = maxExp;
      _dailySpend = dSpend;
      _spendingTrend = trend.abs();
      _isSpendingUp = trend > 0;

      _dailyTrend = dailyTrend;
      _categoryList = categoryList;
      _pieChartData = pieChartData;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MonthSwiper(
        currentMonth: _selectedMonth,
        onMonthChanged: (newMonth) {
          setState(() => _selectedMonth = newMonth);
          _loadData();
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Only show full screen loader if no data exists and we are loading
    final hasNoData = _totalIncome == 0 && _totalExpense == 0 && _dailyTrend.isEmpty;
    if (_loading && hasNoData) return const Center(child: CircularProgressIndicator());
    
    final net = _totalIncome - _totalExpense;

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
                const Text(
                  'Net Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${net.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Summary cards ────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _MiniInsightCard(
                label: 'Total Expense',
                value: '₹${_totalExpense.toStringAsFixed(0)}',
                color: AppColors.expense,
                icon: Icons.arrow_upward_rounded,
              ),
              _MiniInsightCard(
                label: 'Total Income',
                value: '₹${_totalIncome.toStringAsFixed(0)}',
                color: AppColors.income,
                icon: Icons.arrow_downward_rounded,
              ),
              _MiniInsightCard(
                label: 'No of Txns',
                value: '$_transactionCount',
                color: AppColors.info,
                icon: Icons.receipt_long_rounded,
              ),
              _MiniInsightCard(
                label: 'Daily Spend',
                value: '₹${_dailySpend.toStringAsFixed(0)}',
                color: AppColors.warning,
                icon: Icons.today_rounded,
              ),
              _MiniInsightCard(
                label: 'Spending Trend',
                value:
                    '${_isSpendingUp ? '+' : '-'}${_spendingTrend.toStringAsFixed(1)}%',
                color: _isSpendingUp ? AppColors.expense : AppColors.income,
                icon: _isSpendingUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                subLabel: 'vs last month',
              ),
              _MiniInsightCard(
                label: 'Largest Expense',
                value: '₹${_largestExpense.toStringAsFixed(0)}',
                color: AppColors.secondary,
                icon: Icons.monetization_on_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _CalendarSection(title: 'Daily Expenses', data: _dailyTrend, selectedMonth: _selectedMonth),
          const SizedBox(height: 20),
          _DynamicPieChartSection(
            grouping: _pieChartGrouping,
            selectedCategoryId: _selectedCategoryId,
            categoryList: _categoryList,
            data: _pieChartData,
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
}

class _MiniInsightCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subLabel;
  const _MiniInsightCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
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
          const SizedBox(height: 6),
          Text(
            value,
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
    );
  }
}


class _CalendarSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final DateTime selectedMonth;

  const _CalendarSection({required this.title, required this.data, required this.selectedMonth});

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

              return Container(
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
                          child: Text(
                            amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: amountColor),
                          ),
                        ),
                      ),
                    ]
                  ],
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

  const _DynamicPieChartSection({
    required this.grouping,
    required this.selectedCategoryId,
    required this.categoryList,
    required this.data,
    required this.onGroupingChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                            Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
