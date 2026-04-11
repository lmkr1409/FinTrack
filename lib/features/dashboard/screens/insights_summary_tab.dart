import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

/// Insights tab — smart spending suggestions in glassmorphic cards.
class InsightsSummaryTab extends StatefulWidget {
  const InsightsSummaryTab({super.key});

  @override
  State<InsightsSummaryTab> createState() => _InsightsSummaryTabState();
}

class _InsightsSummaryTabState extends State<InsightsSummaryTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  final List<_Insight> _insights = [];
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _generateInsights();
  }

  Future<void> _generateInsights() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _insights.clear();
    });

    final now = DateTime.now();
    final start = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

    final totalExpense = await _analytics.totalByNatureAndType('TRANSACTIONS', 'DEBIT', start, end, widgetKey: 'financial_summary');
    final totalIncome = await _analytics.totalByNatureAndType('TRANSACTIONS', 'CREDIT', start, end, widgetKey: 'financial_summary');
    final topCats = await _analytics.topCategories(start, end, limit: 3, widgetKey: 'financial_summary');
    final rawBudgets = await _analytics.budgetVsActual(_selectedMonth.month, _selectedMonth.year, categoryTypes: ['TRANSACTIONS'], widgetKey: 'financial_summary');
    final budgets = rawBudgets.where((b) => b['category_name']?.toString().toLowerCase() != 'income').toList();

    if (totalIncome > 0) {
      final ratio = totalExpense / totalIncome;
      if (ratio > 0.9) {
        _insights.add(_Insight(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            title: 'High Spending Alert',
            body: 'You\'ve spent ${(ratio * 100).toStringAsFixed(0)}% of your income. Consider cutting discretionary expenses.'));
      } else if (ratio < 0.5) {
        _insights.add(_Insight(
            icon: Icons.thumb_up_rounded,
            color: AppColors.income,
            title: 'Great Savings!',
            body: 'You\'re saving ${((1 - ratio) * 100).toStringAsFixed(0)}% of your income. Keep it up!'));
      }
    }

    if (topCats.isNotEmpty && totalExpense > 0) {
      final topCat = topCats.first;
      final pct = (topCat['total'] as num).toDouble() / totalExpense * 100;
      if (pct > 40) {
        _insights.add(_Insight(
            icon: Icons.pie_chart_rounded,
            color: AppColors.secondary,
            title: '${topCat['category_name']} Dominates Spending',
            body: '${pct.toStringAsFixed(0)}% of expenses go to ${topCat['category_name']}. Look for ways to optimize.'));
      }
    }

    final overBudgets = budgets.where((b) => (b['actual'] as num).toDouble() > (b['budget_amount'] as num).toDouble()).toList();
    if (overBudgets.isNotEmpty) {
      final names = overBudgets.map((b) => b['category_name'] ?? 'Unknown').join(', ');
      _insights.add(_Insight(
          icon: Icons.money_off_rounded,
          color: AppColors.expense,
          title: "${overBudgets.length} Budget${overBudgets.length > 1 ? 's' : ''} Exceeded",
          body: 'Over budget in: $names. Review spending in these areas.'));
    }

    if (totalExpense == 0) {
      _insights.add(_Insight(
          icon: Icons.lightbulb_outline,
          color: AppColors.tertiary,
          title: 'No Expenses This Month',
          body: 'Start logging your transactions to get personalized insights.'));
    }

    if (totalExpense > 0 && _selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      final dailyAvg = totalExpense / now.day;
      final projected = dailyAvg * DateTime(now.year, now.month + 1, 0).day;
      _insights.add(_Insight(
          icon: Icons.trending_up_rounded,
          color: AppColors.info,
          title: 'Projected Monthly Spend',
          body: 'At ₹${dailyAvg.toStringAsFixed(0)}/day, your projected total is ₹${projected.toStringAsFixed(0)} this month.'));
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MonthSwiper(
        currentMonth: _selectedMonth,
        onMonthChanged: (newMonth) {
          setState(() => _selectedMonth = newMonth);
          _generateInsights();
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _generateInsights,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Smart Insights',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            if (_insights.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No insights available yet.', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _insights.length,
                itemBuilder: (context, i) {
                  final ins = _insights[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: ins.color.withValues(alpha: 0.15),
                            child: Icon(ins.icon, color: ins.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ins.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(ins.body,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Insight({required this.icon, required this.color, required this.title, required this.body});
}
