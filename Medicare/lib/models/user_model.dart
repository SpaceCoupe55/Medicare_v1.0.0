import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, doctor, nurse, receptionist }

extension UserRoleExtension on UserRole {
  String get value => name;

  bool get isAdmin => this == UserRole.admin;
  bool get isDoctor => this == UserRole.doctor;
}

UserRole _roleFromString(String? value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.receptionist,
  );
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String hospitalId;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.hospitalId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: _roleFromString(data['role'] as String?),
      hospitalId: data['hospitalId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'role': role.value,
        'hospitalId': hospitalId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
