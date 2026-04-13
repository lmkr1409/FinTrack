import 'package:flutter/material.dart';

import 'budget_tab.dart';
import 'goal_tab.dart';
import 'strategy_settings_tab.dart';

class PlannerSettingsTab extends StatefulWidget {
  const PlannerSettingsTab({super.key});

  @override
  State<PlannerSettingsTab> createState() => _PlannerSettingsTabState();
}

class _PlannerSettingsTabState extends State<PlannerSettingsTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Strategy'),
                    icon: Icon(Icons.insights_rounded),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Budget'),
                    icon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Goals'),
                    icon: Icon(Icons.star_rounded),
                  ),
                ],
                selected: {_selectedIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedIndex = set.first);
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const StrategySettingsTab(key: ValueKey('strategy_settings'));
      case 1:
        return const BudgetTab(key: ValueKey('budget'));
      case 2:
        return const GoalTab(key: ValueKey('goal'));
      default:
        return const SizedBox.shrink();
    }
  }
}
