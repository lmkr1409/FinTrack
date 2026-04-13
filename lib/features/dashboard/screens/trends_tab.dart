import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../services/providers.dart';
import '../../../services/sms_listener_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';
import '../../labeling/screens/label_screen.dart';

/// Trends tab — 12-month aggregated insights and income vs expense chart.
class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  List<Map<String, dynamic>> _yearlyTrend = [];
  List<Map<String, dynamic>> _investmentTrend = [];
  
  double _avgMonthlyBudget = 0;
  double _avgMonthlySpending = 0;
  double _avgMonthlySavings = 0;
  double _averageUtilization = 0;
  int _overBudgetMonths = 0;
  double _savingsRate = 0;
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _handleRefresh() async {
    final container = ProviderScope.containerOf(context);
    await SmsListenerService.syncInboxMessages(container);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final yearly = await _analytics.incomeVsExpenseLast12Months(widgetKey: 'monthly_trends');
    final investmentTrend = await _analytics.netInvestmentsLast12Months(widgetKey: 'monthly_trends');
    final budgetStats = await _analytics.getLast12MonthsBudgetStats();

    double totalIncome12m = 0;
    double totalExpense12m = 0;
    for (var m in yearly) {
      totalIncome12m += (m['income'] as num).toDouble();
      totalExpense12m += (m['expense'] as num).toDouble();
    }
    
    setState(() {
      _yearlyTrend = yearly;
      _investmentTrend = investmentTrend;
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
    final isDemo = ref.watch(demoModeProvider).valueOrNull ?? false;
    return Scaffold(
      body: MonthSwiper(
        currentMonth: _selectedMonth,
        onMonthChanged: (newMonth) {
          setState(() => _selectedMonth = newMonth);
          _loadData();
        },
        child: _buildContent(isDemo),
      ),
    );
  }

  Widget _buildContent(bool isDemo) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              _MiniInsightCard(label: 'Avg Monthly Budget', value: isDemo ? null : '₹${_avgMonthlyBudget.toStringAsFixed(0)}', color: AppColors.primary, icon: Icons.account_balance_wallet_rounded),
              _MiniInsightCard(label: 'Avg Monthly Spend', value: isDemo ? null : '₹${_avgMonthlySpending.toStringAsFixed(0)}', color: AppColors.expense, icon: Icons.money_off_rounded),
              _MiniInsightCard(label: 'Avg Monthly Savings', value: isDemo ? null : '₹${_avgMonthlySavings.toStringAsFixed(0)}', color: AppColors.income, icon: Icons.savings_rounded),
              _MiniInsightCard(label: 'Avg Utilization', value: '${_averageUtilization.toStringAsFixed(1)}%', color: AppColors.warning, icon: Icons.pie_chart_rounded),
              _MiniInsightCard(label: 'Over Budget Months', value: '$_overBudgetMonths / 12', color: AppColors.expense, icon: Icons.warning_amber_rounded),
              _MiniInsightCard(label: 'Savings Rate', value: '${_savingsRate.toStringAsFixed(1)}%', color: _savingsRate >= 0 ? AppColors.income : AppColors.expense, icon: Icons.percent_rounded),
            ],
          ),
          const SizedBox(height: 24),
          _DualTrendSection(title: 'Last 12 Months (Income vs Expense)', data: _yearlyTrend, isDemo: isDemo),
          const SizedBox(height: 20),
          _InvestmentTrendSection(data: _investmentTrend, isDemo: isDemo),
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
  const _MiniInsightCard({required this.label, required this.color, required this.icon, this.value});

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
          value == null
            ? Icon(Icons.visibility_off_rounded, size: 18, color: color.withValues(alpha: 0.6))
            : Text(value!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DualTrendSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final bool isDemo;
  const _DualTrendSection({required this.title, required this.data, this.isDemo = false});

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
                  child: GestureDetector(
                    onTap: () {
                      if (ModalRoute.of(context)?.isCurrent == true) {
                        if (period.length >= 7) {
                          final y = int.tryParse(period.substring(0, 4));
                          final m = int.tryParse(period.substring(5, 7));
                          if (y != null && m != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialYear: y, initialMonth: m)));
                          }
                        }
                      }
                    },
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
                                    Text(isDemo ? '' : (income > 0 ? '${(income / 1000).toStringAsFixed(0)}k' : ''), style: const TextStyle(fontSize: 7, color: AppColors.textMuted), maxLines: 1),
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
                                    Text(isDemo ? '' : (expense > 0 ? '${(expense / 1000).toStringAsFixed(0)}k' : ''), style: const TextStyle(fontSize: 7, color: AppColors.textMuted), maxLines: 1),
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


class _InvestmentTrendSection extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDemo;
  const _InvestmentTrendSection({required this.data, this.isDemo = false});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (prev, e) {
      final v = (e['net_investment'] as num).toDouble();
      return v > prev ? v : prev;
    });

    final total12m = data.fold<double>(0, (sum, e) => sum + (e['net_investment'] as num).toDouble());
    final avgMonthly = total12m / 12;

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
                'Net Investments (12M)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  isDemo
                    ? const Icon(Icons.visibility_off_rounded, size: 12, color: Colors.amberAccent)
                    : Text('?${total12m.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amberAccent)),
                  isDemo
                    ? const Icon(Icons.visibility_off_rounded, size: 10, color: AppColors.textMuted)
                    : Text('avg ?${avgMonthly.toStringAsFixed(0)}/mo',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (maxVal == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No investment data for last 12 months.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final netInv = (item['net_investment'] as num).toDouble();
                  final period = item['period'] as String? ?? '';
                  final fraction = maxVal > 0 ? (netInv / maxVal).clamp(0.0, 1.0) : 0.0;

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
                    child: GestureDetector(
                      onTap: () {
                        if (ModalRoute.of(context)?.isCurrent == true) {
                          if (period.length >= 7) {
                            final y = int.tryParse(period.substring(0, 4));
                            final m = int.tryParse(period.substring(5, 7));
                            if (y != null && m != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => LabelScreen(showBackButton: true, initialYear: y, initialMonth: m, initialNature: 'INVESTMENTS')));
                            }
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (netInv > 0)
                            Text(
                              netInv >= 1000
                                  ? '${(netInv / 1000).toStringAsFixed(0)}k'
                                  : netInv.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
                              maxLines: 1,
                            ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: fraction > 0 ? fraction.clamp(0.04, 1.0) : 0,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amberAccent.withValues(alpha: 0.5),
                                      Colors.amberAccent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
