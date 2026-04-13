import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../services/providers.dart';
import 'filter_selection_screen.dart';
import 'lock_screen.dart';
import '../../../services/security_service.dart';
import '../../../services/providers.dart' show demoModeProvider;

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _loading = true;
  bool _canCheckBiometrics = false;
  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(generalSettingsRepositoryProvider);
    final settings = await repo.getAllSettings();
    final canBiometric = await ref.read(securityServiceProvider).canCheckBiometrics();
    setState(() {
      _settings = settings;
      _canCheckBiometrics = canBiometric;
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

  Widget _buildSecuritySettings() {
    final security = ref.read(securityServiceProvider);
    final isLockEnabled = _settings['security_lock_enabled'] == 'true';
    final authMethodStr = _settings['security_auth_method'] ?? 'none';
    final isDemoMode = ref.watch(demoModeProvider).valueOrNull ?? false;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.security_rounded, color: AppColors.primary),
        title: const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isLockEnabled ? 'App lock is ACTIVE' : 'App lock is disabled',
          style: TextStyle(
            fontSize: 11,
            color: isLockEnabled ? AppColors.income : AppColors.textMuted,
          ),
        ),
        children: [
          SwitchListTile(
            title: const Text('Enable App Lock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Required in Release mode only', style: TextStyle(fontSize: 11)),
            value: isLockEnabled,
            onChanged: (val) async {
              if (val) {
                // If enabling, show selection dialog IF no method is set or if we want to give choice
                final selectedMethod = await _showMethodSelectionDialog();
                if (selectedMethod != null) {
                  await security.setLockEnabled(true);
                  await _updateSetting('security_lock_enabled', 'true');
                  _changeAuthMethod(selectedMethod);
                }
              } else {
                await security.setLockEnabled(false);
                await _updateSetting('security_lock_enabled', 'false');
              }
            },
          ),
          if (isLockEnabled) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: const Text('Authentication Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              trailing: DropdownButton<AuthMethod>(
                value: AuthMethod.values.firstWhere((e) => e.name == authMethodStr, orElse: () => AuthMethod.none),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: AuthMethod.pin, child: Text('PIN (6-digit)', style: TextStyle(fontSize: 12))),
                  const DropdownMenuItem(value: AuthMethod.pattern, child: Text('Pattern', style: TextStyle(fontSize: 12))),
                  if (_canCheckBiometrics)
                    const DropdownMenuItem(value: AuthMethod.fingerprint, child: Text('Biometrics', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _changeAuthMethod(val);
                  }
                },
              ),
            ),
            if (authMethodStr == 'pin')
              ListTile(
                title: const Text('Change PIN', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: _setupPin,
              ),
            if (authMethodStr == 'pattern')
              ListTile(
                title: const Text('Change Pattern', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: _setupPattern,
              ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: const Text('Auto-lock Delay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Wait before requiring re-auth', style: TextStyle(fontSize: 11)),
              trailing: DropdownButton<int>(
                value: int.tryParse(_settings['security_lock_timeout'] ?? '180') ?? 180,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Immediately', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 30, child: Text('30 seconds', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 60, child: Text('1 minute', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 180, child: Text('3 minutes', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 300, child: Text('5 minutes', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 600, child: Text('10 minutes', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateSetting('security_lock_timeout', val.toString());
                  }
                },
              ),
            ),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Hide Details Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Mask currency values during presentations', style: TextStyle(fontSize: 11)),
            secondary: Icon(
              isDemoMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isDemoMode ? AppColors.primary : AppColors.textMuted,
            ),
            value: isDemoMode,
            onChanged: (val) {
              ref.read(demoModeProvider.notifier).set(val);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _changeAuthMethod(AuthMethod method) async {
    final security = ref.read(securityServiceProvider);
    await security.setAuthMethod(method);
    await _updateSetting('security_auth_method', method.name);
    
    if (method == AuthMethod.pin) {
      _setupPin();
    } else if (method == AuthMethod.pattern) {
      _setupPattern();
    }
  }

  void _setupPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreen(
          mode: LockScreenMode.setup,
          method: AuthMethod.pin,
          onSetupComplete: (pin) async {
            await ref.read(securityServiceProvider).savePin(pin);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN updated successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  void _setupPattern() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreen(
          mode: LockScreenMode.setup,
          method: AuthMethod.pattern,
          onPatternSetupComplete: (pattern) async {
            await ref.read(securityServiceProvider).savePattern(pattern);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pattern updated successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGeneralSettings(),
        const SizedBox(height: 16),
        _buildSecuritySettings(),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildIncomeSettingGroup(
            'Financial Flow Inflow',
            salaryKey: 'flow_salary_mode',
            otherKey: 'flow_other_mode',
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
        key: 'financial_flow',
        name: 'Financial Flow Summary',
        description: 'High-level Inflow and Outflow cards (Net Balance).',
        icon: Icons.swap_vert_rounded,
      ),
      _WidgetInfo(
        key: 'spending_insights',
        name: 'Detailed Spending Insights',
        description:
            'Total Expenses, Daily Spend, Trend, and Largest Expense.',
        icon: Icons.insights_rounded,
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

  Future<AuthMethod?> _showMethodSelectionDialog() async {
    return showDialog<AuthMethod>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Authentication Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
              title: const Text('PIN (6-digit)'),
              onTap: () => Navigator.pop(ctx, AuthMethod.pin),
            ),
            ListTile(
              leading: const Icon(Icons.gesture_rounded, color: AppColors.secondary),
              title: const Text('Pattern'),
              onTap: () => Navigator.pop(ctx, AuthMethod.pattern),
            ),
            if (_canCheckBiometrics)
              ListTile(
                leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                title: const Text('Biometrics'),
                onTap: () => Navigator.pop(ctx, AuthMethod.fingerprint),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
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
