import '../../../core/data/local/database/app_database.dart' as db;

enum ContractionIntensity { mild, moderate, strong }

class ContractionEntry {
  final int? id;
  final String userId;
  final String pregnancyId;
  final DateTime startTime;
  final DateTime? endTime;
  final ContractionIntensity? intensity;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractionEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.startTime,
    this.endTime,
    this.intensity,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => endTime != null;

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  static ContractionEntry fromDrift(db.Contraction driftContraction) {
    return ContractionEntry(
      id: driftContraction.id,
      userId: driftContraction.userId,
      pregnancyId: driftContraction.pregnancyId,
      startTime: driftContraction.startTime,
      endTime: driftContraction.endTime,
      intensity: driftContraction.intensity != null
          ? ContractionIntensity.values[driftContraction.intensity!]
          : null,
      note: driftContraction.note,
      createdAt: driftContraction.createdAt,
      updatedAt: driftContraction.updatedAt,
    );
  }

  ContractionEntry copyWith({
    int? id,
    String? userId,
    String? pregnancyId,
    DateTime? startTime,
    DateTime? endTime,
    ContractionIntensity? intensity,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContractionEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
