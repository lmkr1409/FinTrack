import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/dashboard/screens/insights_screen.dart';
import '../features/labeling/screens/label_screen.dart';
import '../features/settings/screens/configuration_screen.dart';
import '../features/settings/screens/export_import_screen.dart';
import '../features/transactions/screens/transactions_screen.dart';

/// Root widget: Material 3 Navigation Drawer with themed gradient header.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _titles = ['Insights', 'Configuration', 'Transactions', 'Label', 'Backup & Restore'];
  static const _screens = <Widget>[
    InsightsScreen(),
    ConfigurationScreen(),
    TransactionsScreen(),
    LabelScreen(),
    ExportImportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context); // close drawer
        },
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 36, color: Colors.white),
                SizedBox(height: 10),
                Text('FinTrack', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Personal Finance Tracker', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const NavigationDrawerDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: Text('Insights'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Configuration'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: Text('Transactions'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.label_important_outline_rounded),
            selectedIcon: Icon(Icons.label_important_rounded),
            label: Text('Label'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.backup_outlined),
            selectedIcon: Icon(Icons.backup),
            label: Text('Backup & Restore'),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
    );
  }
}
