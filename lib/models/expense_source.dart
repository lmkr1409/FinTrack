class ExpenseSource {
  final int? id;
  final String expenseSourceName;
  final String? icon;
  final String? iconColor;
  final int? priority;

  ExpenseSource({
    this.id,
    required this.expenseSourceName,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory ExpenseSource.fromMap(Map<String, dynamic> map) {
    return ExpenseSource(
      id: map['expense_source_id'],
      expenseSourceName: map['expense_source_name'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'expense_source_id': id,
      'expense_source_name': expenseSourceName,
      'icon': icon,
      'icon_color': iconColor,
      'priority': priority,
    };
  }

  ExpenseSource copyWith({
    int? id,
    String? expenseSourceName,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return ExpenseSource(
      id: id ?? this.id,
      expenseSourceName: expenseSourceName ?? this.expenseSourceName,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
