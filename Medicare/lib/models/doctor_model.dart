import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  // UI-facing fields (match existing DoctorModel field names exactly)
  final String doctorName;
  final String designation;
  final String email;
  final String mobileNumber;
  final String degree;
  final DateTime joiningDate;
  // Extended Firestore fields
  final String specialization;
  final String avatarUrl;
  final String hospitalId;
  final String status;
  final Map<String, dynamic> schedule;
  final DateTime createdAt;

  const DoctorModel({
    required this.id,
    required this.doctorName,
    required this.designation,
    required this.email,
    required this.mobileNumber,
    required this.degree,
    required this.joiningDate,
    required this.specialization,
    required this.avatarUrl,
    required this.hospitalId,
    required this.status,
    required this.schedule,
    required this.createdAt,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return DoctorModel(
      id: doc.id,
      doctorName: d['name'] as String? ?? '',
      designation: d['specialization'] as String? ?? '',
      email: d['email'] as String? ?? '',
      mobileNumber: d['phone'] as String? ?? '',
      degree: d['degree'] as String? ?? '',
      joiningDate: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      specialization: d['specialization'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      status: d['status'] as String? ?? 'active',
      schedule: (d['schedule'] as Map<String, dynamic>?) ?? {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': doctorName,
        'specialization': specialization,
        'email': email,
        'phone': mobileNumber,
        'degree': degree,
        'avatarUrl': avatarUrl,
        'hospitalId': hospitalId,
        'status': status,
        'schedule': schedule,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
