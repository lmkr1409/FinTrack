import 'package:flutter/material.dart';

import 'analytics_tab.dart';
import 'budgets_tab.dart';
import 'dashboards_tab.dart';
import 'insights_summary_tab.dart';
import 'trends_tab.dart';

/// The Insights section with a 5-tab Bottom Navigation Bar.
/// Tabs: Dashboards, Budgets, Analytics, Trends, Insights.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    DashboardsTab(),
    BudgetsTab(),
    AnalyticsTab(),
    TrendsTab(),
    InsightsSummaryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboards',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Breakdowns',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outlined),
            selectedIcon: Icon(Icons.lightbulb_rounded),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
