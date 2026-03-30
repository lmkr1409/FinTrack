import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'App Guide & Help',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn how to get the most out of FinTrack.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          _buildHelpSection(
            context,
            icon: Icons.sms_rounded,
            title: 'Smart SMS Sync',
            description: 'FinTrack automatically reads your banking SMS to track your spending in real-time. It looks for keywords like "debited", "credited", and transaction amounts to build your history.',
            color: AppColors.primary,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.label_rounded,
            title: 'Manual Labeling',
            description: 'Initially, some transactions may be unlabeled. Tap on any unlabeled transaction in the "Transactions" tab to set its category, sub-category, and merchant. This helps the app understand your spending patterns.',
            color: Colors.orange,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.psychology_rounded,
            title: 'Automatic Rules',
            description: 'Every time you label a transaction, FinTrack automatically learns and creates a "Rule". In the future, similar transactions will be categorized automatically without your intervention. You can manage these in the "Labeling Rules" section.',
            color: Colors.purple,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.insights_rounded,
            title: 'Powerful Insights',
            description: 'The Insights tab provides a comprehensive view of your finances. You can see your spending trends over the last year, monitor your budgets, and see a breakdown of your top spending categories and merchants.',
            color: AppColors.income,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.backup_rounded,
            title: 'Data Privacy & Backup',
            description: 'Your data stays on your device. We never upload your financial information to any server. You can export your data to a JSON file for your own backups via the "Backup & Restore" screen.',
            color: Colors.blue,
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'FinTrack v1.0.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
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
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
