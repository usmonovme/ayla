import 'package:cloud_firestore/cloud_firestore.dart';

class Pregnancy {
  final String id;
  final String userId;
  final DateTime lastPeriodDate; // LMP
  final DateTime estimatedDueDate; // EDD
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? initialWeight;
  final double? height;
  final bool isActive;
  final DateTime? birthDate;

  // New birth details
  final String? babyName;
  final String? babyGender;
  final double? birthWeight;
  final double? birthLength;
  final String? deliveryNotes;

  Pregnancy({
    required this.id,
    required this.userId,
    required this.lastPeriodDate,
    required this.estimatedDueDate,
    required this.createdAt,
    required this.updatedAt,
    this.initialWeight,
    this.height,
    this.isActive = true,
    this.birthDate,
    this.babyName,
    this.babyGender,
    this.birthWeight,
    this.birthLength,
    this.deliveryNotes,
  });

  /// Calculate gestational age in weeks
  int get currentWeek {
    final now = DateTime.now();
    final difference = now.difference(lastPeriodDate);
    return (difference.inDays / 7).floor() + 1; // 1-based week count
  }

  /// Calculate gestational age (Weeks + Days)
  String get gestationalAge {
    final now = DateTime.now();
    final difference = now.difference(lastPeriodDate);
    final weeks = (difference.inDays / 7).floor();
    final days = difference.inDays % 7;
    return '$weeks weeks, $days days';
  }

  /// Calculate Trimester
  int get trimester {
    final week = currentWeek;
    if (week <= 13) {
      return 1;
    }
    if (week <= 26) {
      return 2;
    }
    return 3;
  }

  /// Calculate duration (Weeks + Days) at birth or current
  String getDuration(String weeksLabel, String daysLabel) {
    final end = birthDate ?? (isActive ? DateTime.now() : DateTime.now());
    final difference = end.difference(lastPeriodDate);
    final weeks = (difference.inDays / 7).floor();
    final days = difference.inDays % 7;
    return '$weeks $weeksLabel, $days $daysLabel';
  }

  /// Create from Firestore
  factory Pregnancy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pregnancy(
      id: doc.id,
      userId: data['userId'] as String,
      lastPeriodDate: (data['lastPeriodDate'] as Timestamp).toDate(),
      estimatedDueDate: (data['estimatedDueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      initialWeight: (data['initialWeight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      babyName: data['babyName'] as String?,
      babyGender: data['babyGender'] as String?,
      birthWeight: (data['birthWeight'] as num?)?.toDouble(),
      birthLength: (data['birthLength'] as num?)?.toDouble(),
      deliveryNotes: data['deliveryNotes'] as String?,
    );
  }

  /// Create from Map
  factory Pregnancy.fromMap(Map<String, dynamic> map, String id) {
    return Pregnancy(
      id: id,
      userId: map['userId'] as String,
      lastPeriodDate: (map['lastPeriodDate'] as Timestamp).toDate(),
      estimatedDueDate: (map['estimatedDueDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      initialWeight: (map['initialWeight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      isActive: map['isActive'] as bool? ?? true,
      birthDate: (map['birthDate'] as Timestamp?)?.toDate(),
      babyName: map['babyName'] as String?,
      babyGender: map['babyGender'] as String?,
      birthWeight: (map['birthWeight'] as num?)?.toDouble(),
      birthLength: (map['birthLength'] as num?)?.toDouble(),
      deliveryNotes: map['deliveryNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lastPeriodDate': Timestamp.fromDate(lastPeriodDate),
      'estimatedDueDate': Timestamp.fromDate(estimatedDueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'initialWeight': initialWeight,
      'height': height,
      'isActive': isActive,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'babyName': babyName,
      'babyGender': babyGender,
      'birthWeight': birthWeight,
      'birthLength': birthLength,
      'deliveryNotes': deliveryNotes,
    };
  }

  /// Copy with modifications
  Pregnancy copyWith({
    String? id,
    String? userId,
    DateTime? lastPeriodDate,
    DateTime? estimatedDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? initialWeight,
    double? height,
    bool? isActive,
    DateTime? birthDate,
    String? babyName,
    String? babyGender,
    double? birthWeight,
    double? birthLength,
    String? deliveryNotes,
  }) {
    return Pregnancy(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      estimatedDueDate: estimatedDueDate ?? this.estimatedDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      initialWeight: initialWeight ?? this.initialWeight,
      height: height ?? this.height,
      isActive: isActive ?? this.isActive,
      birthDate: birthDate ?? this.birthDate,
      babyName: babyName ?? this.babyName,
      babyGender: babyGender ?? this.babyGender,
      birthWeight: birthWeight ?? this.birthWeight,
      birthLength: birthLength ?? this.birthLength,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
    );
  }
}
