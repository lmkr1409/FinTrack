import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../services/providers.dart';
import 'filter_selection_screen.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _loading = true;
  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(generalSettingsRepositoryProvider);
    final settings = await repo.getAllSettings();
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _updateSetting(String key, String value) async {
    final repo = ref.read(generalSettingsRepositoryProvider);
    await repo.setSetting(key, value);
    setState(() {
      _settings[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGeneralSettings(),
        const SizedBox(height: 16),
        _buildWidgetSettings(),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        leading: const Icon(
          Icons.settings_suggest_rounded,
          color: AppColors.primary,
        ),
        title: const Text(
          'Income Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          _buildIncomeSettingGroup(
            'Budget Planner Income',
            salaryKey: 'budget_salary_mode',
            otherKey: 'budget_other_mode',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildIncomeSettingGroup(
            'Strategy Planner Income',
            salaryKey: 'strategy_salary_mode',
            otherKey: 'strategy_other_mode',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildIncomeSettingGroup(
            'Income Allocation Widget',
            salaryKey: 'allocation_salary_mode',
            otherKey: 'allocation_other_mode',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIncomeSettingGroup(
    String title, {
    required String salaryKey,
    required String otherKey,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSourceSelector('Salary derived from:', salaryKey),
          const SizedBox(height: 8),
          _buildSourceSelector('Other Income derived from:', otherKey),
        ],
      ),
    );
  }

  Widget _buildSourceSelector(String label, String key) {
    final currentValue = _settings[key] ?? 'CURRENT';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        DropdownButton<_ValueOption>(
          value: currentValue == 'PREV'
              ? _ValueOption.prev
              : _ValueOption.current,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(
              value: _ValueOption.prev,
              child: Text('Prev Month', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: _ValueOption.current,
              child: Text('Current Month', style: TextStyle(fontSize: 12)),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              _updateSetting(
                key,
                val == _ValueOption.prev ? 'PREV' : 'CURRENT',
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWidgetSettings() {
    final widgets = [
      _WidgetInfo(
        key: 'financial_summary',
        name: 'Financial Summary',
        description:
            'Total Income, Expense, Net Balance, and Daily Spend cards.',
        icon: Icons.summarize_rounded,
      ),
      _WidgetInfo(
        key: 'daily_heatmap',
        name: 'Daily Spend Heatmap',
        description: 'The calendar heatmap showing daily spending intensity.',
        icon: Icons.calendar_view_month_rounded,
      ),
      _WidgetInfo(
        key: 'expense_breakdown',
        name: 'Expense Breakdown',
        description: 'Main Expense Pie Chart and category breakdown lists.',
        icon: Icons.pie_chart_rounded,
      ),
      _WidgetInfo(
        key: 'investment_breakdown',
        name: 'Investment Breakdown',
        description: 'Pie Chart and breakdown specifically for investments.',
        icon: Icons.trending_up_rounded,
      ),
      _WidgetInfo(
        key: 'income_allocation',
        name: 'Income Allocation',
        description:
            'Allocation bar showing split between Expenses, Investments, and Savings.',
        icon: Icons.align_horizontal_left_rounded,
      ),
      _WidgetInfo(
        key: 'budget_tracker',
        name: 'Budget Tracker',
        description: 'Actual spending calculation for category-wise budgets.',
        icon: Icons.track_changes_rounded,
      ),
      _WidgetInfo(
        key: 'monthly_trends',
        name: 'Monthly Trends',
        description: 'Income vs Expense bar charts for the last 12 months.',
        icon: Icons.bar_chart_rounded,
      ),
      _WidgetInfo(
        key: 'strategic_planner',
        name: 'Strategic Progress',
        description:
            'Actuals calculated for 50/30/20 buckets and strategy frameworks.',
        icon: Icons.insights_rounded,
      ),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.widgets_rounded, color: AppColors.primary),
        title: const Text(
          'Widget Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: widgets
            .map(
              (w) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(w.icon, color: AppColors.primary, size: 20),
                title: Text(
                  w.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  w.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilterSelectionScreen(
                        widgetKey: w.key,
                        widgetName: w.name,
                      ),
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

enum _ValueOption { prev, current }

class _WidgetInfo {
  final String key;
  final String name;
  final String description;
  final IconData icon;

  _WidgetInfo({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
  });
}
