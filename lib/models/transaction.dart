class Transaction {
  final int? id;
  final String transactionType;
  final double amount;
  final String transactionDate;
  final String? description;
  final int? categoryId;
  final int? subcategoryId;
  final int? purposeId;
  final int? accountId;
  final int? cardId;
  final int? merchantId;
  final int? paymentMethodId;
  final int? expenseSourceId;
  final int? relatedTransactionId;
  final String? createdTime;
  final String? updatedTime;
  final bool labeled;
  final bool isAutoLabeled;
  final String nature;

  Transaction({
    this.id,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    this.description,
    this.categoryId,
    this.subcategoryId,
    this.purposeId,
    this.accountId,
    this.cardId,
    this.merchantId,
    this.paymentMethodId,
    this.expenseSourceId,
    this.relatedTransactionId,
    this.createdTime,
    this.updatedTime,
    this.labeled = false,
    this.isAutoLabeled = false,
    this.nature = 'EXPENSE',
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['transaction_id'],
      transactionType: map['transaction_type'],
      amount: map['amount'] is num ? (map['amount'] as num).toDouble() : 0.0,
      transactionDate: map['transaction_date'],
      description: map['description'],
      categoryId: map['category_id'],
      subcategoryId: map['subcategory_id'],
      purposeId: map['purpose_id'],
      accountId: map['account_id'],
      cardId: map['card_id'],
      merchantId: map['merchant_id'],
      paymentMethodId: map['payment_method_id'],
      expenseSourceId: map['expense_source_id'],
      relatedTransactionId: map['related_transaction_id'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      labeled: map['labeled'] == 1,
      isAutoLabeled: map['is_auto_labeled'] == 1,
      nature: map['nature'] ?? 'EXPENSE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'transaction_id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'transaction_date': transactionDate,
      'description': description,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'purpose_id': purposeId,
      'account_id': accountId,
      'card_id': cardId,
      'merchant_id': merchantId,
      'payment_method_id': paymentMethodId,
      'expense_source_id': expenseSourceId,
      'related_transaction_id': relatedTransactionId,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'labeled': labeled ? 1 : 0,
      'is_auto_labeled': isAutoLabeled ? 1 : 0,
      'nature': nature,
    };
  }

  Transaction copyWith({
    int? id,
    String? transactionType,
    double? amount,
    String? transactionDate,
    String? description,
    int? categoryId,
    int? subcategoryId,
    int? purposeId,
    int? accountId,
    int? cardId,
    int? merchantId,
    int? paymentMethodId,
    int? expenseSourceId,
    int? relatedTransactionId,
    String? createdTime,
    String? updatedTime,
    bool? labeled,
    bool? isAutoLabeled,
    String? nature,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      purposeId: purposeId ?? this.purposeId,
      accountId: accountId ?? this.accountId,
      cardId: cardId ?? this.cardId,
      merchantId: merchantId ?? this.merchantId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      expenseSourceId: expenseSourceId ?? this.expenseSourceId,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      labeled: labeled ?? this.labeled,
      isAutoLabeled: isAutoLabeled ?? this.isAutoLabeled,
      nature: nature ?? this.nature,
    );
  }
}
