import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus { pending, fulfilled }

PrescriptionStatus _statusFromString(String? v) =>
    v == 'fulfilled' ? PrescriptionStatus.fulfilled : PrescriptionStatus.pending;

class PrescriptionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  // Link back to patients/{patientId}/records/{recordId}
  final String recordId;
  final List<Map<String, dynamic>> items;
  final PrescriptionStatus status;
  final String? saleId;
  final String? fulfilledBy;
  final DateTime? fulfilledAt;
  final String hospitalId;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.recordId,
    required this.items,
    required this.status,
    this.saleId,
    this.fulfilledBy,
    this.fulfilledAt,
    required this.hospitalId,
    required this.createdAt,
  });

  factory PrescriptionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PrescriptionModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      doctorId: d['doctorId'] as String? ?? '',
      doctorName: d['doctorName'] as String? ?? '',
      recordId: d['recordId'] as String? ?? '',
      items: (d['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      status: _statusFromString(d['status'] as String?),
      saleId: d['saleId'] as String?,
      fulfilledBy: d['fulfilledBy'] as String?,
      fulfilledAt: (d['fulfilledAt'] as Timestamp?)?.toDate(),
      hospitalId: d['hospitalId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'recordId': recordId,
        'items': items,
        'status': status.name,
        'saleId': saleId,
        'fulfilledBy': fulfilledBy,
        'fulfilledAt': fulfilledAt != null ? Timestamp.fromDate(fulfilledAt!) : null,
        'hospitalId': hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
