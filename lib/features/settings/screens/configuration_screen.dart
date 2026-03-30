import 'package:flutter/material.dart';

import '../../../features/categories/screens/categories_tab.dart';
import 'accounts_payments_tab.dart';
import 'planner_settings_tab.dart';
import 'purpose_source_tab.dart';
import 'merchants_tab.dart';

/// Configuration section with a 5-tab Bottom Navigation Bar.
class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    CategoriesTab(),
    PlannerSettingsTab(),
    AccountsPaymentsTab(),
    PurposeSourceTab(),
    MerchantsTab(),
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
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.next_plan_outlined),
            selectedIcon: Icon(Icons.next_plan_rounded),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks_rounded),
            label: 'Tags',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded),
            label: 'Merchants',
          ),
        ],
      ),
    );
  }
}
