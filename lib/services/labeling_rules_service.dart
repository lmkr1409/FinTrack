import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/merchant_rule.dart';
import '../models/transaction_rule.dart';
import '../models/category.dart';
import '../services/providers.dart';

class LabelingRulesService {
  /// Applies rules from the database to auto-label a transaction based on its description.
  /// Returns a modified copy of the transaction with mapped fields and `isAutoLabeled` set to true.
  static Transaction applyRules(Transaction txn, List<TransactionRule> tRules, List<MerchantRule> mRules, {List<Category>? allCategories}) {
    if (txn.description == null || txn.description!.isEmpty) return txn;
    
    final lower = txn.description!.toLowerCase();
    
    String txnType = txn.transactionType;
    String nature = txn.nature;
    int? catId = txn.categoryId;
    int? subCatId = txn.subcategoryId;
    int? merchId = txn.merchantId;
    int? paymentId = txn.paymentMethodId;
    int? expenseSourceId = txn.expenseSourceId;
    int? purposeId = txn.purposeId;
    int? accountId = txn.accountId;
    int? cardId = txn.cardId;
    bool matched = false;

    // 1. Transaction Rules
    final typeRules = tRules.where((r) => r.ruleType == 'TRANSACTION_TYPE');
    for (var rule in typeRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        txnType = rule.mappedType!;
        matched = true;
        
        // Synchronize nature with type initially
        if (txnType == 'CREDIT' || txnType == 'DEBIT') {
          nature = 'TRANSACTIONS';
        } else if (txnType == 'TRANSFER') {
          txnType = 'DEBIT';
          nature = 'TRANSFERS';
        }
        break;
      }
    }

