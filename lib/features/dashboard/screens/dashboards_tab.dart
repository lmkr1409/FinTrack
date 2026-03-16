import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';

/// Dashboards tab — monthly summary with gradient header and glassmorphic cards.
class DashboardsTab extends StatefulWidget {
  const DashboardsTab({super.key});

  @override
  State<DashboardsTab> createState() => _DashboardsTabState();
}

class _DashboardsTabState extends State<DashboardsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  late String _monthLabel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
    _monthLabel = DateFormat('MMMM yyyy').format(now);

    final income = await _analytics.totalByType('CREDIT', start, end);
    final expense = await _analytics.totalByType('DEBIT', start, end);

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final net = _totalIncome - _totalExpense;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
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
                Text(_monthLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '₹${net.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Summary cards ────────────────────────────
          _GlassSummaryCard(label: 'Total Income', value: _totalIncome, color: AppColors.income, icon: Icons.arrow_downward_rounded),
          const SizedBox(height: 8),
          _GlassSummaryCard(label: 'Total Expenses', value: _totalExpense, color: AppColors.expense, icon: Icons.arrow_upward_rounded),
        ],
      ),
    );
  }
}

class _GlassSummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _GlassSummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                '₹${value.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
