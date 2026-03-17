import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

/// Analytics tab — visual charts (bar, pie) for expense breakdowns.
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  
  List<Map<String, dynamic>> _dailyTrend = [];
  List<Map<String, dynamic>> _categoryExpenses = [];
  List<Map<String, dynamic>> _paymentExpenses = [];
  List<Map<String, dynamic>> _purposeExpenses = [];
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final monthStart = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
    final monthEnd = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
    
    _dailyTrend = await _analytics.expensePerDay(monthStart, monthEnd);
    _categoryExpenses = await _analytics.expensesByCategory(monthStart, monthEnd);
    _paymentExpenses = await _analytics.expensesByPaymentMethod(monthStart, monthEnd);
    _purposeExpenses = await _analytics.expensesByPurpose(monthStart, monthEnd);
    
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TrendSection(title: 'Daily Expenses', data: _dailyTrend, isDaily: true, barColor: AppColors.primary),
          const SizedBox(height: 20),
          _PieChartSection(title: 'Expenses by Category', data: _categoryExpenses),
          const SizedBox(height: 20),
          _PieChartSection(title: 'Expenses by Payment Method', data: _paymentExpenses),
          const SizedBox(height: 20),
          _PieChartSection(title: 'Expenses by Purpose', data: _purposeExpenses),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final bool isDaily;
  final Color barColor;
  const _TrendSection({required this.title, required this.data, required this.isDaily, required this.barColor});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (prev, e) => ((e['total'] as num).toDouble() > prev) ? (e['total'] as num).toDouble() : prev);
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
        const SizedBox(height: 14),
        if (data.isEmpty)
          const Text('No data', style: TextStyle(color: AppColors.textMuted))
        else
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final total = (item['total'] as num).toDouble();
                final period = item['period'] as String? ?? '';
                final fraction = maxVal > 0 ? total / maxVal : 0.0;
                final label = isDaily ? period.substring(period.length >= 10 ? 8 : 0) : period.substring(period.length >= 7 ? 5 : 0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(total > 0 ? '${(total / 1000).toStringAsFixed(1)}k' : '', style: const TextStyle(fontSize: 8, color: AppColors.textMuted), maxLines: 1),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: fraction.clamp(0.05, 1.0),
                          child: Container(decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [barColor, barColor.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          )),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }
}

class _PieChartSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;

  const _PieChartSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
          const SizedBox(height: 24),
          if (data.isEmpty)
            const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)))
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
