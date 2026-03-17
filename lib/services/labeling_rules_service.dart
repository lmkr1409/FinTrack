import '../models/transaction.dart';

class LabelingRulesService {
  /// Applies hardcoded dictionary rules to auto-label a transaction based on its description.
  /// Returns a modified copy of the transaction with mapped fields and `isAutoLabeled` set to true.
  static Transaction applyRules(Transaction txn) {
    if (txn.description == null || txn.description!.isEmpty) return txn;
    
    final desc = txn.description!.toLowerCase();
    
    // Default assignments
    String txnType = txn.transactionType;
    int? catId = txn.categoryId;
    int? subCatId = txn.subcategoryId;
    int? merchId = txn.merchantId;
    int? paymentId = txn.paymentMethodId;
    bool matched = false;

    // Rules Dictionary
    // Example: Description contains "salary" -> Type: CREDIT, Category: Income
    if (desc.contains('salary') || desc.contains('payroll') || desc.contains('wages')) {
      txnType = 'CREDIT';
      matched = true;
    } else if (desc.contains('dividend') || desc.contains('interest')) {
      txnType = 'CREDIT';
      matched = true;
    } else if (desc.contains('amazon') || desc.contains('amzn')) {
      txnType = 'DEBIT';
      matched = true;
    } else if (desc.contains('uber') || desc.contains('ola') || desc.contains('taxi')) {
      txnType = 'DEBIT';
      matched = true;
    } else if (desc.contains('swiggy') || desc.contains('zomato')) {
      txnType = 'DEBIT';
      matched = true;
    } else if (desc.contains('atm') || desc.contains('cash wd')) {
      txnType = 'DEBIT';
      matched = true;
    } else if (desc.contains('upi')) {
      txnType = 'DEBIT';
      matched = true;
    }
    
    // To do full mapping realistically, the service would need to pull existing Category/Merchant IDs
    // from the database and map text strings to IDs. Since this runs synchronously before insertion,
    // we just mark the type for now and flip the auto-label flag so the UI can separate them.
    // The user's goal was: 'evaluate description and ... mark these as auto labeled'
    
    if (matched) {
      return txn.copyWith(
        transactionType: txnType,
        categoryId: catId,
        subcategoryId: subCatId,
        merchantId: merchId,
        paymentMethodId: paymentId,
        isAutoLabeled: true,
        labeled: false,
      );
    }
    return txn;
  }
}
