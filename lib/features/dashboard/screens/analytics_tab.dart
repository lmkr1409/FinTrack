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

/// Analytics tab — visual charts (bar, pie) for expense breakdowns.
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

enum PieChartGrouping { category, paymentMethod, account, card, purpose }

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  
  List<Map<String, dynamic>> _dailyTrend = [];
  
  PieChartGrouping _pieChartGrouping = PieChartGrouping.category;
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categoryList = [];
  List<Map<String, dynamic>> _pieChartData = [];
  
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
    final monthStart = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
    final monthEnd = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
    
    _dailyTrend = await _analytics.expensePerDay(monthStart, monthEnd);
    
    // Always fetch category breakdown for the drill-down dropdown (when grouping is category)
    _categoryList = await _analytics.expensesByCategory(monthStart, monthEnd);

    switch (_pieChartGrouping) {
      case PieChartGrouping.category:
        if (_selectedCategoryId != null) {
          _pieChartData = await _analytics.expensesBySubCategory(monthStart, monthEnd, _selectedCategoryId!);
        } else {
          _pieChartData = _categoryList;
        }
        break;
      case PieChartGrouping.paymentMethod:
        _pieChartData = await _analytics.expensesByPaymentMethod(monthStart, monthEnd);
        break;
      case PieChartGrouping.account:
        _pieChartData = await _analytics.expensesByAccount(monthStart, monthEnd);
        break;
      case PieChartGrouping.card:
        _pieChartData = await _analytics.expensesByCard(monthStart, monthEnd);
        break;
      case PieChartGrouping.purpose:
        _pieChartData = await _analytics.expensesByPurpose(monthStart, monthEnd);
        break;
    }
    
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
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
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
          // Header Row with Dropdowns
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
              // Subcategory Drill-down (only if Category is selected and we have categories)
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
