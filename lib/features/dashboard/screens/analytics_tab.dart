import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/glass_card.dart';

/// Analytics tab — Top spends with glassmorphic cards and accent-colored bars.
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _topMerchants = [];
  List<Map<String, dynamic>> _topAccounts = [];
  List<Map<String, dynamic>> _topPurposes = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
    _topCategories = await _analytics.topCategories(start, end);
    _topMerchants = await _analytics.topMerchants(start, end);
    _topAccounts = await _analytics.topAccounts(start, end);
    _topPurposes = await _analytics.topPurposes(start, end);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            Text('No data', style: TextStyle(color: AppColors.textMuted))
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
