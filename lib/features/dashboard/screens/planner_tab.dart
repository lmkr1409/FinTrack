import 'package:flutter/material.dart';

import 'budgets_tab.dart';
import 'goals_progress_tab.dart';
import 'strategy_tab.dart';
import '../../../widgets/month_swiper.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  int _selectedIndex = 0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              child: MonthSwiper(
                currentMonth: _selectedMonth,
                onMonthChanged: (newMonth) {
                  setState(() => _selectedMonth = newMonth);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildSelectedTab(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return StrategyTab(
          key: const ValueKey('strategy'),
          selectedMonth: _selectedMonth,
        );
      case 1:
        return BudgetsTab(
          key: const ValueKey('budget'),
          selectedMonth: _selectedMonth,
        );
      case 2:
        return GoalsProgressTab(
          key: const ValueKey('goal'),
          selectedMonth: _selectedMonth,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
