import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/strategy_models.dart';
import '../../../services/providers.dart';
import '../../../widgets/glass_card.dart';

class StrategyTab extends ConsumerStatefulWidget {
  final DateTime selectedMonth;
  const StrategyTab({super.key, required this.selectedMonth});

  @override
  ConsumerState<StrategyTab> createState() => _StrategyTabState();
}

class _StrategyTabState extends ConsumerState<StrategyTab> {
  bool _loading = true;
  List<BucketProgress> _progress = [];
  double _baseline = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(StrategyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final analytics = ref.read(analyticsServiceProvider);
    
    final progress = await analytics.getStrategyProgress(widget.selectedMonth);
    final baseline = await analytics.getStrategyBaseline(widget.selectedMonth);

    if (mounted) {
      setState(() {
        _progress = progress;
        _baseline = baseline;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_progress.isEmpty) {
      return const Center(child: Text('No strategy frameworks active.'));
    }

    final totalAllocated = _progress.fold(0.0, (sum, p) => sum + p.targetAmount);
    final remaining = _baseline - totalAllocated;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBaselineHeader(),
          const SizedBox(height: 16),
          ..._progress.map((p) => _buildBucketCard(p)),
          if (remaining.abs() > 1) _buildAllocationWarning(remaining),
          const SizedBox(height: 80), // Fab spacing
        ],
      ),
    );
  }

  Widget _buildBaselineHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Strategic Baseline (Salary)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹${_baseline.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Text('Targets below are calculated from this amount', style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          const Text('(Change workspace baseline in Settings)', style: TextStyle(color: Colors.white12, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBucketCard(BucketProgress p) {
    final isInvestment = p.bucket.bucketType == 'SAVED';
    final progressColor = isInvestment 
      ? (p.actualAmount >= p.targetAmount ? Colors.greenAccent : AppColors.primary)
      : (p.actualAmount > p.targetAmount ? AppColors.expense : Colors.greenAccent);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (p.bucket.iconColor != null 
                      ? Color(int.parse(p.bucket.iconColor!.replaceFirst('#', '0xFF'))) 
                      : AppColors.primary).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(p.bucket.icon),
                    size: 20,
                    color: p.bucket.iconColor != null 
                      ? Color(int.parse(p.bucket.iconColor!.replaceFirst('#', '0xFF'))) 
                      : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.bucket.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${p.bucket.percentage.toStringAsFixed(0)}% Allocation', 
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${p.actualAmount.toStringAsFixed(0)}', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: progressColor)),
                    Text('Target: ₹${p.targetAmount.toStringAsFixed(0)}', 
                      style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.targetAmount > 0 ? (p.actualAmount / p.targetAmount).clamp(0, 1) : 0,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isInvestment 
                    ? (p.actualAmount >= p.targetAmount ? 'Goal Achieved!' : '₹${(p.targetAmount - p.actualAmount).toStringAsFixed(0)} more to save')
                    : (p.actualAmount > p.targetAmount ? 'Overspent by ₹${(p.actualAmount - p.targetAmount).toStringAsFixed(0)}' : '₹${(p.targetAmount - p.actualAmount).toStringAsFixed(0)} remaining'),
                  style: TextStyle(fontSize: 10, color: progressColor.withOpacity(0.8)),
                ),
                Text('${(p.percentage * 100).toStringAsFixed(0)}%', 
                  style: TextStyle(fontSize: 10, color: progressColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationWarning(double remaining) {
    final isNegative = remaining < 0;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNegative ? AppColors.expense.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNegative ? AppColors.expense.withOpacity(0.3) : Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isNegative ? Icons.warning_rounded : Icons.info_outline_rounded, 
            color: isNegative ? AppColors.expense : Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNegative 
                ? 'Allocations exceed salary by ₹${(-remaining).toStringAsFixed(0)}' 
                : '₹${remaining.toStringAsFixed(0)} of salary is unallocated',
              style: TextStyle(fontSize: 12, color: isNegative ? AppColors.expense : Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'fact_check_rounded': return Icons.fact_check_rounded;
      case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'trending_up_rounded': return Icons.trending_up_rounded;
      case 'rocket_launch_rounded': return Icons.rocket_launch_rounded;
      case 'shield_rounded': return Icons.shield_rounded;
      case 'card_giftcard_rounded': return Icons.card_giftcard_rounded;
      default: return Icons.category_rounded;
    }
  }
}
