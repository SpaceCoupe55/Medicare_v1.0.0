import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;       // 'appointment_booked' | 'appointment_cancelled' | 'appointment_reminder' | 'general'
  final String relatedId;  // appointmentId, etc.
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: d['type'] as String? ?? 'general',
      relatedId: d['relatedId'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
