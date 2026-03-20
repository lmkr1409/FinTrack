class Category {
  final int? id;
  final String categoryName;
  final String? icon;
  final String? iconColor;
  final int? priority;

  Category({
    this.id,
    required this.categoryName,
    this.icon,
    this.iconColor,
    this.priority,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['category_id'],
      categoryName: map['category_name'],
      icon: map['icon'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'category_id': id,
      'category_name': categoryName,
      if (icon != null) 'icon': icon,
      if (iconColor != null) 'icon_color': iconColor,
      if (priority != null) 'priority': priority,
    };
  }

  Category copyWith({
    int? id,
    String? categoryName,
    String? icon,
    String? iconColor,
    int? priority,
  }) {
    return Category(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
