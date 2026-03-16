class PaymentMethod {
  final int? id;
  final String paymentMethodName;
  final String? icon;
  final String? iconColor;
  final int? priority;

  PaymentMethod({
    this.id,
    required this.paymentMethodName,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['payment_method_id'],
      paymentMethodName: map['payment_method_name'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'payment_method_id': id,
      'payment_method_name': paymentMethodName,
      'icon': icon,
      'icon_color': iconColor,
      'priority': priority,
    };
  }

  PaymentMethod copyWith({
    int? id,
    String? paymentMethodName,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
