class Card {
  final int? id;
  final String cardName;
  final String cardType;
  final String cardNumber;
  final String cardExpiryDate;
  final String? cardNetwork;
  final double balance;
  final int? accountId;
  final String? createdTime;
  final String? updatedTime;
  final String? icon;
  final String? iconColor;
  final int? priority;

  Card({
    this.id,
    required this.cardName,
    required this.cardType,
    required this.cardNumber,
    required this.cardExpiryDate,
    required this.cardNetwork,
    required this.balance,
    this.accountId,
    this.createdTime,
    this.updatedTime,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['card_id'],
      cardName: map['card_name'],
      cardType: map['card_type'],
      cardNumber: map['card_number'],
      cardExpiryDate: map['card_expiry_date'],
      cardNetwork: map['card_network'] ?? 'UNKNOWN',
      balance: map['balance'] is num ? (map['balance'] as num).toDouble() : 0.0,
      accountId: map['account_id'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'card_id': id,
      'card_name': cardName,
      'card_type': cardType,
      'card_number': cardNumber,
      'card_expiry_date': cardExpiryDate,
      'card_network': cardNetwork,
      'balance': balance,
      'account_id': accountId,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'icon': icon,
      'icon_color': iconColor,
      'priority': priority,
    };
  }

  Card copyWith({
    int? id,
    String? cardName,
    String? cardType,
    String? cardNumber,
    String? cardExpiryDate,
    String? cardNetwork,
    double? balance,
    int? accountId,
    String? createdTime,
    String? updatedTime,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return Card(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      cardType: cardType ?? this.cardType,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiryDate: cardExpiryDate ?? this.cardExpiryDate,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      balance: balance ?? this.balance,
      accountId: accountId ?? this.accountId,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
