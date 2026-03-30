import 'package:flutter/material.dart';

import 'budgets_tab.dart';
import 'goals_progress_tab.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  int _selectedIndex = 0;

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
                  ButtonSegment(value: 0, label: Text('Expenses'), icon: Icon(Icons.money_off_csred_rounded)),
                  ButtonSegment(value: 1, label: Text('Goals'), icon: Icon(Icons.star_rounded)),
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
                child: _selectedIndex == 0 
                  ? const BudgetsTab(key: ValueKey('budget')) 
                  : const GoalsProgressTab(key: ValueKey('goal')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