    final methodRules = tRules.where((r) => r.ruleType == 'PAYMENT_METHOD');
    for (var rule in methodRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        paymentId = rule.paymentMethodId;
        matched = true;
        break;
      }
    }

    final accountRules = tRules.where((r) => r.ruleType == 'ACCOUNT');
    for (var rule in accountRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        if (accountId == null) accountId = rule.accountId;
        matched = true;
        break;
      }
    }

    final cardRules = tRules.where((r) => r.ruleType == 'CARD');
    for (var rule in cardRules) {
      if (lower.contains(rule.pattern.toLowerCase())) {
        if (cardId == null) cardId = rule.cardId;
        matched = true;
        break;
      }
    }

    // 2. Merchant Rules
    for (var rule in mRules) {
      if (lower.contains(rule.keyword.toLowerCase())) {
        if (rule.merchantId != null) merchId = rule.merchantId;
        if (rule.categoryId != null) catId = rule.categoryId;
        if (rule.subcategoryId != null) subCatId = rule.subcategoryId;
        if (rule.purposeId != null) purposeId = rule.purposeId;
        if (rule.goalId != null) {
          txn = txn.copyWith(goalId: rule.goalId);
        }
        matched = true;
        break;
      }
    }
    
    // Override nature if category provides one
    if (catId != null && allCategories != null) {
       try {
         final category = allCategories.firstWhere((c) => c.id == catId);
         nature = category.categoryType;
       } catch (_) {}
    }
    
    if (matched) {
      final bool isComplete = catId != null &&
                              merchId != null &&
                              paymentId != null &&
                              accountId != null &&
                              cardId != null;

      return txn.copyWith(
        transactionType: txnType,
        nature: nature,
        categoryId: catId,
        subcategoryId: subCatId,
        merchantId: merchId,
        paymentMethodId: paymentId,
        expenseSourceId: expenseSourceId,
        purposeId: purposeId,
        accountId: accountId,
        cardId: cardId,
        goalId: txn.goalId,
        isAutoLabeled: isComplete,
        labeled: false,
      );
    }
    
    return txn;
  }

  /// Shows a dialog to prompt the user about overriding behavior, then mass-applies rules to the database.
  static Future<void> promptAndApplyRules(BuildContext context, WidgetRef ref, {bool applyTransactions = true, bool applyMerchants = true}) async {
    final title = applyTransactions && applyMerchants 
        ? 'Apply All Rules'
        : (applyTransactions ? 'Apply Transaction Rules' : 'Apply Merchant/Platform Rules');

    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Do you want to update all unlabeled transactions, or only fill in their missing details?\n\n'
          '• Update All: Replaces existing categories, merchants/platforms, etc. if a matching rule defines them.\n'
          '• Fill Missing: Only updates fields that are currently empty.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Fill Missing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update All'),
          ),
        ],
      ),
    );

    if (override == null) return; // user cancelled

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final updatedCount = await _massApplyRules(ref, override: override, applyTransactions: applyTransactions, applyMerchants: applyMerchants);

    if (context.mounted) {
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rules applied to $updatedCount transactions!')),
      );
    }
  }

  /// Mass-applies existing rules to all transactions in the DB.
  static Future<int> _massApplyRules(WidgetRef ref, {required bool override, bool applyTransactions = true, bool applyMerchants = true}) async {
    final mRepo = ref.read(merchantRuleRepositoryProvider);
    final mRules = await mRepo.getAllSorted();
    
    final tRepo = ref.read(transactionRuleRepositoryProvider);
    final tRules = await tRepo.getAllSorted();

    final cardRepo = ref.read(cardRepositoryProvider);
    final allCards = await cardRepo.getAll();
    
    final catRepo = ref.read(categoryRepositoryProvider);
    final allCategories = await catRepo.getAll();
    final Map<int, String> categoryTypes = { for (var c in allCategories) c.id!: c.categoryType };

    if ((!applyMerchants || mRules.isEmpty) && (!applyTransactions || tRules.isEmpty)) return 0;

    final txnRepo = ref.read(transactionRepositoryProvider);
    // Only get transactions that are not manually labeled by the user
    final allTxns = await txnRepo.getFiltered(labeled: false);
    if (allTxns.isEmpty) return 0;
    List<Transaction> updatedTxns = [];
    int matchCount = 0;

    for (final txn in allTxns) {
      if (txn.description == null || txn.description!.isEmpty) continue;
      
      bool hasAllDetails = (txn.categoryId != null &&
                            txn.subcategoryId != null &&
                            txn.merchantId != null &&
                            txn.paymentMethodId != null &&
                            txn.expenseSourceId != null &&
                            txn.purposeId != null &&
                            txn.accountId != null &&
                            txn.cardId != null);
                            
      if (!override && hasAllDetails) continue;

      final lower = txn.description!.toLowerCase();

      bool matchedOne = false;
      Transaction currentTxn = txn;

      String? newTxnType = txn.transactionType;
      String? newNature = txn.nature;
      int? newCatId = txn.categoryId;
      int? newSubCatId = txn.subcategoryId;
      int? newMerchId = txn.merchantId;
      int? newPaymentId = txn.paymentMethodId;
      int? newSourceId = txn.expenseSourceId;
      int? newPurposeId = txn.purposeId;
      int? newAccountId = txn.accountId;
      int? newCardId = txn.cardId;
      int? newGoalId = txn.goalId;

      if (applyTransactions) {
        // 1. Transaction Rules
        final amountRules = tRules.where((r) => r.ruleType == 'AMOUNT_REGEX');
        for (var rule in amountRules) {
          try {
            final regex = RegExp(rule.pattern, caseSensitive: false);
            if (regex.hasMatch(txn.description!)) {
              matchedOne = true;
              break;
            }
          } catch (_) {}
        }

        final typeRules = tRules.where((r) => r.ruleType == 'TRANSACTION_TYPE');
        for (var rule in typeRules) {
          if (lower.contains(rule.pattern.toLowerCase())) {
            if (override || newTxnType == null) {
              newTxnType = rule.mappedType;
              if (newTxnType == 'CREDIT' || newTxnType == 'DEBIT') {
                newNature = 'TRANSACTIONS';
              } else if (newTxnType == 'TRANSFER') {
                newTxnType = 'DEBIT';
                newNature = 'TRANSFERS';
              }
            }
            matchedOne = true;
            break;
          }
        }

        final methodRules = tRules.where((r) => r.ruleType == 'PAYMENT_METHOD');
        for (var rule in methodRules) {
          if (lower.contains(rule.pattern.toLowerCase())) {
            if (override || newPaymentId == null) newPaymentId = rule.paymentMethodId;
            matchedOne = true;
            break;
          }
        }

        final accountRules = tRules.where((r) => r.ruleType == 'ACCOUNT');
        for (var rule in accountRules) {
          if (lower.contains(rule.pattern.toLowerCase())) {
            if (override || newAccountId == null) newAccountId = rule.accountId;
            matchedOne = true;
            break;
          }
        }

        final cardRules = tRules.where((r) => r.ruleType == 'CARD');
        for (var rule in cardRules) {
          if (lower.contains(rule.pattern.toLowerCase())) {
            if (override || newCardId == null) newCardId = rule.cardId;
            matchedOne = true;
            break;
          }
        }

        // Try generic card lookup if still null
        if (newCardId == null) {
          final accMatch = RegExp(r'(?:a[/\\]?c|acct|account|card)\s*(?:[Nn]o)?.*?(?:\b|[Xx]|\*)*([0-9]{4})\b', caseSensitive: false).firstMatch(txn.description!);
          if (accMatch != null) {
            final lastFour = accMatch.group(1)!;
            for (var c in allCards) {
              if (c.cardNumber.contains(lastFour)) {
                newCardId = c.id;
                matchedOne = true;
                break;
              }
            }
          }
        }
      }

      if (applyMerchants) {
        // 2. Merchant Rules
        for (var rule in mRules) {
          if (lower.contains(rule.keyword.toLowerCase())) {
            if (rule.merchantId != null && (override || newMerchId == null)) newMerchId = rule.merchantId;
            if (rule.categoryId != null && (override || newCatId == null)) newCatId = rule.categoryId;
            if (rule.subcategoryId != null && (override || newSubCatId == null)) newSubCatId = rule.subcategoryId;
            if (rule.purposeId != null && (override || newPurposeId == null)) newPurposeId = rule.purposeId;
            if (rule.goalId != null && (override || newGoalId == null)) newGoalId = rule.goalId;
            matchedOne = true;
            break;
          }
        }
      }

      if (newCatId != null && categoryTypes.containsKey(newCatId)) {
         newNature = categoryTypes[newCatId]!;
      }

      bool changed = (newTxnType != currentTxn.transactionType) ||
                     (newCatId != currentTxn.categoryId) ||
                     (newSubCatId != currentTxn.subcategoryId) ||
                     (newMerchId != currentTxn.merchantId) ||
                     (newPaymentId != currentTxn.paymentMethodId) ||
                     (newSourceId != currentTxn.expenseSourceId) ||
                     (newPurposeId != currentTxn.purposeId) ||
                     (newAccountId != currentTxn.accountId) ||
                     (newCardId != currentTxn.cardId) ||
                     (newGoalId != currentTxn.goalId);

      if (changed) {
         currentTxn = currentTxn.copyWith(
           transactionType: newTxnType,
           nature: newNature,
           categoryId: newCatId,
           subcategoryId: newSubCatId,
           merchantId: newMerchId,
           paymentMethodId: newPaymentId,
           expenseSourceId: newSourceId,
           purposeId: newPurposeId,
           accountId: newAccountId,
           cardId: newCardId,
           goalId: newGoalId,
         );
      }
      
      if (matchedOne) {
        matchCount++;
        final bool isComplete = newCatId != null &&
                                newMerchId != null &&
                                newPaymentId != null &&
                                newAccountId != null &&
                                newCardId != null;

        updatedTxns.add(currentTxn.copyWith(
          isAutoLabeled: isComplete,
          updatedTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        ));
      }
    }

    if (updatedTxns.isNotEmpty) {
      await txnRepo.updateBatch(updatedTxns);
    }

    return matchCount;
  }
}

