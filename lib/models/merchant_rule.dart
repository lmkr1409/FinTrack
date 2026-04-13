import 'dart:convert';

class MerchantRule {
  final int? id;
  final String keyword;
  final int? categoryId;
  final int? subcategoryId;
  final int? purposeId;
  final int? merchantId;
  final int? goalId;

  MerchantRule({
    this.id,
    required this.keyword,
    this.categoryId,
    this.subcategoryId,
    this.purposeId,
    this.merchantId,
    this.goalId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'rule_id': id,
      'keyword': keyword,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (purposeId != null) 'purpose_id': purposeId,
      if (merchantId != null) 'merchant_id': merchantId,
      if (goalId != null) 'goal_id': goalId,
    };
  }

  factory MerchantRule.fromMap(Map<String, dynamic> map) {
    return MerchantRule(
      id: map['rule_id']?.toInt(),
      keyword: map['keyword'] ?? '',
      categoryId: map['category_id']?.toInt(),
      subcategoryId: map['subcategory_id']?.toInt(),
      purposeId: map['purpose_id']?.toInt(),
      merchantId: map['merchant_id']?.toInt(),
      goalId: map['goal_id']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());
  factory MerchantRule.fromJson(String source) => MerchantRule.fromMap(json.decode(source));
}
