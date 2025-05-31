import 'package:flutter/material.dart'; // Keep for ChangeNotifier
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Renamed your Order model to AppOrder to avoid conflicts
class AppOrder {
  final String id; // Document ID from Firestore
  final String orderId; // Could be paymentId or your custom order ID
  final String userId;
  final List<Map<String, dynamic>> products; // Consider a ProductInOrder model too
  final double subtotal;
  final double shippingFee;
  final double discountApplied; // This is the field name in your model
  final double totalAmount;
  final DateTime orderDate;     // This is a DateTime object
  final String status;
  final String paymentMethod;
  final String? razorpayPaymentId;
  final Map<String, dynamic> paymentDetails;
  // Add any other fields you expect from your Firestore 'orders' documents

  AppOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.products,
    required this.subtotal,
    required this.shippingFee,
    required this.discountApplied,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.paymentMethod,
    this.razorpayPaymentId,
    required this.paymentDetails,
    // Initialize other fields
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppOrder(
      id: doc.id,
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0.0).toDouble(),
      // Ensure your Firestore document has 'discountApplied' or map the correct field
      discountApplied: (data['discountApplied'] ?? data['discount'] ?? 0.0).toDouble(), // Reads 'discountApplied' or fallback to 'discount'
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      // Correctly reads 'timestamp' from Firestore and converts to DateTime
      orderDate: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: data['status'] ?? 'Unknown',
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      razorpayPaymentId: data['razorpayPaymentId'],
      paymentDetails: Map<String, dynamic>.from(data['paymentDetails'] ?? {}),
    );
  }

  // This method is used when passing data to OrderDetailsScreen
  Map<String, dynamic> toMapForDetails() { // Renamed for clarity, or just modify toMap()
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'products': products,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      // Key for OrderDetailsScreen should be 'discount' if that's what it expects
      'discount': discountApplied, // Use the value from discountApplied field
      'totalAmount': totalAmount,
      // Key for OrderDetailsScreen is 'orderDate', and it expects a String
      'orderDate': orderDate.toIso8601String(), // Convert DateTime to ISO 8601 String
      'status': status,
      'paymentMethod': paymentMethod, // This might be redundant if paymentDetails also has it
      'razorpayPaymentId': razorpayPaymentId,
      'paymentDetails': paymentDetails,
      // 'shippingAddress' will be added separately in MyOrdersScreen before navigating
    };
  }

  // Original toMap() - might be used for saving back to Firestore (notice 'timestamp' and 'discountApplied')
  Map<String, dynamic> toMap() {
    return {
      'id': id, // This is usually the doc ID, not part of the data itself unless needed
      'orderId': orderId,
      'userId': userId,
      'products': products,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discountApplied': discountApplied, // Use this key for Firestore
      'totalAmount': totalAmount,
      'timestamp': Timestamp.fromDate(orderDate), // Use this key for Firestore
      'status': status,
      'paymentMethod': paymentMethod,
      'razorpayPaymentId': razorpayPaymentId,
      'paymentDetails': paymentDetails,
    };
  }
}

class OrdersProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppOrder> _orders = [];
  User? _currentUser;
  DateTime? _lastFetchTime;
  bool _isLoading = false;
  String? _error;

  List<AppOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearOrders() {
    _orders = [];
    _currentUser = null;
    _lastFetchTime = null;
    _error = null;
    notifyListeners(); // Notify if you want UI to react to clearing immediately
  }

  Future<void> fetchOrders({bool forceRefresh = false}) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      // print("OrdersProvider: No user logged in. Cannot fetch orders.");
      _orders = [];
      _currentUser = null;
      _error = "User not logged in.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _currentUser?.uid == user.uid &&
        _orders.isNotEmpty &&
        !hasError &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      // print("OrdersProvider: Using recently fetched orders for user ${user.uid}.");
      if (_isLoading) { // Ensure isLoading is reset if we skip fetch
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _error = null;
    if (_currentUser?.uid != user.uid) {
      _orders = []; // Clear old user's data
    }
    _currentUser = user;
    notifyListeners(); // Notify for loading start and user change

    try {
      // print("OrdersProvider: Fetching orders from Firestore for user ${user.uid}...");
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      _orders = orderSnapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList();
      _lastFetchTime = DateTime.now();
      // print("OrdersProvider: Successfully fetched ${_orders.length} orders.");
    } catch (e) { // Also catch stacktrace for better debugging
      // print("OrdersProvider: Error fetching orders: $e\n$s");
      _error = "Failed to load your orders. Please try again.";
      // _orders = []; // Optional: clear orders on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrderFromMap(Map<String, dynamic> newOrderDataMap) async {
    final User? user = _auth.currentUser;
    if (user == null || user.uid != newOrderDataMap['userId']) {
      _error = "User mismatch or not logged in. Cannot add order.";
      // print("OrdersProvider: $_error");
      // notifyListeners(); // Maybe not notify for this internal error, or handle differently
      return; // Early return
    }

    // You might want to show loading specifically for adding an order
    // bool _isAddingOrder = true; notifyListeners();

    _isLoading = true; // Using general isLoading, or could have a specific one
    _error = null;
    notifyListeners();

    try {
      String docId = newOrderDataMap['orderId'] ?? _firestore.collection('orders').doc().id;
      // Ensure 'timestamp' is a Timestamp; if it's already from AppOrder.toMap(), it should be.
      if (newOrderDataMap['timestamp'] == null) {
        newOrderDataMap['timestamp'] = Timestamp.now();
      } else if (newOrderDataMap['timestamp'] is DateTime) {
        newOrderDataMap['timestamp'] = Timestamp.fromDate(newOrderDataMap['timestamp'] as DateTime);
      } else if (newOrderDataMap['timestamp'] is! Timestamp) {
        // Try to parse if it's a string, otherwise default
        DateTime? dt = DateTime.tryParse(newOrderDataMap['timestamp'].toString());
        newOrderDataMap['timestamp'] = dt != null ? Timestamp.fromDate(dt) : Timestamp.now();
      }

      // Ensure 'discountApplied' field matches Firestore if it's different from 'discount'
      // If newOrderDataMap comes from a place where 'discount' is used:
      if (newOrderDataMap.containsKey('discount') && !newOrderDataMap.containsKey('discountApplied')) {
        newOrderDataMap['discountApplied'] = newOrderDataMap['discount'];
        // remove 'discount' if you want to be strict about schema, or leave it
      }


      await _firestore.collection('orders').doc(docId).set(newOrderDataMap);
      // print("OrdersProvider: Order ${newOrderDataMap['orderId']} added successfully using map.");
      await fetchOrders(forceRefresh: true); // Refresh the list
    } catch (e) { // Catch stacktrace
      // print("OrdersProvider: Error adding order from map: $e\n$s");
      _error = "Failed to save your order: $e";
    } finally {
      _isLoading = false;
      // _isAddingOrder = false;
      notifyListeners();
    }
  }
}