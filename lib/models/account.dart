class Account {
  final int? id;
  final String accountName;
  final double balance;
  final String? createdTime;
  final String? updatedTime;
  final String? icon;
  final String? iconColor;
  final int? priority;

  Account({
    this.id,
    required this.accountName,
    required this.balance,
    this.createdTime,
    this.updatedTime,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['account_id'],
      accountName: map['account_name'],
      balance: map['balance'] is num ? (map['balance'] as num).toDouble() : 0.0,
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'account_id': id,
      'account_name': accountName,
      'balance': balance,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'icon': icon,
      'icon_color': iconColor,
      'priority': priority,
    };
  }

  Account copyWith({
    int? id,
    String? accountName,
    double? balance,
    String? createdTime,
    String? updatedTime,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return Account(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      balance: balance ?? this.balance,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
