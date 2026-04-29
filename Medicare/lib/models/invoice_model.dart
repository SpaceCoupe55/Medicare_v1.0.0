import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, pending, paid, claimed }
enum NhisClaimStatus { none, submitted, approved, rejected }
enum InvoicePaymentMethod { cash, momo, nhis, insurance }

class InvoiceLineItem {
  final String description;
  final String type; // 'consultation' | 'procedure' | 'lab' | 'other'
  final double unitPrice;
  final int qty;
  final double lineTotal;

  const InvoiceLineItem({
    required this.description,
    required this.type,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() => {
        'description': description,
        'type': type,
        'unitPrice': unitPrice,
        'qty': qty,
        'lineTotal': lineTotal,
      };

  factory InvoiceLineItem.fromMap(Map<String, dynamic> m) => InvoiceLineItem(
        description: m['description'] as String? ?? '',
        type: m['type'] as String? ?? 'other',
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
        lineTotal: (m['lineTotal'] as num?)?.toDouble() ?? 0.0,
      );
}

InvoiceStatus _statusFromString(String? v) {
  switch (v) {
    case 'draft':
      return InvoiceStatus.draft;
    case 'paid':
      return InvoiceStatus.paid;
    case 'claimed':
      return InvoiceStatus.claimed;
    default:
      return InvoiceStatus.pending;
  }
}

NhisClaimStatus _claimStatusFromString(String? v) {
  switch (v) {
    case 'submitted':
      return NhisClaimStatus.submitted;
    case 'approved':
      return NhisClaimStatus.approved;
    case 'rejected':
      return NhisClaimStatus.rejected;
    default:
      return NhisClaimStatus.none;
  }
}

InvoicePaymentMethod? _paymentFromString(String? v) {
  switch (v) {
    case 'cash':
      return InvoicePaymentMethod.cash;
    case 'momo':
      return InvoicePaymentMethod.momo;
    case 'nhis':
      return InvoicePaymentMethod.nhis;
    case 'insurance':
      return InvoicePaymentMethod.insurance;
    default:
      return null;
  }
}

class InvoiceModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? appointmentId;
  final String? saleId;
  final List<InvoiceLineItem> items;
  final double subtotal;
  final bool nhisApplied;
  final double nhisCoverage; // 0.0–1.0
  final double nhisAmount;
  final double netAmount;
  final NhisClaimStatus nhisClaimStatus;
  final InvoicePaymentMethod? paymentMethod;
  final String? momoPhone;
  final String? momoNetwork;
  final String? momoReference;
  final InvoiceStatus status;
  final String hospitalId;
  final String createdBy;
  final DateTime? paidAt;
  final DateTime createdAt;

  const InvoiceModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
    this.saleId,
    required this.items,
    required this.subtotal,
    required this.nhisApplied,
    required this.nhisCoverage,
    required this.nhisAmount,
    required this.netAmount,
    required this.nhisClaimStatus,
    this.paymentMethod,
    this.momoPhone,
    this.momoNetwork,
    this.momoReference,
    required this.status,
    required this.hospitalId,
    required this.createdBy,
    this.paidAt,
    required this.createdAt,
  });

  factory InvoiceModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return InvoiceModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      appointmentId: d['appointmentId'] as String?,
      saleId: d['saleId'] as String?,
      items: rawItems
          .map((e) =>
              InvoiceLineItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0.0,
      nhisApplied: d['nhisApplied'] as bool? ?? false,
      nhisCoverage: (d['nhisCoverage'] as num?)?.toDouble() ?? 0.0,
      nhisAmount: (d['nhisAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (d['netAmount'] as num?)?.toDouble() ?? 0.0,
      nhisClaimStatus:
          _claimStatusFromString(d['nhisClaimStatus'] as String?),
      paymentMethod: _paymentFromString(d['paymentMethod'] as String?),
      momoPhone: d['momoPhone'] as String?,
      momoNetwork: d['momoNetwork'] as String?,
      momoReference: d['momoReference'] as String?,
      status: _statusFromString(d['status'] as String?),
      hospitalId: d['hospitalId'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'appointmentId': appointmentId,
        'saleId': saleId,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'nhisApplied': nhisApplied,
        'nhisCoverage': nhisCoverage,
        'nhisAmount': nhisAmount,
        'netAmount': netAmount,
        'nhisClaimStatus': nhisClaimStatus.name,
        'paymentMethod': paymentMethod?.name,
        'momoPhone': momoPhone,
        'momoNetwork': momoNetwork,
        'momoReference': momoReference,
        'status': status.name,
        'hospitalId': hospitalId,
        'createdBy': createdBy,
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
