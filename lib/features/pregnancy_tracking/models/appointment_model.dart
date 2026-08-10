class Appointment {
  final String id;
  final String pregnancyId;
  final String userId;
  final DateTime date;
  final String title;
  final String? description;
  final String? notes;
  final DateTime? reminderTime;
  final int? reminderLeadTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.pregnancyId,
    required this.userId,
    required this.date,
    required this.title,
    this.description,
    this.notes,
    this.reminderTime,
    this.reminderLeadTime,
    this.createdAt,
    this.updatedAt,
  });

  Appointment copyWith({
    String? id,
    String? pregnancyId,
    String? userId,
    DateTime? date,
    String? title,
    String? description,
    String? notes,
    DateTime? reminderTime,
    int? reminderLeadTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderLeadTime: reminderLeadTime ?? this.reminderLeadTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
