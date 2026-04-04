import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double rate;
  final int stock;
  final String imageUrl;
  final String hospitalId;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rate,
    required this.stock,
    required this.imageUrl,
    required this.hospitalId,
  });

  /// Returns a map with the keys the existing pharmacy UI expects:
  /// product['name'], product['image'], product['price'], product['rate']
  Map<String, dynamic> toDisplayMap() => {
        'id': id,
        'name': name,
        'image': imageUrl,
        'price': price,
        'rate': rate,
        'stock': stock,
        'category': category,
      };

  factory PharmacyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PharmacyModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      rate: (d['rate'] as num?)?.toDouble() ?? 0.0,
      stock: d['stock'] as int? ?? 0,
      imageUrl: d['imageUrl'] as String? ?? '',
      hospitalId: d['hospitalId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'price': price,
        'rate': rate,
        'stock': stock,
        'imageUrl': imageUrl,
        'hospitalId': hospitalId,
      };
}
