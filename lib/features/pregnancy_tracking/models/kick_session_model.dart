class KickSession {
  final int? id;
  final String userId;
  final String pregnancyId;
  final DateTime startTime;
  final DateTime? endTime;
  final int count;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  KickSession({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.startTime,
    this.endTime,
    this.count = 0,
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

  static KickSession fromDrift(dynamic driftSession) {
    return KickSession(
      id: driftSession.id as int?,
      userId: driftSession.userId as String,
      pregnancyId: driftSession.pregnancyId as String,
      startTime: driftSession.startTime as DateTime,
      endTime: driftSession.endTime as DateTime?,
      count: driftSession.count as int,
      note: driftSession.note as String?,
      createdAt: driftSession.createdAt as DateTime,
      updatedAt: driftSession.updatedAt as DateTime,
    );
  }

  KickSession copyWith({
    int? id,
    String? userId,
    String? pregnancyId,
    DateTime? startTime,
    DateTime? endTime,
    int? count,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KickSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      count: count ?? this.count,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
