class SubCategory {
  final int? id;
  final String subcategoryName;
  final String? icon;
  final int categoryId;
  final String? iconColor;
  final int? priority;

  SubCategory({
    this.id,
    required this.subcategoryName,
    this.icon,
    required this.categoryId,
    this.iconColor,
    this.priority,
  });

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['subcategory_id'],
      subcategoryName: map['subcategory_name'],
      icon: map['icon'],
      categoryId: map['category_id'],
      iconColor: map['icon_color'],
      priority: map['priority'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'subcategory_id': id,
      'subcategory_name': subcategoryName,
      if (icon != null) 'icon': icon,
      'category_id': categoryId,
      if (iconColor != null) 'icon_color': iconColor,
      if (priority != null) 'priority': priority,
    };
  }

  SubCategory copyWith({
    int? id,
    String? subcategoryName,
    String? icon,
    int? categoryId,
    String? iconColor,
    int? priority,
  }) {
    return SubCategory(
      id: id ?? this.id,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      iconColor: iconColor ?? this.iconColor,
      priority: priority ?? this.priority,
    );
  }
}
