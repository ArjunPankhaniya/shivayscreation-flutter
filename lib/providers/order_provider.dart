import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders(BuildContext context) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> ordersWithProducts = [];

      for (var orderDoc in orderSnapshot.docs) {
        var orderData = orderDoc.data() as Map<String, dynamic>;
        if (!orderData.containsKey('products') || orderData['products'] == null) continue;

        List<dynamic> products = orderData['products'];
        ordersWithProducts.add({
          'orderId': orderDoc.id,
          'totalAmount': orderData['totalAmount'] ?? 0,
          'status': orderData['status'] ?? 'Pending',
          'orderDate': orderData['timestamp'] != null
              ? (orderData['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'products': products,
        });
      }

      _orders = ordersWithProducts;
    } catch (e) {
      _orders = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching orders: $e")),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
