class BudgetTotal {
  final int? id;
  final double budgetAmount;
  final String budgetFrequency;
  final int? month;
  final int year;
  final String? createdTime;
  final String? updatedTime;

  BudgetTotal({
    this.id,
    required this.budgetAmount,
    required this.budgetFrequency,
    this.month,
    required this.year,
    this.createdTime,
    this.updatedTime,
  });

  factory BudgetTotal.fromMap(Map<String, dynamic> map) {
    return BudgetTotal(
      id: map['total_id'],
      budgetAmount: map['budget_amount'] is num ? (map['budget_amount'] as num).toDouble() : 0.0,
      budgetFrequency: map['budget_frequency'],
      month: map['month'],
      year: map['year'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'total_id': id,
      'budget_amount': budgetAmount,
      'budget_frequency': budgetFrequency,
      'month': month,
      'year': year,
      'created_time': createdTime,
      'updated_time': updatedTime,
    };
  }

  BudgetTotal copyWith({
    int? id,
    double? budgetAmount,
    String? budgetFrequency,
    int? month,
    int? year,
    String? createdTime,
    String? updatedTime,
  }) {
    return BudgetTotal(
      id: id ?? this.id,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      budgetFrequency: budgetFrequency ?? this.budgetFrequency,
      month: month ?? this.month,
      year: year ?? this.year,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
    );
  }
}
