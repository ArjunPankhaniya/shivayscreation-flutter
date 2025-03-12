import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _openCheckout(); // ✅ Screen khulte hi Razorpay open hoga
  }

  /// 🛒 Open Razorpay checkout
  void _openCheckout() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    double totalPrice = cartProvider.getTotalPrice();

    var options = {
      'key': 'rzp_test_5TvoiBecBPLRvZ', // 👈 Replace with actual Test Key
      'amount': (totalPrice * 100).toInt(),
      'currency': 'INR',
      'name': 'Shivays Creation',
      'description': 'Purchase from your cart',
      'prefill': {
        'contact': '1234567890',
        'email': 'user@example.com',
      },
      'theme': {
        'color': '#3399cc'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
    }
  }

  /// ✅ Payment Success
  // Payment Successful ke baad order Firestore me store karega
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    String orderId = response.paymentId ?? 'Unknown';
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    List<Map<String, dynamic>> cartItems = cartProvider.cartItems.map((item) => {
      'productId': item['id'],
      'name': item['name'],
      'price': item['price'],
      'quantity': item['quantity'],
      'imageUrl': item['imageUrl'],
    }).toList();

    // Firestore Orders Collection me Add Karo
    await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
      'orderId': orderId,
      'userId': userId,
      'products': cartItems,
      'totalAmount': cartProvider.getTotalPrice(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Processing', // Default status
    });

    // Payment success hone ke baad cart clear karo
    cartProvider.clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful! Order ID: $orderId')),
    );

    Navigator.pop(context); // ✅ Wapas cart ya home page pe
  }

  /// ❌ Payment Failed
  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed! Please try again.")),
    );
    Navigator.pop(context); // ✅ Back after failure
  }

  /// 💳 External Wallet Used
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Using External Wallet: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Processing Payment")),
      body: Center(child: CircularProgressIndicator()), // 🔄 Show loading while payment is open
    );
  }
}
