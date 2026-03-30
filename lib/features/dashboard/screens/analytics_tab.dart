import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/icon_helper.dart';

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

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _analytics = AnalyticsService();
  bool _loading = true;
  
  List<Map<String, dynamic>> _topCategories = [];
  List<Map<String, dynamic>> _topMerchants = [];
  List<Map<String, dynamic>> _topAccounts = [];
  List<Map<String, dynamic>> _topCards = [];
  List<Map<String, dynamic>> _topPurposes = [];
  
  int _limitCategories = 5;
  int _limitMerchants = 5;
  int _limitAccounts = 5;
  int _limitCards = 5;
  int _limitPurposes = 5;
  
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
    
    final cats = await _analytics.topCategories(monthStart, monthEnd, limit: _limitCategories);
    final merchs = await _analytics.topMerchants(monthStart, monthEnd, limit: _limitMerchants);
    final accs = await _analytics.topAccounts(monthStart, monthEnd, limit: _limitAccounts);
    final cards = await _analytics.topCards(monthStart, monthEnd, limit: _limitCards);
    final purps = await _analytics.topPurposes(monthStart, monthEnd, limit: _limitPurposes);
    
    setState(() {
      _topCategories = cats;
      _topMerchants = merchs;
      _topAccounts = accs;
      _topCards = cards;
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
    // Only show full-screen loader if no data exists and we are loading
    final hasNoData = _topCategories.isEmpty && _topMerchants.isEmpty && _topAccounts.isEmpty && _topCards.isEmpty && _topPurposes.isEmpty;
    if (_loading && hasNoData) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _TopSection(
            title: 'Top Categories',
            items: _topCategories,
            nameKey: 'category_name',
            limit: _limitCategories,
            onMore: _limitCategories < 20 ? () {
              setState(() => _limitCategories += 5);
              _loadData();
            } : null,
            onLess: _limitCategories > 5 ? () {
              setState(() => _limitCategories -= 5);
              _loadData();
            } : null,
          ),
          const SizedBox(height: 16),
          _TopSection(
            title: 'Top Merchants',
            items: _topMerchants,
            nameKey: 'merchant_name',
            limit: _limitMerchants,
            onMore: _limitMerchants < 20 ? () {
              setState(() => _limitMerchants += 5);
              _loadData();
            } : null,
            onLess: _limitMerchants > 5 ? () {
              setState(() => _limitMerchants -= 5);
              _loadData();
            } : null,
          ),
          const SizedBox(height: 16),
          _TopSection(
            title: 'Top Accounts',
            items: _topAccounts,
            nameKey: 'account_name',
            limit: _limitAccounts,
            onMore: _limitAccounts < 20 ? () {
              setState(() => _limitAccounts += 5);
              _loadData();
            } : null,
            onLess: _limitAccounts > 5 ? () {
              setState(() => _limitAccounts -= 5);
              _loadData();
            } : null,
          ),
          const SizedBox(height: 16),
          _TopSection(
            title: 'Top Cards',
            items: _topCards,
            nameKey: 'card_name',
            limit: _limitCards,
            onMore: _limitCards < 20 ? () {
              setState(() => _limitCards += 5);
              _loadData();
            } : null,
            onLess: _limitCards > 5 ? () {
              setState(() => _limitCards -= 5);
              _loadData();
            } : null,
          ),
          const SizedBox(height: 16),
          _TopSection(
            title: 'Top Expense Purposes',
            items: _topPurposes,
            nameKey: 'expense_for',
            limit: _limitPurposes,
            onMore: _limitPurposes < 20 ? () {
              setState(() => _limitPurposes += 5);
              _loadData();
            } : null,
            onLess: _limitPurposes > 5 ? () {
              setState(() => _limitPurposes -= 5);
              _loadData();
            } : null,
          ),
            ],
          ),
        ),
        if (_loading)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class _TopSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String nameKey;
  final int limit;
  final VoidCallback? onMore;
  final VoidCallback? onLess;

  const _TopSection({
    required this.title,
    required this.items,
    required this.nameKey,
    required this.limit,
    this.onMore,
    this.onLess,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = items.isNotEmpty
        ? (items.first['total'] as num).toDouble()
        : 1.0;
    
    // Only show "More" if we actually got as many items as we asked for (implying there might be more)
    final canShowMore = onMore != null && items.length == limit;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onLess != null)
                    _CompactButton(
                      icon: Icons.remove,
                      onTap: onLess!,
                      tooltip: 'Show Less',
                    ),
                  if (canShowMore) ...[
                    const SizedBox(width: 8),
                    _CompactButton(
                      icon: Icons.add,
                      onTap: onMore!,
                      tooltip: 'Show More',
                    ),
                  ],
                ],
              ),
            ],
          ),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: ColorHelper.fromHex(
                        color,
                      ).withValues(alpha: 0.15),
                      child: Icon(
                        IconHelper.getIcon(icon),
                        size: 16,
                        color: ColorHelper.fromHex(color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 5,
                              backgroundColor: AppColors.surfaceContainer,
                              color: ColorHelper.fromHex(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _CompactButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
