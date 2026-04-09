import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';

class GoalsProgressTab extends StatefulWidget {
  final DateTime selectedMonth;
  const GoalsProgressTab({super.key, required this.selectedMonth});

  @override
  State<GoalsProgressTab> createState() => _GoalsProgressTabState();
}

class _GoalsProgressTabState extends State<GoalsProgressTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  List<Map<String, dynamic>> _goalsData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(GoalsProgressTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final data = await _analytics.getGoalProgress(widget.selectedMonth.month, widget.selectedMonth.year);
    
    if (!mounted) return;
    setState(() {
      _goalsData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_goalsData.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: const Center(
              child: Text(
                'No active investment goals.\nAdd them in Settings > Planner.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _goalsData.length,
        itemBuilder: (context, i) {
          final g = _goalsData[i];
          final goalName = g['goal_name'] as String;
          final targetAmount = (g['target_amount'] as num).toDouble();
          final savedAmount = (g['saved_amount'] as num).toDouble();
          
          final icon = g['icon'] as String? ?? 'star';
          final iconColor = g['icon_color'] as String? ?? '#FF9800';
          
          final categoryName = g['category_name'] as String? ?? 'Investment';

          final progressRaw = targetAmount > 0 ? (savedAmount / targetAmount) : 0.0;
          final progress = progressRaw.clamp(0.0, 1.0);
          final isCompleted = savedAmount >= targetAmount && targetAmount > 0;

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: ColorHelper.fromHex(iconColor).withValues(alpha: 0.2),
                        child: Icon(IconHelper.getIcon(icon), color: ColorHelper.fromHex(iconColor)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(categoryName, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle_rounded, color: AppColors.income),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${(progressRaw * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.income : Colors.amberAccent,
                        ),
                      ),
                      Text(
                        '₹${savedAmount.toStringAsFixed(0)} / ₹${targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      color: isCompleted ? AppColors.income : Colors.amberAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
