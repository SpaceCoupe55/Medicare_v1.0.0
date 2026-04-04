import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, completed, cancelled }

AppointmentStatus _statusFromString(String? v) {
  switch (v) {
    case 'completed':
      return AppointmentStatus.completed;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.scheduled;
  }
}

class AppointmentModel {
  final String id;
  // UI-facing fields (match existing AppointmentListModel field names exactly)
  final String name;          // patient name
  final String consultingDoctor;
  final String treatment;     // maps to notes/type
  final String mobile;
  final String email;
  final DateTime date;
  final DateTime time;
  // Extended Firestore fields
  final String patientId;
  final String doctorId;
  final AppointmentStatus status;
  final String notes;
  final String hospitalId;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.name,
    required this.consultingDoctor,
    required this.treatment,
    required this.mobile,
    required this.email,
    required this.date,
    required this.time,
    required this.patientId,
    required this.doctorId,
    required this.status,
    required this.notes,
    required this.hospitalId,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    final dt = (d['dateTime'] as Timestamp?)?.toDate() ?? now;
    return AppointmentModel(
      id: doc.id,
      name: d['patientName'] as String? ?? '',
      consultingDoctor: d['doctorName'] as String? ?? '',
      treatment: d['notes'] as String? ?? '',
      mobile: d['patientPhone'] as String? ?? '',
      email: d['patientEmail'] as String? ?? '',
      date: dt,
      time: dt,
      patientId: d['patientId'] as String? ?? '',
      doctorId: d['doctorId'] as String? ?? '',
      status: _statusFromString(d['status'] as String?),
      notes: d['notes'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': name,
        'patientPhone': mobile,
        'patientEmail': email,
        'doctorId': doctorId,
        'doctorName': consultingDoctor,
        'dateTime': Timestamp.fromDate(date),
        'status': status.name,
        'notes': notes,
        'hospitalId': hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
