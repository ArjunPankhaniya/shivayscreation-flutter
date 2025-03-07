import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> get cartItems => _cartItems;

  /// Fetch cart items from Firestore in real-time
  void fetchCart() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).collection('cart').snapshots().listen((snapshot) {
        _cartItems = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        notifyListeners();
      });
    }
  }

  /// Add item to cart and sync with Firestore
  Future<void> addToCart(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final productId = product['id'] ?? product['name']; // Ensure we have a unique identifier

    final docRef = cartRef.doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await docRef.set({...product, 'quantity': 1}, SetOptions(merge: true));
    }

    fetchCart(); // Refresh UI
  }

  /// Remove item from cart and sync with Firestore
  Future<void> removeFromCart(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final productId = product['id'] ?? product['name'];

    final docRef = cartRef.doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final currentQuantity = docSnapshot['quantity'] ?? 1;
      if (currentQuantity > 1) {
        await docRef.update({'quantity': FieldValue.increment(-1)});
      } else {
        await docRef.delete();
      }
    }

    fetchCart(); // Refresh UI
  }

  /// Get total cart price
  double getTotalPrice() {
    return _cartItems.fold(0.0, (sum, item) {
      return sum + (item['price'] ?? 0) * (item['quantity'] ?? 1);
    });
  }

  /// Clear the cart after successful payment
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
    final cartSnapshot = await cartRef.get();
    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    _cartItems.clear();
    notifyListeners();
  }
}
