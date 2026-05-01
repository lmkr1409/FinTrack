import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import '../../labeling/screens/labeling_rules_screen.dart';
import '../../settings/screens/accounts_payments_tab.dart';
import '../../categories/screens/categories_tab.dart';
import '../../settings/screens/planner_settings_tab.dart';
import '../../settings/screens/settings_tab.dart';
import '../../labeling/screens/label_screen.dart';
import '../../dashboard/screens/insights_screen.dart';

class TourStep {
  final String title;
  final String instruction;
  final Widget liveWidget;
  final IconData icon;

  TourStep({
    required this.title,
    required this.instruction,
    required this.liveWidget,
    required this.icon,
  });
}

class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<TourStep> _tourSteps;

  @override
  void initState() {
    super.initState();
    _tourSteps = [
      TourStep(
        title: 'SMS Mapping',
        instruction: 'If your bank SMS does not sync automatically, map its sender ID (like AD-HDFCBK) here to ensure FinTrack captures it.',
        liveWidget: const LabelingRulesScreen(),
        icon: Icons.sms_rounded,
      ),
      TourStep(
        title: 'Financial Sources',
        instruction: 'Add your Bank Accounts and link your Credit Cards. This allows the app to track which account was used mechanically.',
        liveWidget: const AccountsPaymentsTab(),
        icon: Icons.account_balance_wallet_rounded,
      ),
      TourStep(
        title: 'Categorization',
        instruction: 'Review or modify the default categories. You can edit icons or add custom subcategories tailored to your expenses.',
        liveWidget: const CategoriesTab(),
        icon: Icons.category_rounded,
      ),
      TourStep(
        title: 'Budgeting',
        instruction: 'Choose a budget strategy (like 50/30/20) and assign your categories into buckets to track your spending limits.',
        liveWidget: const PlannerSettingsTab(),
        icon: Icons.pie_chart_rounded,
      ),
      TourStep(
        title: 'App Preferences',
        instruction: 'Customize your dashboard widgets, enable Privacy mode, set up an App Lock, or change your visual theme.',
        liveWidget: const SettingsTab(),
        icon: Icons.settings_rounded,
      ),
      TourStep(
        title: 'Transactions & Labeling',
        instruction: 'When SMS arrive, they appear here. Swipe to approve or label them. You can split amounts or mark them as ignored.',
        liveWidget: const LabelScreen(),
        icon: Icons.receipt_long_rounded,
      ),
      TourStep(
        title: 'Merchant Rules',
        instruction: 'When you label a transaction for a new merchant, a rule is dynamically created here. FinTrack will automatically apply this rule to future payments to the same merchant!',
        liveWidget: const LabelingRulesScreen(), // User will manually toggle to merchants segment if they want, but the screen handles both
        icon: Icons.storefront_rounded,
      ),
      TourStep(
        title: 'Insights & Analytics',
        instruction: 'Once labeled, all your data converges here. Analyze spending trends, visual breakdowns, and your overall cash flow!',
        liveWidget: const InsightsScreen(),
        icon: Icons.insights_rounded,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tourSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _tourSteps[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Setup: Component ${_currentPage + 1} of ${_tourSteps.length}'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Exit Setup', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: Column(
        children: [
          // The Live Interactive Screen
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Force user to use next/prev buttons to avoid accidental swipes during live config
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _tourSteps.length,
              itemBuilder: (context, index) {
                // Return the live widget but wrapped in a dark container background for contrast if needed
                return Container(
                  color: AppColors.surfaceDim,
                  child: _tourSteps[index].liveWidget,
                );
              },
            ),
          ),

          // The Guided Instruction Banner and Navigation Bottom Sheet
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              border: Border(top: BorderSide(color: AppColors.glassBorder)),
              boxShadow: [
                BoxShadow(color: Colors.black26, offset: Offset(0, -4), blurRadius: 16),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(step.icon, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.instruction,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? TextButton.icon(
                              onPressed: _prevPage,
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: const Text('Back Step'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                            )
                          : const SizedBox(width: 100), // Placeholder to keep layout balanced

                      // Pagination Dots
                      Row(
                        children: List.generate(
                          _tourSteps.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: _currentPage == index ? 20 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          _currentPage == _tourSteps.length - 1 ? 'Finish' : 'Next Step',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
