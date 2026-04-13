import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/account_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/card_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/expense_purpose_repository.dart';
import '../repositories/expense_source_repository.dart';
import '../repositories/merchant_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/sub_category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/merchant_rule_repository.dart';
import '../repositories/transaction_rule_repository.dart';
import '../repositories/labeling_rule_repository.dart';
import '../repositories/budget_total_repository.dart';
import '../repositories/investment_goal_repository.dart';
import '../repositories/strategy_repository.dart';
import '../repositories/widget_filter_repository.dart';
import '../repositories/general_settings_repository.dart';
import 'analytics_service.dart';
import 'security_service.dart';

// ─── Repository Providers ────────────────────────────────────────────

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final subCategoryRepositoryProvider = Provider<SubCategoryRepository>((ref) {
  return SubCategoryRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepository();
});

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  return PaymentMethodRepository();
});

final expenseSourceRepositoryProvider = Provider<ExpenseSourceRepository>((ref) {
  return ExpenseSourceRepository();
});

final expensePurposeRepositoryProvider = Provider<ExpensePurposeRepository>((ref) {
  return ExpensePurposeRepository();
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final merchantRuleRepositoryProvider = Provider<MerchantRuleRepository>((ref) {
  return MerchantRuleRepository();
});

final transactionRuleRepositoryProvider = Provider<TransactionRuleRepository>((ref) {
  return TransactionRuleRepository();
});

final labelingRuleRepositoryProvider = Provider<LabelingRuleRepository>((ref) {
  return LabelingRuleRepository();
});

final budgetTotalRepositoryProvider = Provider<BudgetTotalRepository>((ref) {
  return BudgetTotalRepository();
});

final investmentGoalRepositoryProvider = Provider<InvestmentGoalRepository>((ref) {
  return InvestmentGoalRepository();
});

final strategyRepositoryProvider = Provider<StrategyRepository>((ref) {
  return StrategyRepository();
});

final widgetFilterRepositoryProvider = Provider<WidgetFilterRepository>((ref) {
  return WidgetFilterRepository();
});

final generalSettingsRepositoryProvider = Provider<GeneralSettingsRepository>((ref) {
  return GeneralSettingsRepository();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.read(generalSettingsRepositoryProvider));
});

// ─── Demo Mode Provider ───────────────────────────────────────────────────────

class DemoModeNotifier extends AsyncNotifier<bool> {
  static const _key = 'demo_mode_enabled';

  @override
  Future<bool> build() async {
    final repo = ref.read(generalSettingsRepositoryProvider);
    final val = await repo.getSetting(_key);
    return val == 'true';
  }

  Future<void> toggle() async {
    final current = await future;
    final next = !current;
    final repo = ref.read(generalSettingsRepositoryProvider);
    await repo.setSetting(_key, next.toString());
    state = AsyncData(next);
  }

  Future<void> set(bool value) async {
    final repo = ref.read(generalSettingsRepositoryProvider);
    await repo.setSetting(_key, value.toString());
    state = AsyncData(value);
  }
}

/// Reactive demo-mode flag. Watch this to conditionally mask financial values.
final demoModeProvider = AsyncNotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);
