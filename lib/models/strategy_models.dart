class BudgetFramework {
  final int? id;
  final String name;
  final bool isActive;

  BudgetFramework({
    this.id,
    required this.name,
    this.isActive = false,
  });

  factory BudgetFramework.fromMap(Map<String, dynamic> map) {
    return BudgetFramework(
      id: map['framework_id'] as int?,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'framework_id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class BudgetBucket {
  final int? id;
  final int frameworkId;
  final String name;
  final double percentage;
  final String bucketType; // 'SAVED' or 'SPENT'
  final String? icon;
  final String? iconColor;

  BudgetBucket({
    this.id,
    required this.frameworkId,
    required this.name,
    required this.percentage,
    required this.bucketType,
    this.icon,
    this.iconColor,
  });

  factory BudgetBucket.fromMap(Map<String, dynamic> map) {
    return BudgetBucket(
      id: map['bucket_id'] as int?,
      frameworkId: map['framework_id'] as int,
      name: map['name'] as String,
      percentage: (map['percentage'] as num).toDouble(),
      bucketType: map['bucket_type'] as String,
      icon: map['icon'] as String?,
      iconColor: map['icon_color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bucket_id': id,
      'framework_id': frameworkId,
      'name': name,
      'percentage': percentage,
      'bucket_type': bucketType,
      'icon': icon,
      'icon_color': iconColor,
    };
  }
}

class BucketProgress {
  final BudgetBucket bucket;
  final double targetAmount;
  final double actualAmount;

  BucketProgress({
    required this.bucket,
    required this.targetAmount,
    required this.actualAmount,
  });

  double get percentage => targetAmount > 0 ? actualAmount / targetAmount : 0.0;
  bool get isExceeded => bucket.bucketType == 'SPENT' && actualAmount > targetAmount;
  bool get isGoalMet => bucket.bucketType == 'SAVED' && actualAmount >= targetAmount;
}
