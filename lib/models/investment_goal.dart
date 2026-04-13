class InvestmentGoal {
  final int? id;
  final String goalName;
  final double targetAmount;
  final int categoryId;
  final int? subcategoryId;
  final int? purposeId;
  final int? merchantId;
  final String? createdTime;
  final String? updatedTime;

  // These are not persisted to investment_goal directly, but useful for joined queries
  final String? categoryName;
  final String? icon;
  final String? iconColor;
  final String? merchantName;

  InvestmentGoal({
    this.id,
    required this.goalName,
    required this.targetAmount,
    required this.categoryId,
    this.subcategoryId,
    this.purposeId,
    this.merchantId,
    this.createdTime,
    this.updatedTime,
    this.categoryName,
    this.icon,
    this.iconColor,
    this.merchantName,
  });

  factory InvestmentGoal.fromMap(Map<String, dynamic> map) {
    return InvestmentGoal(
      id: map['goal_id'],
      goalName: map['goal_name'],
      targetAmount: map['target_amount'] is num ? (map['target_amount'] as num).toDouble() : 0.0,
      categoryId: map['category_id'],
      subcategoryId: map['subcategory_id'],
      purposeId: map['purpose_id'],
      merchantId: map['merchant_id'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      categoryName: map['category_name'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      merchantName: map['merchant_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'goal_id': id,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'purpose_id': purposeId,
      if (merchantId != null) 'merchant_id': merchantId,
      'created_time': createdTime,
      'updated_time': updatedTime,
    };
  }

  InvestmentGoal copyWith({
    int? id,
    String? goalName,
    double? targetAmount,
    int? categoryId,
    int? subcategoryId,
    int? purposeId,
    int? merchantId,
    String? createdTime,
    String? updatedTime,
    String? categoryName,
    String? icon,
    String? iconColor,
    String? merchantName,
  }) {
    return InvestmentGoal(
      id: id ?? this.id,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      purposeId: purposeId ?? this.purposeId,
      merchantId: merchantId ?? this.merchantId,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      categoryName: categoryName ?? this.categoryName,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      merchantName: merchantName ?? this.merchantName,
    );
  }
}
