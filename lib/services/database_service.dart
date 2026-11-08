import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lunti_app/models/product.dart';
import 'package:lunti_app/models/order.dart';

/// Database service for Firestore operations
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products collection
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Stream<List<Product>> get products {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Product?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    if (doc.exists) {
      return Product.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> createProduct(Product product) async {
    await _products.add(product.toJson());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _products.doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  // Orders collection
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Stream<List<Order>> getOrdersForUser(String userId) {
    // Filter only, then sort client-side: `where` + `orderBy` on different
    // fields requires a composite index, which the MVP does not need.
    return _orders.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final orders =
          snapshot.docs
              .map((doc) => Order.fromJson(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<Order>> getAllOrders() {
    return _orders.snapshots().map((snapshot) {
      final orders =
          snapshot.docs
              .map((doc) => Order.fromJson(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> createOrder(Order order) async {
    // Allow saving orders even without a userId (anonymous checkout)
    final data = order.toJson();
    final orderData = Map<String, dynamic>.from(data);
    orderData['userId'] = order.userId.isEmpty ? 'anonymous' : order.userId;
    await _orders.add(orderData);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<Order?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (doc.exists) {
      return Order.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  // Users collection
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'admin': false,
      'wishlist': [],
    });
  }

  /// Creates the lightweight user profile document once, without overwriting
  /// data the customer may have changed later.
  Future<void> createUserIfMissing(User user) async {
    try {
      final doc = await _users.doc(user.uid).get();
      if (doc.exists) return;
      // Merge so a shopping snapshot written by ShoppingSyncService during
      // the same sign-in is never overwritten.
      await _users.doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'wishlist': <String>[],
      }, SetOptions(merge: true));
    } catch (_) {
      // A profile document is helpful but must never block sign-in.
    }
  }

  Stream<Map<String, dynamic>?> getUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data());
  }

  /// One-time profile read used by the edit screen.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  /// Saves the editable parts of a customer profile.
  ///
  /// The account email is intentionally not written here: it belongs to the
  /// Firebase Auth account and stays read-only in the app. A merge write keeps
  /// the shopping snapshot and other fields intact.
  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
    required String phone,
    required String photoUrl,
    required Map<String, String> address,
  }) async {
    await _users.doc(uid).set({
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'address': {
        'street': address['street'] ?? '',
        'barangay': address['barangay'] ?? '',
        'city': address['city'] ?? '',
        'province': address['province'] ?? '',
        'postalCode': address['postalCode'] ?? '',
        'phone': address['phone'] ?? phone,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Gets the saved shipping address for a user.
  /// Returns a map with street, barangay, city, province, postalCode, phone.
  Future<Map<String, dynamic>> getUserAddress(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      return {
        'street': '',
        'barangay': '',
        'city': '',
        'province': '',
        'postalCode': '',
        'phone': '',
      };
    }
    final data = doc.data() ?? {};
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      return {
        'street': '',
        'barangay': '',
        'city': '',
        'province': '',
        'postalCode': '',
        'phone': data['phone'] as String? ?? '',
      };
    }
    return {
      'street': address['street'] as String? ?? data['street'] as String? ?? '',
      'barangay':
          address['barangay'] as String? ?? data['barangay'] as String? ?? '',
      'city': address['city'] as String? ?? data['city'] as String? ?? '',
      'province':
          address['province'] as String? ?? data['province'] as String? ?? '',
      'postalCode':
          address['postalCode'] as String? ??
          data['postalCode'] as String? ??
          '',
      'phone': address['phone'] as String? ?? data['phone'] as String? ?? '',
    };
  }

  /// Saves the shipping address for a user in Firestore.
  ///
  /// Uses a merge write so a customer whose profile document was never
  /// created (for example an older account) can still save an address.
  Future<void> saveUserAddress(String uid, Map<String, dynamic> address) async {
    await _users.doc(uid).set({
      'address': {
        'street': address['street'] ?? '',
        'barangay': address['barangay'] ?? '',
        'city': address['city'] ?? '',
        'province': address['province'] ?? '',
        'postalCode': address['postalCode'] ?? '',
        'phone': address['phone'] ?? '',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
