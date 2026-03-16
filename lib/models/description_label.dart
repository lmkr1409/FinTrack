class DescriptionLabel {
  final int? id;
  final String label;

  DescriptionLabel({
    this.id,
    required this.label,
  });

  factory DescriptionLabel.fromMap(Map<String, dynamic> map) {
    return DescriptionLabel(
      id: map['id'],
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'label': label,
    };
  }

  DescriptionLabel copyWith({
    int? id,
    String? label,
  }) {
    return DescriptionLabel(
      id: id ?? this.id,
      label: label ?? this.label,
    );
  }
}
