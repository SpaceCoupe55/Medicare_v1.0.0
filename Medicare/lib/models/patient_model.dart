import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  // UI-facing fields (match existing PatientListModel field names exactly)
  final String name;
  final String gender;
  final String mobileNumber;
  final String bloodGroup;
  final String address;
  final String status;
  final int age;
  final DateTime birthDate;
  // Extended Firestore fields
  final String email;
  final String medicalHistory;
  final String assignedDoctorId;
  final String hospitalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.mobileNumber,
    required this.bloodGroup,
    required this.address,
    required this.status,
    required this.age,
    required this.birthDate,
    required this.email,
    required this.medicalHistory,
    required this.assignedDoctorId,
    required this.hospitalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final dob = (d['dob'] as Timestamp?)?.toDate() ?? DateTime(1990);
    final now = DateTime.now();
    final computedAge = d['age'] as int? ??
        (now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0));
    return PatientModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      gender: d['gender'] as String? ?? '',
      mobileNumber: d['phone'] as String? ?? '',
      bloodGroup: d['bloodType'] as String? ?? '',
      address: d['address'] as String? ?? '',
      status: d['status'] as String? ?? 'active',
      age: computedAge,
      birthDate: dob,
      email: d['email'] as String? ?? '',
      medicalHistory: d['medicalHistory'] as String? ?? '',
      assignedDoctorId: d['assignedDoctorId'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'gender': gender,
        'phone': mobileNumber,
        'bloodType': bloodGroup,
        'address': address,
        'status': status,
        'age': age,
        'dob': Timestamp.fromDate(birthDate),
        'email': email,
        'medicalHistory': medicalHistory,
        'assignedDoctorId': assignedDoctorId,
        'hospitalId': hospitalId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
