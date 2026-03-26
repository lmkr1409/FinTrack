

class MlService {
  /// Parses transaction info from an SMS when rule-based regex fails.
  /// Currently a placeholder. Returns `null` if it can't determine.
  static Future<Map<String, dynamic>?> parseTransactionInfo(String smsText) async {
    // TODO: Implement FastText or Mobile BERT integration
    // Returns a map with keys: 'amount', 'merchantName', 'transactionType' (CREDIT/DEBIT),
    // 'paymentMethodName', 'bankName', 'cardNumber'
    return null;
  }

  /// Categorizes a merchant when rule-based matching fails.
  /// Returns a map with 'categoryId', 'subcategoryId', 'purposeId' or null.
  static Future<Map<String, dynamic>?> categorizeMerchant(String merchantName) async {
    // TODO: Implement FastText or Mobile BERT integration
    return null;
  }
}
