import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

import 'app_tour_screen.dart';
import '../../labeling/screens/labeling_rules_screen.dart';
import '../../settings/screens/accounts_payments_tab.dart';
import '../../categories/screens/categories_tab.dart';
import '../../settings/screens/planner_settings_tab.dart';
import '../../settings/screens/settings_tab.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _teleport(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Guide & Setup',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Master the features of FinTrack.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
                color: AppColors.primary,
                tooltip: 'Replay App Tour',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppTourScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildHeader('Setup Checklist'),
          const SizedBox(height: 16),
          
          _buildActionSection(
            context,
            icon: Icons.sms_rounded,
            title: '1. Verify Bank Senders',
            description: 'Check if your bank is listed. If missing, add its SMS sender ID (e.g., AD-HDFCBK).',
            color: Colors.blueAccent,
            onAction: () => _teleport(context, 'Bank Senders', const LabelingRulesScreen()),
          ),
          
          _buildActionSection(
            context,
            icon: Icons.account_balance_rounded,
            title: '2. Accounts & Cards',
            description: 'Add your Bank Accounts and link your Credit Cards to track transaction sources.',
            color: Colors.greenAccent,
            onAction: () => _teleport(context, 'Accounts & Cards', const AccountsPaymentsTab()),
          ),
          
          _buildActionSection(
            context,
            icon: Icons.category_rounded,
            title: '3. Categories',
            description: 'Review the default expense and investment categories or create your own.',
            color: Colors.purpleAccent,
            onAction: () => _teleport(context, 'Categories', const CategoriesTab()),
          ),
          
          _buildActionSection(
            context,
            icon: Icons.pie_chart_rounded,
            title: '4. Budgets',
            description: 'Select a budget framework (like 50/30/20) and assign your categories to buckets.',
            color: Colors.orangeAccent,
            onAction: () => _teleport(context, 'Budget Planner', const PlannerSettingsTab()),
          ),
          
          _buildActionSection(
            context,
            icon: Icons.settings_rounded,
            title: '5. App Settings',
            description: 'Enable Privacy mode, App Lock, adjust widgets, and change themes.',
            color: AppColors.primary,
            onAction: () => _teleport(context, 'Settings', const SettingsTab()),
          ),

          const SizedBox(height: 24),
          _buildHeader('General Help'),
          const SizedBox(height: 16),
          
          _buildInfoSection(
            icon: Icons.receipt_long_rounded,
            title: 'Labeling Transactions',
            description: 'When a new transaction arrives, assign it a Merchant and Category. FinTrack will create a Merchant Rule and automatically label future payments to that merchant!',
            color: Colors.redAccent,
          ),
          
          _buildInfoSection(
            icon: Icons.insights_rounded,
            title: 'Insights & Analytics',
            description: 'The Insights tab provides a view of your finances. Analyze spending trends, monitor budgets, and see a breakdown of your top categories.',
            color: AppColors.income,
          ),

          const SizedBox(height: 48),
          const Center(
            child: Text(
              'FinTrack v1.1.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onAction,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Take Me There'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
