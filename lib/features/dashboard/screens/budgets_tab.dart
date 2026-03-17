import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

/// Budgets tab — budget vs actual with glassmorphic cards and themed progress bars.
class BudgetsTab extends StatefulWidget {
  const BudgetsTab({super.key});

  @override
  State<BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<BudgetsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  List<Map<String, dynamic>> _budgets = [];
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _budgets = await _analytics.budgetVsActual(_selectedMonth.month, _selectedMonth.year);
    setState(() => _loading = false);
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_budgets.isEmpty) return const Center(child: Text('No budgets set for this month.', style: TextStyle(color: AppColors.textMuted)));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _budgets.map((b) {
          final budget = (b['budget_amount'] as num).toDouble();
          final actual = (b['actual'] as num).toDouble();
          final catName = b['category_name'] as String? ?? 'All';
          final progress = budget > 0 ? (actual / budget).clamp(0.0, 1.5) : 0.0;
          final over = actual > budget;
          final barColor = over ? AppColors.expense : AppColors.primary;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  Text(
                    over ? 'Over by ₹${(actual - budget).toStringAsFixed(0)}' : '₹${(budget - actual).toStringAsFixed(0)} left',
                    style: TextStyle(color: over ? AppColors.expense : AppColors.income, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress.toDouble(), minHeight: 10, backgroundColor: AppColors.surfaceContainer, color: barColor),
                ),
                const SizedBox(height: 6),
                Text('₹${actual.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
