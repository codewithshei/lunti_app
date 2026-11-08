/// Bag item model for cart
class BagItem {
  final String productId;
  final String productName;
  final int price; // Base price
  final int quantity;
  final String? engravingText;
  final String? variant;
  final String? imagePath;

  // Computed values
  int get engravingValue => engravingText != null ? 550 : 0; // ₱550 engraving
  int get totalPrice => price * quantity + engravingValue * quantity;

  BagItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.engravingText,
    this.variant,
    this.imagePath,
  });

  BagItem copyWith({
    String? productId,
    String? productName,
    int? price,
    int? quantity,
    String? engravingText,
    String? variant,
    String? imagePath,
  }) {
    return BagItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      engravingText: engravingText ?? this.engravingText,
      variant: variant ?? this.variant,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'engravingText': engravingText,
      'variant': variant,
      'imagePath': imagePath,
    };
  }

  factory BagItem.fromJson(Map<String, dynamic> json) {
    return BagItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
      engravingText: json['engravingText'] as String?,
      variant: json['variant'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }
}