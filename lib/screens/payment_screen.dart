import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart'; // Assuming your CartProvider path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Configuration (Best Practice: Move to a separate, gitignored file) ---
class AppConfig {
  // IMPORTANT: Replace with your ACTUAL Razorpay Test Key ID
  // It's highly recommended to load this from environment variables or a secure config file
  // and NOT hardcode it directly, especially for production keys.
  static const String razorpayKeyId = 'rzp_test_5TvoiBecBPLRvZ'; // <<< REPLACE THIS
}
// --- End Configuration ---

// --- Firestore Constants ---
const String _kOrdersCollection = 'orders';
// --- End Firestore Constants ---

// --- Basic Order Data Model ---
class OrderData {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> products;
  final double totalAmount;
  final Timestamp timestamp; // Use Firestore Timestamp for consistency
  final String status;
  final String paymentMethod; // Added payment method

  OrderData({
    required this.orderId,
    required this.userId,
    required this.products,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
    this.paymentMethod = 'Razorpay', // Default payment method
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'products': products,
      'totalAmount': totalAmount,
      'timestamp': timestamp, // Firestore will handle server timestamp if FieldValue.serverTimestamp() is used
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }
}
// --- End Order Data Model ---


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessingOrder = false; // To show loading state during Firestore save
  bool _isRazorpayLoading = true; // To show loading while Razorpay SDK is active

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Delay opening checkout slightly to ensure widget is fully built
    // and to get context for Theme if needed immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure the widget is still in the tree
        _openCheckout();
      }
    });
  }

  /// 🛒 Open Razorpay checkout
  void _openCheckout() {
    if (!mounted) return; // Check if the widget is still mounted

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    double totalPrice = cartProvider.getTotalPrice();

    if (totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Please add items to proceed.')),
      );
      Navigator.pop(context);
      return;
    }

    // --- User Information (Best Practice: Fetch from User Profile) ---
    final currentUser = FirebaseAuth.instance.currentUser;
    String userContact = currentUser?.phoneNumber ?? '9876543210'; // Fallback
    String userEmail = currentUser?.email ?? 'guest@example.com';   // Fallback
    // --- End User Information ---

    var options = {
      'key': AppConfig.razorpayKeyId,
      'amount': (totalPrice * 100).toInt(), // Amount in paise
      'currency': 'INR',
      'name': 'Shivay\'s Creation', // Your App/Company Name
      'description': 'Order from your cart',
      // 'order_id': 'YOUR_SERVER_GENERATED_ORDER_ID', // Optional: If you create an order_id on your backend first
      'prefill': {
        'contact': userContact,
        'email': userEmail,
      },
      'theme': {
        // Using Color to Hex. Make sure to define the 'toHex()' extension for Color.
        'color': Theme.of(context).primaryColor.toHex(),
      },
      // Optional: Add notes, retry options, timeout etc.
      // 'notes': {
      //   'address': 'Shipped to: User Address from profile'
      // },
      // 'retry': {'enabled': true, 'max_count': 3},
      'timeout': 300, // in seconds (default is 5 mins)
    };

    try {
      setState(() {
        _isRazorpayLoading = true; // Razorpay window is about to open
      });
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate payment. Please try again. Error: ${e.toString()}')),
      );
      if (mounted) {
        setState(() {
          _isRazorpayLoading = false;
        });
        Navigator.pop(context); // Go back if Razorpay can't even open
      }
    }
  }

  /// ✅ Payment Success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() {
      _isRazorpayLoading = false; // Razorpay UI is closed
      _isProcessingOrder = true;  // Now processing the order (saving to Firestore)
    });

    final paymentId = response.paymentId;
    final orderIdFromResponse = response.orderId; // If you passed an order_id to Razorpay
    final signature = response.signature; // For server-side verification if implemented

    if (paymentId == null) {
      print("Critical: Razorpay payment success but no paymentId received. Response: ${response.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful, but there was an issue recording your order. Please contact support.')),
      );
      _finishPaymentProcess();
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user'; // Handle guest user appropriately

    List<Map<String, dynamic>> cartItems = cartProvider.cartItems.map((item) {
      // Ensure all necessary fields are present and correctly typed
      return {
        'productId': item['id']?.toString() ?? 'unknown_id',
        'name': item['name']?.toString() ?? 'Unknown Product',
        'price': (item['price'] is num) ? item['price'] : (double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0),
        'quantity': (item['quantity'] is int) ? item['quantity'] : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1),
        'imageUrl': item['imageUrl']?.toString() ?? '',
        // Add any other product details you need, e.g., variant, SKU
      };
    }).toList();

    final newOrder = OrderData(
      orderId: paymentId, // Using paymentId as the primary orderId for simplicity
      userId: userId,
      products: cartItems,
      totalAmount: cartProvider.getTotalPrice(),
      timestamp: Timestamp.now(), // Firestore server timestamp is also an option: FieldValue.serverTimestamp()
      status: 'Processing', // Initial order status
      paymentMethod: 'Razorpay (Success)',
    );

    try {
      await FirebaseFirestore.instance
          .collection(_kOrdersCollection)
          .doc(newOrder.orderId)
          .set(newOrder.toMap());

      cartProvider.clearCart(); // Clear cart only after successful save

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Successful! Your Order ID: ${newOrder.orderId}')),
      );

      // --- Navigation (Best Practice: Navigate to an Order Confirmation Screen) ---
      // Example:
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => OrderConfirmationScreen(orderId: newOrder.orderId)),
      //   (Route<dynamic> route) => false, // Clears navigation stack
      // );
      // For now, just pop:
      // --- End Navigation ---

    } catch (e) {
      print("Firestore Error: Failed to save order - $e. Payment ID: $paymentId");
      // Potentially, you might want to store this failed order attempt locally or flag it for manual processing.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful, but failed to save your order. Please contact support with Payment ID: $paymentId')),
      );
    } finally {
      _finishPaymentProcess();
    }
  }

  /// ❌ Payment Failed
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    print("Payment Failed: Code: ${response.code} Message: ${response.message} Metadata: ${response.error.toString()}");

    // Try to parse the error message if it's JSON (Razorpay sometimes sends JSON in message)
    String displayMessage = "Payment Failed. Please try again.";
    if (response.message != null) {
      // You might want to parse response.message if it's a JSON string with more details
      // For now, keeping it simple.
      displayMessage = "Payment Failed: ${response.message}";
    }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(displayMessage)),
    );
    _finishPaymentProcess();
  }

  /// 💳 External Wallet Used
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    print("External Wallet: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Processing via External Wallet: ${response.walletName}")),
    );
    // Note: Payment success/failure will still come through the respective handlers
    // You might not need to pop here immediately, wait for success/failure event.
    // setState(() {
    //   _isRazorpayLoading = false; // Assuming external wallet takes over UI
    // });
  }

  void _finishPaymentProcess() {
    if (mounted) {
      setState(() {
        _isProcessingOrder = false;
        _isRazorpayLoading = false;
      });
      // Only pop if the screen is meant to be temporary after payment attempt
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }


  @override
  void dispose() {
    _razorpay.clear(); // Important: Clear Razorpay listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingMessage = "Processing Payment...";
    if (_isProcessingOrder) {
      loadingMessage = "Saving your order...";
    } else if (!_isRazorpayLoading && !_isProcessingOrder) {
      // This state might occur briefly if something went wrong before Razorpay even opened
      // or if all processing is done and we are about to pop.
      // Or, if you decide to keep the screen open and show a success/failure message here.
      // For now, we assume it will pop, so a generic loading is fine.
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(loadingMessage), // Dynamic title based on state
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              loadingMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for Color to Hex string for Razorpay theme
extension ColorHex on Color {
  String toHex() {
    // Ensure `Color` is `material.dart` Color.
    // Format: #RRGGBB (no alpha for Razorpay theme color)
    return '#${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }
}