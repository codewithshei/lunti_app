import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model matching Firestore structure
class Product {
  final String id;
  final String name;
  final String description;
  final String type;
  final String category;
  final int price;
  final String? imagePath;
  final int stock;
  final int engravingPrice;
  final List<String> availableEngravings;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.price,
    this.imagePath,
    required this.stock,
    required this.engravingPrice,
    required this.availableEngravings,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json, String docId) {
    return Product(
      id: docId,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String? ?? 'product',
      category: json['category'] as String? ?? 'misc',
      price: json['price'] as int? ?? 0,
      imagePath: json['imagePath'] as String?,
      stock: json['stock'] as int? ?? 0,
      engravingPrice: json['engravingPrice'] as int? ?? 0,
      availableEngravings: List<String>.from(json['availableEngravings'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'category': category,
      'price': price,
      'imagePath': imagePath,
      'stock': stock,
      'engravingPrice': engravingPrice,
      'availableEngravings': availableEngravings,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}