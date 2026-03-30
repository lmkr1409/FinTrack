import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';
import '../../../services/sms_listener_service.dart';
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
  
  String _sortMode = 'percent';
  bool _sortAscending = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _handleRefresh() async {
    final container = ProviderScope.containerOf(context);
    await SmsListenerService.syncInboxMessages(container);
    await _loadData(showLoading: false);
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);

    final data = await _analytics.budgetVsActual(_selectedMonth.month, _selectedMonth.year, categoryType: 'TRANSACTIONS');
    if (!mounted) return;
    setState(() {
      _budgets = data.where((b) => b['category_name']?.toString().toLowerCase() != 'income').toList();
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
    return Column(
      children: [
        // Budget List
        Expanded(
          child: Column(
            children: [
              _buildGlobalBudgetSummary(),
              Expanded(child: _buildBudgetGrid()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetGrid() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final budgetsWithoutGlobal = _budgets.where((b) => b['category_id'] != null).toList();

    if (budgetsWithoutGlobal.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: const Center(
                child: Text('No category budgets set for this month.', style: TextStyle(color: AppColors.textMuted))
              ),
            ),
          ],
        ),
      );
    }

    // Apply sorting
    final sortedBudgets = List<Map<String, dynamic>>.from(budgetsWithoutGlobal);
    sortedBudgets.sort((a, b) {
      final aBudget = (a['budget_amount'] as num).toDouble();
      final aActual = (a['actual'] as num).toDouble();
      final bBudget = (b['budget_amount'] as num).toDouble();
      final bActual = (b['actual'] as num).toDouble();

      final aPercent = aBudget > 0 ? aActual / aBudget : 0.0;
      final bPercent = bBudget > 0 ? bActual / bBudget : 0.0;

      if (_sortMode == 'percent') {
        return _sortAscending ? aPercent.compareTo(bPercent) : bPercent.compareTo(aPercent);
      } else { // 'amount'
        return _sortAscending ? aActual.compareTo(bActual) : bActual.compareTo(aActual);
      }
    });

    return Column(
      children: [
        _buildSortBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: sortedBudgets.length,
              itemBuilder: (context, index) {
                final b = sortedBudgets[index];
                final budgetM = (b['budget_amount'] as num).toDouble();
                final budgetA = (b['budget_amount_annual'] as num?)?.toDouble() ?? 0.0;
                final actual = (b['actual'] as num).toDouble();
                final catName = b['category_name'] as String? ?? 'All';
                
                final progressM = budgetM > 0 ? actual / budgetM : 0.0;
                final isOverM = actual > budgetM;
                final yearlyActual = (b['actual_annual'] as num?)?.toDouble() ?? actual;
                final hasAnnual = budgetA > 0;

                Color circleColor;
                if (progressM < 0.6) circleColor = Colors.greenAccent.shade700;
                else if (progressM < 0.85) circleColor = Colors.amber;
                else if (progressM <= 1.0) circleColor = Colors.orangeAccent;
                else circleColor = AppColors.expense;

                final yearlyProgress = budgetA > 0
                    ? (yearlyActual / budgetA).clamp(0.0, 1.5)
                    : 0.0;

                return GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        catName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _DoubleRingProgress(
                        size: 80,
                        outerProgress: yearlyProgress.clamp(0.0, 1.0),
                        innerProgress: progressM.clamp(0.0, 1.5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOverM ? 'OVER' : '${(progressM * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontWeight: FontWeight.bold, color: circleColor, fontSize: 12),
                            ),
                            if (hasAnnual)
                              Text(
                                '${(yearlyProgress * 100).toStringAsFixed(0)}%Y',
                                style: const TextStyle(fontSize: 9, color: Colors.white54),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${actual.toStringAsFixed(0)} / ₹${budgetM.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (hasAnnual) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Yearly: ₹${yearlyActual.toStringAsFixed(0)} / ₹${budgetA.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        isOverM
                          ? 'Over by ₹${(actual - budgetM).toStringAsFixed(0)}'
                          : '₹${(budgetM - actual).toStringAsFixed(0)} left',
                        style: TextStyle(
                          color: isOverM ? AppColors.expense : AppColors.income,
                          fontWeight: FontWeight.w600,
                          fontSize: 11
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Sort by: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          _buildSortChip('Completion %', 'percent'),
          const SizedBox(width: 8),
          _buildSortChip('Amount', 'amount'),
        ],
      ),
    );
  }

  Widget _buildGlobalBudgetSummary() {
    final globalEntry = _budgets.where((b) => b['category_id'] == null).firstOrNull;
    if (globalEntry == null) return const SizedBox.shrink();

    final budget = (globalEntry['budget_amount'] as num).toDouble();
    final actual = (globalEntry['actual'] as num).toDouble();
    final progress = budget > 0 ? (actual / budget).clamp(0, 1).toDouble() : 0.0;
    final isExceeded = actual > budget;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: isExceeded ? AppColors.expense.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
      borderColor: isExceeded ? AppColors.expense : AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('₹${actual.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceContainer,
                color: isExceeded ? AppColors.expense : Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExceeded ? 'Exceeded by ₹${(actual - budget).toStringAsFixed(0)}' : '₹${(budget - actual).toStringAsFixed(0)} remaining',
                  style: TextStyle(color: isExceeded ? AppColors.expense : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: isExceeded ? AppColors.expense : Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String mode) {
    final isSelected = _sortMode == mode;
    return ActionChip(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
          if (isSelected)
            Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: AppColors.primary),
        ],
      ),
      backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceContainer,
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
      onPressed: () {
        setState(() {
          if (_sortMode == mode) {
            _sortAscending = !_sortAscending;
          } else {
            _sortMode = mode;
            _sortAscending = false; // default to descending high-low
          }
        });
      },
    );
  }
}

// ─── Double-Ring Progress Widget ─────────────────────────────────────────
// Outer ring = Yearly budget progress  |  Inner ring = Monthly budget progress

class _DoubleRingProgress extends StatelessWidget {
  final double size;
  final double outerProgress; // yearly: [0..1]
  final double innerProgress; // monthly: [0..1.5 clamped]
  final Widget? child;

  const _DoubleRingProgress({
    required this.size,
    required this.outerProgress,
    required this.innerProgress,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoubleRingPainter(
          outerProgress: outerProgress,
          innerProgress: innerProgress,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DoubleRingPainter extends CustomPainter {
  final double outerProgress;
  final double innerProgress;

  _DoubleRingPainter({required this.outerProgress, required this.innerProgress});

  static Color _progressColor(double p) {
    if (p > 1.0) return Colors.redAccent;
    if (p > 0.85) return Colors.orangeAccent;
    if (p > 0.6) return Colors.amber;
    return Colors.greenAccent.shade700;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -math.pi / 2;

    // ── Outer ring: Yearly budget ──
    const outerStroke = 5.0;
    final outerR = (size.width / 2) - outerStroke / 2;
    final outerTrack = Rect.fromCircle(center: center, radius: outerR);
    final outerColor = _progressColor(outerProgress);

    canvas.drawArc(outerTrack, 0, 2 * math.pi, false,
      Paint()..color = outerColor.withValues(alpha: 0.15)
              ..strokeWidth = outerStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    if (outerProgress > 0) {
      canvas.drawArc(outerTrack, startAngle, 2 * math.pi * outerProgress.clamp(0.0, 1.0), false,
        Paint()..color = outerColor
                ..strokeWidth = outerStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    // ── Inner ring: Monthly budget ──
    const innerStroke = 4.0;
    const gap = 4.5;
    final innerR = outerR - outerStroke - gap;
    final innerTrack = Rect.fromCircle(center: center, radius: innerR);
    final innerColor = _progressColor(innerProgress);

    canvas.drawArc(innerTrack, 0, 2 * math.pi, false,
      Paint()..color = Colors.white.withValues(alpha: 0.08)
              ..strokeWidth = innerStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    if (innerProgress > 0) {
      canvas.drawArc(innerTrack, startAngle, 2 * math.pi * innerProgress.clamp(0.0, 1.0), false,
        Paint()..color = innerColor
                ..strokeWidth = innerStroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_DoubleRingPainter old) =>
      old.outerProgress != outerProgress || old.innerProgress != innerProgress;
}
