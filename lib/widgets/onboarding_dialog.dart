import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class OnboardingDialog extends StatelessWidget {
  const OnboardingDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const OnboardingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Welcome to FinTrack', style: TextStyle(color: AppColors.textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStep(
              Icons.sms_rounded,
              'Smart SMS Sync',
              'FinTrack automatically reads your banking SMS to track your spending in real-time.',
            ),
            _buildStep(
              Icons.label_rounded,
              'Manual Labeling',
              'Initially, some transactions may be unlabeled. Tap them to set a category and merchant/platform.',
            ),
            _buildStep(
              Icons.psychology_rounded,
              'Automatic Rules',
              'Once you label a transaction, FinTrack creates rules to automate future ones for you.',
            ),
            _buildStep(
              Icons.insights_rounded,
              'Powerful Insights',
              'Check the Insights tab to see your spending trends, budgets, and smart alerts.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Look for the "i" icons on any screen to learn more about what you\'re seeing.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Get Started', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStep(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
