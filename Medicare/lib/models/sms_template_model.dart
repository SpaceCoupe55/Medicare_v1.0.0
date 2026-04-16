import 'package:cloud_firestore/cloud_firestore.dart';

class SmsTemplateModel {
  final String id;
  final String title;
  final String body;

  const SmsTemplateModel({
    required this.id,
    required this.title,
    required this.body,
  });

  factory SmsTemplateModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SmsTemplateModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
