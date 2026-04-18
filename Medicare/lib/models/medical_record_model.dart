import 'package:cloud_firestore/cloud_firestore.dart';

enum RecordType { note, diagnosis, prescription, lab_result }

RecordType _typeFromString(String? v) {
  switch (v) {
    case 'diagnosis':
      return RecordType.diagnosis;
    case 'prescription':
      return RecordType.prescription;
    case 'lab_result':
      return RecordType.lab_result;
    default:
      return RecordType.note;
  }
}

extension RecordTypeExtension on RecordType {
  String get label {
    switch (this) {
      case RecordType.note:
        return 'Note';
      case RecordType.diagnosis:
        return 'Diagnosis';
      case RecordType.prescription:
        return 'Prescription';
      case RecordType.lab_result:
        return 'Lab Result';
    }
  }

  String get value => name;
}

class MedicalRecordModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final RecordType type;
  final String title;
  final String content;
  final String? attachmentUrl;
  final DateTime visitDate;
  final DateTime createdAt;
  // Structured data for prescription and lab_result types
  final List<Map<String, dynamic>> prescriptionItems;
  final List<Map<String, dynamic>> labItems;

  const MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.type,
    required this.title,
    required this.content,
    this.attachmentUrl,
    required this.visitDate,
    required this.createdAt,
    this.prescriptionItems = const [],
    this.labItems = const [],
  });

  factory MedicalRecordModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return MedicalRecordModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      doctorId: d['doctorId'] as String? ?? '',
      doctorName: d['doctorName'] as String? ?? '',
      type: _typeFromString(d['type'] as String?),
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      attachmentUrl: d['attachmentUrl'] as String?,
      visitDate: (d['visitDate'] as Timestamp?)?.toDate() ?? now,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      prescriptionItems: (d['prescriptionItems'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      labItems: (d['labItems'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'type': type.value,
        'title': title,
        'content': content,
        'attachmentUrl': attachmentUrl,
        'visitDate': Timestamp.fromDate(visitDate),
        'createdAt': FieldValue.serverTimestamp(),
        'prescriptionItems': prescriptionItems,
        'labItems': labItems,
      };
}
