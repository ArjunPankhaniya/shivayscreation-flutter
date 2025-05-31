// cart_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // For StreamSubscription

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _cartSubscription;

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void fetchCart() {
    final user = _auth.currentUser;
    _cartSubscription?.cancel();

    if (user != null) {
      _cartSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .listen((snapshot) {
        _cartItems = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        notifyListeners();
      }, onError: (error) {
        // print("Error fetching cart: $error");
        _cartItems = [];
        notifyListeners();
      });
    } else {
      _cartItems = [];
      notifyListeners();
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final productId = product['id']?.toString() ?? product['name']?.toString() ?? DateTime.now().toIso8601String(); // Ensure productId is a string

    final docRef = cartRef.doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await docRef.set({
        'id': productId, // Ensure this ID is consistent and preferably what's stored in product map
        'name': product['name'] ?? 'Unknown Product',
        'price': (product['price'] is num ? product['price'] : (double.tryParse(product['price'].toString()) ?? 0.0)),
        'imageUrl': product['imageUrl'] ?? 'assets/images/placeholder.png',
        'quantity': 1,
      }, SetOptions(merge: true));
    }
    // The stream listener in fetchCart will automatically update the UI
    // So, calling fetchCart() here explicitly might be redundant if the stream is active
    // However, if you want immediate reflection before stream updates, you can update local state
    // and then rely on stream for confirmation. For simplicity, current approach is fine.
  }

  Future<void> removeFromCart(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final productId = product['id']?.toString() ?? product['name']?.toString();

    if (productId == null) {
      // print("Error: Product ID is null, cannot remove from cart.");
      return;
    }
    final docRef = cartRef.doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final currentQuantity = (docSnapshot.data()?['quantity'] ?? 1) as int;
      if (currentQuantity > 1) {
        await docRef.update({'quantity': FieldValue.increment(-1)});
      } else {
        await docRef.delete();
      }
    }
    // Stream listener updates UI
  }

  double getTotalPrice() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = (item['price'] is num ? item['price'] : (double.tryParse(item['price'].toString()) ?? 0.0)) as num;
      final quantity = (item['quantity'] is int ? item['quantity'] : (int.tryParse(item['quantity'].toString()) ?? 1)) as int;
      return sum + (price * quantity);
    });
  }

  // <<<--- ADD THIS METHOD --- >>>
  double getSubtotal() {
    return getTotalPrice();
  }

  // <<<--- ADD THIS METHOD (Example Implementation) --- >>>
  double getDiscount({String? promoCode}) {
    double subtotal = getSubtotal();
    double discount = 0.0;

    if (promoCode == null || promoCode.isEmpty) {
      return 0.0;
    }

    // Example Promo Codes - Replace with your actual logic
    // (e.g., fetching from Firestore, checking validity, etc.)
    switch (promoCode.toUpperCase()) {
      case 'SUMMER10':
        if (subtotal > 500) {
          discount = subtotal * 0.10; // 10% discount
        } else {
          // Optionally, provide feedback if condition not met
          // print("SUMMER10 requires a subtotal over 500");
        }
        break;
      case 'FLAT50':
        discount = 50.0; // Flat 50₹ off
        break;
    // Add more promo codes as needed
      default:
        // print("Invalid promo code: $promoCode");
        discount = 0.0; // No discount for invalid codes
    }

    // Ensure discount doesn't exceed subtotal (unless you allow negative totals)
    return discount > subtotal ? subtotal : discount;
  }


  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final cartSnapshot = await cartRef.get();
    WriteBatch batch = _firestore.batch(); // Use a batch for multiple deletes
    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Local state is updated by the stream listener.
    // If you need immediate local clearing before stream syncs:
    // _cartItems.clear();
    // notifyListeners();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}