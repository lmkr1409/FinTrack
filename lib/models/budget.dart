class Budget {
  final int? id;
  final int? categoryId;
  final double budgetAmount;
  final String budgetFrequency;
  final String? createdTime;
  final String? updatedTime;
  final int? month;
  final int? year;

  Budget({
    this.id,
    this.categoryId,
    required this.budgetAmount,
    required this.budgetFrequency,
    this.createdTime,
    this.updatedTime,
    this.month,
    this.year,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['budget_id'],
      categoryId: map['category_id'],
      budgetAmount: map['budget_amount'] is num ? (map['budget_amount'] as num).toDouble() : 0.0,
      budgetFrequency: map['budget_frequency'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      month: map['month'],
      year: map['year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'budget_id': id,
      'category_id': categoryId,
      'budget_amount': budgetAmount,
      'budget_frequency': budgetFrequency,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'month': month,
      'year': year,
    };
  }

  Budget copyWith({
    int? id,
    int? categoryId,
    double? budgetAmount,
    String? budgetFrequency,
    String? createdTime,
    String? updatedTime,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      budgetFrequency: budgetFrequency ?? this.budgetFrequency,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
