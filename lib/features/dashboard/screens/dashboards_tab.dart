import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/month_swiper.dart';

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
  int _transactionCount = 0;
  double _dailySpend = 0;
  double _largestExpense = 0;
  double _spendingTrend = 0;
  bool _isSpendingUp = false;
  
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _topMerchants = [];
  List<Map<String, dynamic>> _topAccounts = [];
  List<Map<String, dynamic>> _topPurposes = [];
  
  late String _monthLabel;
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final start = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
    final prevMonthStart = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
    final prevMonthEnd = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, 0));
    _monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    final income = await _analytics.totalByType('CREDIT', start, end);
    final expense = await _analytics.totalByType('DEBIT', start, end);
    final tCount = await _analytics.transactionCount(start, end);
    final maxExp = await _analytics.largestExpense(start, end);
    
    final prevExpense = await _analytics.totalByType('DEBIT', prevMonthStart, prevMonthEnd);
    final now = DateTime.now();
    final daysToDivide = (_selectedMonth.year == now.year && _selectedMonth.month == now.month) 
        ? (now.day > 0 ? now.day : 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dSpend = expense / daysToDivide;
    
    final trend = prevExpense > 0 ? ((expense - prevExpense) / prevExpense) * 100 : (expense > 0 ? 100.0 : 0.0);

    final cats = await _analytics.topCategories(start, end);
    final merchs = await _analytics.topMerchants(start, end);
    final accs = await _analytics.topAccounts(start, end);
    final purps = await _analytics.topPurposes(start, end);

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _transactionCount = tCount;
      _largestExpense = maxExp;
      _dailySpend = dSpend;
      _spendingTrend = trend.abs();
      _isSpendingUp = trend > 0;
      
      _topCategories = cats;
      _topMerchants = merchs;
      _topAccounts = accs;
      _topPurposes = purps;
      
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
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _MiniInsightCard(label: 'Total Expense', value: '₹${_totalExpense.toStringAsFixed(0)}', color: AppColors.expense, icon: Icons.arrow_upward_rounded),
              _MiniInsightCard(label: 'Total Income', value: '₹${_totalIncome.toStringAsFixed(0)}', color: AppColors.income, icon: Icons.arrow_downward_rounded),
              _MiniInsightCard(label: 'No of Txns', value: '$_transactionCount', color: AppColors.info, icon: Icons.receipt_long_rounded),
              _MiniInsightCard(label: 'Daily Spend', value: '₹${_dailySpend.toStringAsFixed(0)}', color: AppColors.warning, icon: Icons.today_rounded),
              _MiniInsightCard(
                label: 'Spending Trend', 
                value: '${_isSpendingUp ? '+' : '-'}${_spendingTrend.toStringAsFixed(1)}%', 
                color: _isSpendingUp ? AppColors.expense : AppColors.income, 
                icon: _isSpendingUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                subLabel: 'vs last month',
              ),
              _MiniInsightCard(label: 'Largest Expense', value: '₹${_largestExpense.toStringAsFixed(0)}', color: AppColors.secondary, icon: Icons.monetization_on_rounded),
            ],
          ),
          const SizedBox(height: 24),
          
          _TopSection(title: 'Top Categories', items: _topCategories, nameKey: 'category_name'),
          const SizedBox(height: 16),
          _TopSection(title: 'Top Merchants', items: _topMerchants, nameKey: 'merchant_name'),
          const SizedBox(height: 16),
          _TopSection(title: 'Top Accounts', items: _topAccounts, nameKey: 'account_name'),
          const SizedBox(height: 16),
          _TopSection(title: 'Top Expense Purposes', items: _topPurposes, nameKey: 'expense_for'),
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
  final String? subLabel;
  const _MiniInsightCard({required this.label, required this.value, required this.color, required this.icon, this.subLabel});

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
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(subLabel!, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]
        ],
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String nameKey;
  const _TopSection({required this.title, required this.items, required this.nameKey});

  @override
  Widget build(BuildContext context) {
    final maxVal = items.isNotEmpty ? (items.first['total'] as num).toDouble() : 1.0;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No data', style: TextStyle(color: AppColors.textMuted))
          else
            ...items.map((item) {
              final name = item[nameKey] as String? ?? '—';
              final total = (item['total'] as num).toDouble();
              final icon = item['icon'] as String?;
              final color = item['icon_color'] as String?;
              final fraction = maxVal > 0 ? total / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ColorHelper.fromHex(color).withValues(alpha: 0.15),
                    child: Icon(IconHelper.getIcon(icon), size: 16, color: ColorHelper.fromHex(color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                      Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: fraction, minHeight: 5, backgroundColor: AppColors.surfaceContainer, color: ColorHelper.fromHex(color)),
                    ),
                  ])),
                ]),
              );
            }),
        ],
      ),
    );
  }
}
