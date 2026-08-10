import 'package:cloud_firestore/cloud_firestore.dart';

class PregnancyWeightEntry {
  final String id;
  final DateTime date;
  final double
  weight; // in kg or lbs (we'll store as double, assume kg for now or add unit)
  final String? note;

  PregnancyWeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.note,
  });

  factory PregnancyWeightEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyWeightEntry(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': Timestamp.fromDate(date), 'weight': weight, 'note': note};
  }
}

enum AppointmentType { checkup, ultrasound, bloodTest, glucoseTest, other }

class PrenatalAppointment {
  final String id;
  final DateTime date;
  final String title;
  final AppointmentType type;
  final String? location;
  final String? doctorName;
  final String? notes;

  PrenatalAppointment({
    required this.id,
    required this.date,
    required this.title,
    required this.type,
    this.location,
    this.doctorName,
    this.notes,
  });

  factory PrenatalAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrenatalAppointment(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] as String,
      type: AppointmentType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => AppointmentType.other,
      ),
      location: data['location'] as String?,
      doctorName: data['doctorName'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'title': title,
      'type': type.toString().split('.').last,
      'location': location,
      'doctorName': doctorName,
      'notes': notes,
    };
  }
}
