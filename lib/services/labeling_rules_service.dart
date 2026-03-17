import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/labeling_rule.dart';
import '../services/providers.dart';

class LabelingRulesService {
  /// Applies rules from the database to auto-label a transaction based on its description.
  /// Returns a modified copy of the transaction with mapped fields and `isAutoLabeled` set to true.
  static Transaction applyRules(Transaction txn, List<LabelingRule> rules) {
    if (txn.description == null || txn.description!.isEmpty) return txn;
    
    final desc = txn.description!.toLowerCase();
    
    // Default assignments
    String txnType = txn.transactionType;
    int? catId = txn.categoryId;
    int? subCatId = txn.subcategoryId;
    int? merchId = txn.merchantId;
    int? paymentId = txn.paymentMethodId;
    int? expenseSourceId = txn.expenseSourceId;
    int? purposeId = txn.purposeId;
    int? accountId = txn.accountId;
    int? cardId = txn.cardId;
    bool matched = false;

    // Evaluate rules sequentially, first match priority.
    // If you want all to apply in order, don't break, just let them overwrite.
    for (final rule in rules) {
      if (desc.contains(rule.keyword.toLowerCase())) {
        matched = true;
        
        if (rule.transactionType != null && rule.transactionType!.isNotEmpty) {
           txnType = rule.transactionType!;
        }
        if (rule.categoryId != null) catId = rule.categoryId;
        if (rule.subcategoryId != null) subCatId = rule.subcategoryId;
        if (rule.merchantId != null) merchId = rule.merchantId;
        if (rule.paymentMethodId != null) paymentId = rule.paymentMethodId;
        if (rule.expenseSourceId != null) expenseSourceId = rule.expenseSourceId;
        if (rule.purposeId != null) purposeId = rule.purposeId;
        
        // Note: As per user request, we do NOT overwrite Account/Card configured during statement upload.
        // If they are null, we can try to apply from rule, else stick to uploaded account.
        if (accountId == null && rule.accountId != null) accountId = rule.accountId;
        if (cardId == null && rule.cardId != null) cardId = rule.cardId;

        // Found a matching rule
        break;
      }
    }
    
    if (matched) {
      return txn.copyWith(
        transactionType: txnType,
        categoryId: catId,
        subcategoryId: subCatId,
        merchantId: merchId,
        paymentMethodId: paymentId,
        expenseSourceId: expenseSourceId,
        purposeId: purposeId,
        accountId: accountId,
        cardId: cardId,
        isAutoLabeled: true,
        labeled: false,
      );
    }
    
    return txn;
  }

  /// Shows a dialog to prompt the user about overidding behavior, then mass-applies rules to the database.
  static Future<void> promptAndApplyRules(BuildContext context, WidgetRef ref) async {
    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply Rules to All Transactions'),
        content: const Text(
          'Do you want to override existing transaction configurations, or only fill in the missing ones?\n\n'
          '• Override: Replaces existing categories, merchants, etc. if the matching rule defines them.\n'
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
            child: const Text('Override'),
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

    final updatedCount = await _massApplyRules(ref, override: override);

    if (context.mounted) {
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rules applied to $updatedCount transactions!')),
      );
    }
  }

  /// Mass-applies existing rules to all transactions in the DB.
  static Future<int> _massApplyRules(WidgetRef ref, {required bool override}) async {
    final rulesRepo = ref.read(labelingRuleRepositoryProvider);
    final rules = await rulesRepo.getAllSorted();
    if (rules.isEmpty) return 0;

    final txnRepo = ref.read(transactionRepositoryProvider);
    final allTxns = await txnRepo.getAll();
    if (allTxns.isEmpty) return 0;

    List<Transaction> updatedTxns = [];

    for (final txn in allTxns) {
      if (txn.description == null || txn.description!.isEmpty) continue;
      final desc = txn.description!.toLowerCase();

      bool matchedOne = false;
      Transaction currentTxn = txn;

      for (final rule in rules) {
        if (desc.contains(rule.keyword.toLowerCase())) {
          matchedOne = true;
          
          String newTxnType = currentTxn.transactionType;
          int? newCatId = currentTxn.categoryId;
          int? newSubCatId = currentTxn.subcategoryId;
          int? newMerchId = currentTxn.merchantId;
          int? newPaymentId = currentTxn.paymentMethodId;
          int? newSourceId = currentTxn.expenseSourceId;
          int? newPurposeId = currentTxn.purposeId;
          int? newAccountId = currentTxn.accountId;
          int? newCardId = currentTxn.cardId;

          if (rule.transactionType != null && rule.transactionType!.isNotEmpty) {
            newTxnType = rule.transactionType!;
          }
          if (rule.categoryId != null) {
            if (override || newCatId == null) newCatId = rule.categoryId;
          }
          if (rule.subcategoryId != null) {
            if (override || newSubCatId == null) newSubCatId = rule.subcategoryId;
          }
          if (rule.merchantId != null) {
            if (override || newMerchId == null) newMerchId = rule.merchantId;
          }
          if (rule.paymentMethodId != null) {
            if (override || newPaymentId == null) newPaymentId = rule.paymentMethodId;
          }
          if (rule.expenseSourceId != null) {
            if (override || newSourceId == null) newSourceId = rule.expenseSourceId;
          }
          if (rule.purposeId != null) {
            if (override || newPurposeId == null) newPurposeId = rule.purposeId;
          }
          if (rule.accountId != null) {
            if (override || newAccountId == null) newAccountId = rule.accountId;
          }
          if (rule.cardId != null) {
            if (override || newCardId == null) newCardId = rule.cardId;
          }

          bool changed = (newTxnType != currentTxn.transactionType) ||
                         (newCatId != currentTxn.categoryId) ||
                         (newSubCatId != currentTxn.subcategoryId) ||
                         (newMerchId != currentTxn.merchantId) ||
                         (newPaymentId != currentTxn.paymentMethodId) ||
                         (newSourceId != currentTxn.expenseSourceId) ||
                         (newPurposeId != currentTxn.purposeId) ||
                         (newAccountId != currentTxn.accountId) ||
                         (newCardId != currentTxn.cardId);

          if (changed) {
             currentTxn = currentTxn.copyWith(
               transactionType: newTxnType,
               categoryId: newCatId,
               subcategoryId: newSubCatId,
               merchantId: newMerchId,
               paymentMethodId: newPaymentId,
               expenseSourceId: newSourceId,
               purposeId: newPurposeId,
               accountId: newAccountId,
               cardId: newCardId,
             );
          }
          
          break; // only apply first matching rule per transaction
        }
      }

      if (matchedOne && currentTxn != txn) {
        updatedTxns.add(currentTxn.copyWith(
          isAutoLabeled: true,
          updatedTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        ));
      }
    }

    if (updatedTxns.isNotEmpty) {
      await txnRepo.updateBatch(updatedTxns);
    }
    return updatedTxns.length;
  }
}
