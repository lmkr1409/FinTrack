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
import '../repositories/budget_total_repository.dart';
import '../repositories/investment_goal_repository.dart';

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

final budgetTotalRepositoryProvider = Provider<BudgetTotalRepository>((ref) {
  return BudgetTotalRepository();
});

final investmentGoalRepositoryProvider = Provider<InvestmentGoalRepository>((ref) {
  return InvestmentGoalRepository();
});
