import 'package:cloud_firestore/cloud_firestore.dart';

class SmsRecipient {
  final String patientId;
  final String name;
  final String phone;

  const SmsRecipient({
    required this.patientId,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'name': name,
        'phone': phone,
      };

  factory SmsRecipient.fromMap(Map<String, dynamic> m) => SmsRecipient(
        patientId: m['patientId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
      );
}

class SmsLogModel {
  final String id;
  final List<SmsRecipient> recipients;
  final String message;
  final String sentBy;
  final DateTime sentAt;
  final String status; // queued | sent | failed
  final int recipientCount;

  const SmsLogModel({
    required this.id,
    required this.recipients,
    required this.message,
    required this.sentBy,
    required this.sentAt,
    required this.status,
    required this.recipientCount,
  });

  factory SmsLogModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final raw = d['recipients'] as List<dynamic>? ?? [];
    return SmsLogModel(
      id: doc.id,
      recipients: raw
          .map((r) => SmsRecipient.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
      message: d['message'] as String? ?? '',
      sentBy: d['sentBy'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] as String? ?? 'queued',
      recipientCount: d['recipientCount'] as int? ?? 0,
    );
  }
}
