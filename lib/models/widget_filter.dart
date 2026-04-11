class WidgetFilter {
  final int? id;
  final String widgetKey;
  final int targetId;
  final String targetType; // 'CATEGORY' or 'SUBCATEGORY'
  final String filterType; // 'INCLUDE' or 'EXCLUDE'

  WidgetFilter({
    this.id,
    required this.widgetKey,
    required this.targetId,
    required this.targetType,
    required this.filterType,
  });

  factory WidgetFilter.fromMap(Map<String, dynamic> map) {
    return WidgetFilter(
      id: map['filter_id'] as int?,
      widgetKey: map['widget_key'] as String,
      targetId: map['target_id'] as int,
      targetType: map['target_type'] as String,
      filterType: map['filter_type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filter_id': id,
      'widget_key': widgetKey,
      'target_id': targetId,
      'target_type': targetType,
      'filter_type': filterType,
    };
  }
}
