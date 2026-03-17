import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

/// Trends tab — 12-month aggregated insights and income vs expense chart.
class TrendsTab extends StatefulWidget {
  const TrendsTab({super.key});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  List<Map<String, dynamic>> _yearlyTrend = [];
  
  double _avgMonthlyBudget = 0;
  double _avgMonthlySpending = 0;
  double _avgMonthlySavings = 0;
  double _averageUtilization = 0;
  int _overBudgetMonths = 0;
  double _savingsRate = 0;
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final yearly = await _analytics.incomeVsExpenseLast12Months();
    final budgetStats = await _analytics.getLast12MonthsBudgetStats();

    double totalIncome12m = 0;
    double totalExpense12m = 0;
    for (var m in yearly) {
      totalIncome12m += (m['income'] as num).toDouble();
      totalExpense12m += (m['expense'] as num).toDouble();
    }
    
    setState(() {
      _yearlyTrend = yearly;
      _avgMonthlyBudget = budgetStats['avgMonthlyBudget'] as double;
      _avgMonthlySpending = totalExpense12m / 12;
      _avgMonthlySavings = (totalIncome12m - totalExpense12m) / 12;
      _averageUtilization = budgetStats['averageUtilization'] as double;
      _overBudgetMonths = budgetStats['overBudgetMonths'] as int;
      _savingsRate = totalIncome12m > 0 ? ((totalIncome12m - totalExpense12m) / totalIncome12m) * 100 : 0.0;
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
          _loadData(); // Swiper will change context month, though 12 months is effectively relative to 'now' mostly. If we wanted it relative to selectedMonth, we'd need to pass it to AnalyticsService. But typical 'trends' focus is usually just the latest unless specified. For now we just refresh.
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Last 12 Months Insights', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _MiniInsightCard(label: 'Avg Monthly Budget', value: '₹${_avgMonthlyBudget.toStringAsFixed(0)}', color: AppColors.primary, icon: Icons.account_balance_wallet_rounded),
              _MiniInsightCard(label: 'Avg Monthly Spend', value: '₹${_avgMonthlySpending.toStringAsFixed(0)}', color: AppColors.expense, icon: Icons.money_off_rounded),
              _MiniInsightCard(label: 'Avg Monthly Savings', value: '₹${_avgMonthlySavings.toStringAsFixed(0)}', color: AppColors.income, icon: Icons.savings_rounded),
              _MiniInsightCard(label: 'Avg Utilization', value: '${_averageUtilization.toStringAsFixed(1)}%', color: AppColors.warning, icon: Icons.pie_chart_rounded),
              _MiniInsightCard(label: 'Over Budget Months', value: '$_overBudgetMonths / 12', color: AppColors.expense, icon: Icons.warning_amber_rounded),
              _MiniInsightCard(label: 'Savings Rate', value: '${_savingsRate.toStringAsFixed(1)}%', color: _savingsRate >= 0 ? AppColors.income : AppColors.expense, icon: Icons.percent_rounded),
            ],
          ),
          const SizedBox(height: 24),
          _DualTrendSection(title: 'Last 12 Months (Income vs Expense)', data: _yearlyTrend),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniInsightCard({required this.label, required this.value, required this.color, required this.icon});

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
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DualTrendSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  const _DualTrendSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxIncome = data.fold<double>(0, (prev, e) => ((e['income'] as num).toDouble() > prev) ? (e['income'] as num).toDouble() : prev);
    final maxExpense = data.fold<double>(0, (prev, e) => ((e['expense'] as num).toDouble() > prev) ? (e['expense'] as num).toDouble() : prev);
    final maxVal = maxIncome > maxExpense ? maxIncome : maxExpense;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
            Row(
              children: [
                _buildLegendItem('In', AppColors.income),
                const SizedBox(width: 8),
                _buildLegendItem('Out', AppColors.expense),
              ],
            )
          ],
        ),
        const SizedBox(height: 14),
        if (data.isEmpty)
          const Text('No data', style: TextStyle(color: AppColors.textMuted))
        else
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final income = (item['income'] as num).toDouble();
                final expense = (item['expense'] as num).toDouble();
                final period = item['period'] as String? ?? '';
                final incomeFraction = maxVal > 0 ? income / maxVal : 0.0;
                final expenseFraction = maxVal > 0 ? expense / maxVal : 0.0;
                
                // Format YYYY-MM to short month name (e.g., Jan, Feb)
                String label = period;
                if (period.length >= 7) {
                  try {
                    final dt = DateTime.parse('${period.substring(0, 7)}-01');
                    label = DateFormat('MMM').format(dt);
                  } catch (_) {
                    label = period.substring(5);
                  }
                }
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Income Bar
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(income > 0 ? '${(income / 1000).toStringAsFixed(0)}k' : '', style: const TextStyle(fontSize: 7, color: AppColors.textMuted), maxLines: 1),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: FractionallySizedBox(
                                        heightFactor: income > 0 ? incomeFraction.clamp(0.05, 1.0) : 0,
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.income.withValues(alpha: 0.8),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Expense Bar
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(expense > 0 ? '${(expense / 1000).toStringAsFixed(0)}k' : '', style: const TextStyle(fontSize: 7, color: AppColors.textMuted), maxLines: 1),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: FractionallySizedBox(
                                        heightFactor: expense > 0 ? expenseFraction.clamp(0.05, 1.0) : 0,
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.expense.withValues(alpha: 0.8),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

