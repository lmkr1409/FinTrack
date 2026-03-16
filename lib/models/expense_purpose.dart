class ExpensePurpose {
  final int? id;
  final String expenseFor;
  final String? icon;
  final String? iconColor;
  final int? priority;

  ExpensePurpose({
    this.id,
    required this.expenseFor,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory ExpensePurpose.fromMap(Map<String, dynamic> map) {
    return ExpensePurpose(
      id: map['purpose_id'],
      expenseFor: map['expense_for'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'purpose_id': id,
      'expense_for': expenseFor,
      'icon': icon,
      'icon_color': iconColor,
      'priority': priority,
    };
  }

  ExpensePurpose copyWith({
    int? id,
    String? expenseFor,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return ExpensePurpose(
      id: id ?? this.id,
      expenseFor: expenseFor ?? this.expenseFor,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
