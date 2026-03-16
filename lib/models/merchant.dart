class Merchant {
  final int? id;
  final String merchantName;
  final String? createdTime;
  final String? updatedTime;
  final String? iconColor;
  final String? icon;
  final int? priority;

  Merchant({
    this.id,
    required this.merchantName,
    this.createdTime,
    this.updatedTime,
    this.iconColor,
    this.icon,
    this.priority,
  });

  factory Merchant.fromMap(Map<String, dynamic> map) {
    return Merchant(
      id: map['merchant_id'],
      merchantName: map['merchant_name'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
      iconColor: map['icon_color'],
      icon: map['icon'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'merchant_id': id,
      'merchant_name': merchantName,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'icon_color': iconColor,
      'icon': icon,
      'priority': priority,
    };
  }

  Merchant copyWith({
    int? id,
    String? merchantName,
    String? createdTime,
    String? updatedTime,
    String? iconColor,
    String? icon,
    int? priority,
  }) {
    return Merchant(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      createdTime: createdTime ?? this.createdTime,
      updatedTime: updatedTime ?? this.updatedTime,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
    );
  }
}
