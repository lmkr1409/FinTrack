import 'dart:convert';

class TransactionRule {
  final int? id;
  final String ruleType; // 'AMOUNT_REGEX', 'TRANSACTION_TYPE', 'PAYMENT_METHOD', 'ACCOUNT', 'CARD'
  final String pattern;
  final String? mappedType; // DEBIT, CREDIT, TRANSFER
  final int? paymentMethodId;
  final int? accountId;
  final int? cardId;

  TransactionRule({
    this.id,
    required this.ruleType,
    required this.pattern,
    this.mappedType,
    this.paymentMethodId,
    this.accountId,
    this.cardId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'rule_id': id,
      'rule_type': ruleType,
      'pattern': pattern,
      if (mappedType != null) 'mapped_type': mappedType,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (accountId != null) 'account_id': accountId,
      if (cardId != null) 'card_id': cardId,
    };
  }

  factory TransactionRule.fromMap(Map<String, dynamic> map) {
    return TransactionRule(
      id: map['rule_id']?.toInt(),
      ruleType: map['rule_type'] ?? '',
      pattern: map['pattern'] ?? '',
      mappedType: map['mapped_type'],
      paymentMethodId: map['payment_method_id']?.toInt(),
      accountId: map['account_id']?.toInt(),
      cardId: map['card_id']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());
  factory TransactionRule.fromJson(String source) => TransactionRule.fromMap(json.decode(source));
}
