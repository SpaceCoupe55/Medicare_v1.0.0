import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String description;
  final String hospitalId;
  final DateTime createdAt;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    required this.hospitalId,
    required this.createdAt,
  });

  factory PharmacyModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final now = DateTime.now();
    return PharmacyModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      description: d['description'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': description,
        'hospitalId': hospitalId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
