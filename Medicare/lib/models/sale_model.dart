import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String pharmacyItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const SaleItem({
    required this.pharmacyItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() => {
        'pharmacyItemId': pharmacyItemId,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory SaleItem.fromMap(Map<String, dynamic> m) => SaleItem(
        pharmacyItemId: m['pharmacyItemId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
        lineTotal: (m['lineTotal'] as num?)?.toDouble() ?? 0.0,
      );
}

class SaleModel {
  final String id;
  final List<SaleItem> items;
  final double grandTotal;
  final String paymentMethod; // 'cash' | 'momo'
  final String? momoPhone;
  final String? momoNetwork;
  final String? momoReference;
  final String? patientId;
  final String soldBy;
  final String hospitalId;
  final DateTime createdAt;
  final String status;

  const SaleModel({
    required this.id,
    required this.items,
    required this.grandTotal,
    required this.paymentMethod,
    this.momoPhone,
    this.momoNetwork,
    this.momoReference,
    this.patientId,
    required this.soldBy,
    required this.hospitalId,
    required this.createdAt,
    this.status = 'completed',
  });

  factory SaleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return SaleModel(
      id: doc.id,
      items: rawItems
          .map((e) => SaleItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      grandTotal: (d['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: d['paymentMethod'] as String? ?? 'cash',
      momoPhone: d['momoPhone'] as String?,
      momoNetwork: d['momoNetwork'] as String?,
      momoReference: d['momoReference'] as String?,
      patientId: d['patientId'] as String?,
      soldBy: d['soldBy'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      status: d['status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'items': items.map((e) => e.toMap()).toList(),
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'momoPhone': momoPhone,
        'momoNetwork': momoNetwork,
        'momoReference': momoReference,
        'patientId': patientId,
        'soldBy': soldBy,
        'hospitalId': hospitalId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      };
}
