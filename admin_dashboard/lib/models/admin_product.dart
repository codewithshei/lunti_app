import 'package:cloud_firestore/cloud_firestore.dart';

/// Product document used by the dashboard. Mobile screens map the same
/// document into their UI model, so the field names here must stay aligned
/// with `lib/services/catalog_store.dart` in the mobile app.
class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.engravingPrice,
    required this.availableEngravings,
    required this.imagePath,
    required this.note,
    required this.eyebrow,
    required this.material,
    required this.origin,
    required this.care,
    required this.gallery,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final int stock;
  final int engravingPrice;
  final List<String> availableEngravings;
  final String imagePath;
  final String note;
  final String eyebrow;
  final String material;
  final String origin;
  final String care;
  final List<String> gallery;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get supportsEngraving =>
      availableEngravings.any((value) => value.toLowerCase() == 'engraved') ||
      engravingPrice > 0;

  factory AdminProduct.fromDoc(String id, Map<String, dynamic> data) {
    return AdminProduct(
      id: id,
      name: _string(data['name']) ?? 'Untitled product',
      description: _string(data['description']) ?? '',
      category: _string(data['category']) ?? 'customized',
      price: _int(data['price']) ?? 0,
      stock: _int(data['stock']) ?? 0,
      engravingPrice: _int(data['engravingPrice']) ?? 0,
      availableEngravings: _stringList(data['availableEngravings']),
      imagePath: _string(data['imagePath']) ?? '',
      note: _string(data['note']) ?? '',
      eyebrow: _string(data['eyebrow']) ?? '',
      material: _string(data['material']) ?? 'Bamboo',
      origin: _string(data['origin']) ?? 'Cardona, Rizal, Philippines',
      care: _string(data['care']) ?? 'Wipe gently; keep dry.',
      gallery: _stringList(data['gallery']),
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    final now = Timestamp.now();
    return {
      'name': name,
      'description': description,
      'type': 'product',
      'category': category,
      'price': price,
      'stock': stock,
      'engravingPrice': engravingPrice,
      'availableEngravings': availableEngravings,
      'imagePath': imagePath,
      'note': note,
      'eyebrow': eyebrow,
      'material': material,
      'origin': origin,
      'care': care,
      'gallery': gallery,
      'createdAt': createdAt == null ? now : Timestamp.fromDate(createdAt!),
      'updatedAt': now,
    };
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((entry) => '$entry'.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
