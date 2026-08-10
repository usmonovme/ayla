class WeightEntry {
  final String id;
  final String pregnancyId;
  final String userId;
  final DateTime date;
  final double weightValue;
  final double? bmi;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WeightEntry({
    required this.id,
    required this.pregnancyId,
    required this.userId,
    required this.date,
    required this.weightValue,
    this.bmi,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  WeightEntry copyWith({
    String? id,
    String? pregnancyId,
    String? userId,
    DateTime? date,
    double? weightValue,
    double? bmi,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weightValue: weightValue ?? this.weightValue,
      bmi: bmi ?? this.bmi,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
