import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by the drawer/main layout
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          const Text(
            'App Guide & Help',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Master the features of FinTrack with this guide.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          
          _buildHeader('Getting Started'),
          const SizedBox(height: 16),
          
          _buildHelpSection(
            context,
            icon: Icons.sms_rounded,
            title: 'Bank Senders (SMS Sync)',
            description: 'FinTrack tracks your spending by reading banking SMS. \n\n• The app looks for alphanumeric senders (like XX-ABCBNK).\n• If your bank\'s SMS aren\'t appearing, go to Labeling Rules > Transaction Rules and add a "Bank Sender" rule with your bank\'s ID.',
            color: AppColors.primary,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.account_balance_rounded,
            title: 'Accounts & Cards',
            description: 'Source tracking starts with your accounts.\n\n• Create your Bank Accounts first.\n• Link your Credit/Debit cards to these accounts. \n• This allows the app to group transactions based on the account or card mentioned in your SMS.',
            color: Colors.blueAccent,
          ),

          const SizedBox(height: 24),
          _buildHeader('Automation & Rules'),
          const SizedBox(height: 16),
          
          _buildHelpSection(
            context,
            icon: Icons.settings_suggest_rounded,
            title: 'Transaction Rules',
            description: 'Teach the app how to identify the "How" of a payment.\n\n• Payment Method: Link keywords like "UPI" or "VISA" to a method.\n• Account/Card: Map "A/c XXXX" or "Card XX1234" to your created Accounts/Cards.\n• Transaction Type: Identify "Debited" as Expense and "Credited" as Income.',
            color: Colors.purpleAccent,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.store_rounded,
            title: 'Merchant Rules',
            description: 'Teach the app how to identify the "Who" of a payment.\n\n• When you label a transaction for the first time, look for a unique Merchant Keyword (e.g., from a UPI ID).\n• Linking this keyword to a Merchant, Category, and Purpose creates a Rule.\n• Future transactions from the same merchant will be labeled automatically!',
            color: Colors.orangeAccent,
          ),

          const SizedBox(height: 24),
          _buildHeader('Advanced Features'),
          const SizedBox(height: 16),
          
          _buildHelpSection(
            context,
            icon: Icons.insights_rounded,
            title: 'Insights & Trends',
            description: 'The Analytics tab provides a comprehensive view of your finances. Analyze your spending trends, monitor your budgets, and see a breakdown of your top categories and cards.',
            color: AppColors.income,
          ),
          
          _buildHelpSection(
            context,
            icon: Icons.backup_rounded,
            title: 'Data Privacy & Backup',
            description: 'All your financial data stays on your device. You can export your data to a JSON file for your own backups via the "Backup & Restore" screen in Settings.',
            color: AppColors.textMuted,
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

  Widget _buildHelpSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
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
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
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
