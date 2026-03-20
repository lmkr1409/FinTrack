import 'dart:convert';

class LabelingRule {
  final int? id;
  final String keyword;
  final String? transactionType;
  final int? categoryId;
  final int? subcategoryId;
  final int? merchantId;
  final int? paymentMethodId;
  final int? expenseSourceId;
  final int? purposeId;
  final int? accountId;
  final int? cardId;

  LabelingRule({
    this.id,
    required this.keyword,
    this.transactionType,
    this.categoryId,
    this.subcategoryId,
    this.merchantId,
    this.paymentMethodId,
    this.expenseSourceId,
    this.purposeId,
    this.accountId,
    this.cardId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'rule_id': id,
      'keyword': keyword,
      if (transactionType != null) 'transaction_type': transactionType,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (merchantId != null) 'merchant_id': merchantId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (expenseSourceId != null) 'expense_source_id': expenseSourceId,
      if (purposeId != null) 'purpose_id': purposeId,
      if (accountId != null) 'account_id': accountId,
      if (cardId != null) 'card_id': cardId,
    };
  }

  factory LabelingRule.fromMap(Map<String, dynamic> map) {
    return LabelingRule(
      id: map['rule_id']?.toInt(),
      keyword: map['keyword'] ?? '',
      transactionType: map['transaction_type'],
      categoryId: map['category_id']?.toInt(),
      subcategoryId: map['subcategory_id']?.toInt(),
      merchantId: map['merchant_id']?.toInt(),
      paymentMethodId: map['payment_method_id']?.toInt(),
      expenseSourceId: map['expense_source_id']?.toInt(),
      purposeId: map['purpose_id']?.toInt(),
      accountId: map['account_id']?.toInt(),
      cardId: map['card_id']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LabelingRule.fromJson(String source) =>
      LabelingRule.fromMap(json.decode(source));

  LabelingRule copyWith({
    int? id,
    String? keyword,
    String? transactionType,
    int? categoryId,
    int? subcategoryId,
    int? merchantId,
    int? paymentMethodId,
    int? expenseSourceId,
    int? purposeId,
    int? accountId,
    int? cardId,
  }) {
    return LabelingRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      transactionType: transactionType ?? this.transactionType,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      merchantId: merchantId ?? this.merchantId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      expenseSourceId: expenseSourceId ?? this.expenseSourceId,
      purposeId: purposeId ?? this.purposeId,
      accountId: accountId ?? this.accountId,
      cardId: cardId ?? this.cardId,
    );
  }
}
