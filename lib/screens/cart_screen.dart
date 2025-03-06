import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'categories_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Razorpay _razorpay;
  late List<Map<String, dynamic>> _firebaseCartItems;
  late int _cartCount; // Declare _cartCount

  @override
  void initState() {
    super.initState();
    _cartCount = 0; // Initialize cart count to 0
    _razorpay = Razorpay();
    _firebaseCartItems = List.from(widget.cartItems); // Start with existing cart items
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchCartFromFirebase();
  }

  Future<void> _fetchCartFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');
        final cartSnapshot = await cartRef.get();
        final cartItems = cartSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Include document ID for reference
          return data;
        }).toList();

        setState(() {
          _firebaseCartItems = cartItems;
          _cartCount = _firebaseCartItems.fold(0, (sum, item) {
            final quantity = item['quantity'] ?? 0;
            return sum + (quantity is int ? quantity : 0); // Ensure quantity is an integer
          });
          widget.onCartUpdated(_firebaseCartItems); // Notify the parent widget of the update
        });
      }
    } catch (e) {
      _showErrorDialog("Error fetching cart from Firebase: $e");
    }
  }

  Future<void> _updateCartItemInFirebase(String itemId, int quantity) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(itemId);
        if (quantity > 0) {
          await cartRef.update({'quantity': quantity});
        } else {
          await cartRef.delete();
        }
      }
    } catch (e) {
      _showErrorDialog("Error updating cart item in Firebase: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double get totalPrice {
    return _firebaseCartItems.fold(
      0,
          (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful: ${response.paymentId}')),
    );
    // Optionally clear cart after payment
    _clearCart();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Error: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');
      final cartSnapshot = await cartRef.get();
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {
        _firebaseCartItems.clear();
        widget.onCartUpdated(_firebaseCartItems);
      });
    }
  }

  void _openCheckout() {
    var options = {
      'key': 'your_razorpay_api_key',
      'amount': (totalPrice * 100).toInt(),
      'name': 'Your Store Name',
      'description': 'Purchase from your cart',
      'prefill': {
        'contact': '1234567890',
        'email': 'user@example.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.teal,
      ),
      body: _firebaseCartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.teal,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your cart is empty!',
              style: TextStyle(fontSize: 18, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesScreen(
                      cartItems: _firebaseCartItems,
                      onAddToCart: (product) {
                        setState(() {
                          _firebaseCartItems.add(product);
                          widget.onCartUpdated(_firebaseCartItems);
                        });
                      },
                      onCartUpdated: widget.onCartUpdated,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.teal,
              ),
              child: const Text(
                'Explore Products',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _firebaseCartItems.length,
                itemBuilder: (context, index) {
                  final item = _firebaseCartItems[index];
                  final quantity = item['quantity'] ?? 1;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8.0),
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(
                          item['imageUrl'] ?? 'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(item['name'] ?? 'Unnamed Product'),
                      subtitle: Text('Price: ₹${item['price'] ?? 0}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (quantity > 1) {
                                  _firebaseCartItems[index]['quantity'] = quantity - 1;
                                  _updateCartItemInFirebase(item['id'], quantity - 1);
                                } else {
                                  _updateCartItemInFirebase(item['id'], 0);
                                  _firebaseCartItems.removeAt(index);
                                }
                                widget.onCartUpdated(_firebaseCartItems);
                              });
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _firebaseCartItems[index]['quantity'] = quantity + 1;
                                _updateCartItemInFirebase(item['id'], quantity + 1);
                                widget.onCartUpdated(_firebaseCartItems);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹$totalPrice',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _openCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.teal,
              ),
              child: const Center(
                child: Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
