import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart'; // Assuming your CartProvider path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Configuration (Best Practice: Move to a separate, gitignored file) ---
class AppConfig {
  static const String razorpayKeyId = 'rzp_test_5TvoiBecBPLRvZ'; // <<< REPLACE THIS
// For production, use your live key and consider loading from .env
// static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'YOUR_DEFAULT_TEST_KEY');
}
// --- End Configuration ---

// --- Firestore Constants ---
const String _kOrdersCollection = 'orders';
// --- End Firestore Constants ---

// --- Basic Order Data Model (Modified to include more details) ---
class OrderData {
  final String orderId; // Usually the paymentId from Razorpay or your own generated ID
  final String userId;
  final List<Map<String, dynamic>> products;
  final double subtotal; // Price before discount and shipping
  final double shippingFee;
  final double discountApplied;
  final double totalAmount; // Final amount paid by customer (subtotal + shipping - discount)
  final Timestamp timestamp;
  final String status;
  final String paymentMethod;
  final String? razorpayPaymentId;
  final String? razorpayOrderId; // If you generate order_id on backend first
  final String? razorpaySignature; // For verification

  OrderData({
    required this.orderId,
    required this.userId,
    required this.products,
    required this.subtotal,
    required this.shippingFee,
    required this.discountApplied,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
    this.paymentMethod = 'Razorpay',
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'products': products,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discountApplied': discountApplied,
      'totalAmount': totalAmount,
      'timestamp': timestamp,
      'status': status,
      'paymentMethod': paymentMethod,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    };
  }
}
// --- End Order Data Model ---

class PaymentScreen extends StatefulWidget {
  // <<<--- MODIFIED CONSTRUCTOR --- >>>
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double finalAmount; // This is the amount Razorpay will charge

  const PaymentScreen({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.finalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessingOrder = false;
  bool _isRazorpayLoading = true;
  String? _lastOrderIdAttempted; // To return in case of failure after Firestore success

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openCheckout();
      }
    });
  }

  void _openCheckout() {
    if (!mounted) return;

    // Use widget.finalAmount passed from CartScreen
    double amountToPay = widget.finalAmount;

    if (amountToPay <= 0 && widget.subtotal > 0) {
      // This means the order is free due to discounts.
      // Razorpay might not handle 0 amount payments directly in the same way.
      // You might need a different flow for 100% discounted orders.
      // For now, if it's truly free, we can simulate a success and save the order.
      // print("Order is free due to discounts. Processing as successful.");
      // Simulate a successful "payment" for free orders
      _handleFreeOrderSuccess();
      return;
    }
    if (amountToPay <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount. Cannot proceed with payment.')),
      );
      _finishPaymentProcess(success: false); // Pop with failure
      return;
    }


    final currentUser = FirebaseAuth.instance.currentUser;
    String userContact = currentUser?.phoneNumber ?? '9999999999'; // Fallback
    String userEmail = currentUser?.email ?? 'guest@example.com'; // Fallback

    var options = {
      'key': AppConfig.razorpayKeyId,
      'amount': (amountToPay * 100).toInt(), // Amount in paise
      'currency': 'INR',
      'name': "Shivay's Creation",
      'description': 'Order Payment',
      // 'order_id': serverGeneratedOrderId, // If you create order on backend first
      'prefill': {
        'contact': userContact,
        'email': userEmail,
      },
      'theme': {
        'color': Theme.of(context).primaryColor.toHex(),
      },
      'timeout': 300, // 5 minutes
    };

    try {
      setState(() {
        _isRazorpayLoading = true;
      });
      _razorpay.open(options);
    } catch (e) {
      // print("Error opening Razorpay: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate payment. Error: ${e.toString()}')),
      );
      if (mounted) {
        setState(() {
          _isRazorpayLoading = false;
        });
        _finishPaymentProcess(success: false); // Pop with failure
      }
    }
  }

  // Special handler for orders that are free after discounts
  void _handleFreeOrderSuccess() async {
    if (!mounted) return;

    setState(() {
      _isRazorpayLoading = false;
      _isProcessingOrder = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_free_order';
    final generatedOrderId = 'FREE-${DateTime.now().millisecondsSinceEpoch}'; // Generate a unique ID for free orders
    _lastOrderIdAttempted = generatedOrderId;


    List<Map<String, dynamic>> cartItems = cartProvider.cartItems.map((item) {
      return {
        'productId': item['id']?.toString() ?? 'unknown_id',
        'name': item['name']?.toString() ?? 'Unknown Product',
        'price': (item['price'] is num) ? item['price'] : (double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0),
        'quantity': (item['quantity'] is int) ? item['quantity'] : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1),
        'imageUrl': item['imageUrl']?.toString() ?? '',
      };
    }).toList();

    final newOrder = OrderData(
      orderId: generatedOrderId,
      userId: userId,
      products: cartItems,
      subtotal: widget.subtotal,
      shippingFee: widget.shippingFee,
      discountApplied: widget.discount,
      totalAmount: widget.finalAmount, // Should be 0.0 for free orders
      timestamp: Timestamp.now(),
      status: 'Completed (Free)',
      paymentMethod: 'Discount (100%)',
    );

    try {
      await FirebaseFirestore.instance
          .collection(_kOrdersCollection)
          .doc(newOrder.orderId)
          .set(newOrder.toMap());

      await cartProvider.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order Placed (Free)! Order ID: ${newOrder.orderId}')),
      );
      _finishPaymentProcess(success: true, orderId: newOrder.orderId);
    } catch (e) {
      // print("Firestore Error (Free Order): Failed to save order - $e. Order ID: ${newOrder.orderId}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save your free order. Please contact support with Order ID: ${newOrder.orderId}')),
      );
      _finishPaymentProcess(success: false, orderId: newOrder.orderId); // Success false as order save failed
    }
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() {
      _isRazorpayLoading = false;
      _isProcessingOrder = true;
    });

    final paymentId = response.paymentId;
    final serverOrderId = response.orderId; // Razorpay's order_id if you created one via API
    final signature = response.signature;

    if (paymentId == null) {
      // print("Critical: Razorpay payment success but no paymentId received. Response: ${response.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded, but issue saving order. Contact support.')),
      );
      _finishPaymentProcess(success: true, orderId: _lastOrderIdAttempted); // Payment was made, but order saving might fail.
      return;
    }
    _lastOrderIdAttempted = paymentId;


    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

    List<Map<String, dynamic>> cartItems = cartProvider.cartItems.map((item) {
      return {
        'productId': item['id']?.toString() ?? 'unknown_id',
        'name': item['name']?.toString() ?? 'Unknown Product',
        'price': (item['price'] is num) ? item['price'] : (double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0),
        'quantity': (item['quantity'] is int) ? item['quantity'] : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1),
        'imageUrl': item['imageUrl']?.toString() ?? '',
      };
    }).toList();

    final newOrder = OrderData(
      orderId: paymentId, // Using Razorpay paymentId as our primary orderId
      userId: userId,
      products: cartItems,
      subtotal: widget.subtotal,
      shippingFee: widget.shippingFee,
      discountApplied: widget.discount,
      totalAmount: widget.finalAmount, // The actual amount charged by Razorpay
      timestamp: Timestamp.now(),
      status: 'Processing',
      paymentMethod: 'Razorpay',
      razorpayPaymentId: paymentId,
      razorpayOrderId: serverOrderId,
      razorpaySignature: signature,
    );

    try {
      await FirebaseFirestore.instance
          .collection(_kOrdersCollection)
          .doc(newOrder.orderId)
          .set(newOrder.toMap());

      await cartProvider.clearCart(); // Clear cart only after successful save

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Successful! Order ID: ${newOrder.orderId}')),
      );
      _finishPaymentProcess(success: true, orderId: newOrder.orderId);
    } catch (e) {
      // print("Firestore Error: Failed to save order - $e. Payment ID: $paymentId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful, but failed to save order. Contact support with Payment ID: $paymentId')),
      );
      // Payment was successful, but order saving failed.
      // Return success true because payment was captured, but also provide paymentId.
      _finishPaymentProcess(success: true, orderId: paymentId, orderSaveFailed: true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    // print("Payment Failed: Code: ${response.code} Message: ${response.message} Metadata: ${response.error.toString()}");

    String displayMessage = "Payment Failed. Please try again.";
    if (response.message != null) {
      displayMessage = "Payment Failed: ${response.message}";
      // Consider parsing response.error for more detailed user messages if it's structured (e.g., JSON)
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(displayMessage)),
    );
    _finishPaymentProcess(success: false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    // print("External Wallet: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Processing via External Wallet: ${response.walletName}")),
    );
    // UI state might not change here, wait for success/error event
  }

  // <<<--- MODIFIED to return a result --- >>>
  void _finishPaymentProcess({required bool success, String? orderId, bool orderSaveFailed = false}) {
    if (mounted) {
      setState(() {
        _isProcessingOrder = false;
        _isRazorpayLoading = false;
      });
      if (Navigator.canPop(context)) {
        Navigator.pop(context, {
          'success': success,
          'orderId': orderId,
          'orderSaveFailed': orderSaveFailed, // Let CartScreen know if Firestore save failed
        });
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingMessage = "Initializing Payment...";
    if (_isRazorpayLoading && !_isProcessingOrder) {
      loadingMessage = "Connecting to Payment Gateway...";
    } else if (_isProcessingOrder) {
      loadingMessage = "Saving your order...";
    } else if (!_isRazorpayLoading && !_isProcessingOrder) {
      // This state means processing is done, about to pop or error before Razorpay
      loadingMessage = "Finalizing...";
    }

    return PopScope( // Use PopScope for more control over back navigation
      canPop: !_isProcessingOrder && !_isRazorpayLoading, // Prevent back if processing
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isProcessingOrder || _isRazorpayLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment processing. Please wait...')),
          );
        } else {
          // If not processing, allow pop but send a failure result
          _finishPaymentProcess(success: false, orderId: _lastOrderIdAttempted);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loadingMessage),
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
              if (_isProcessingOrder || _isRazorpayLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Text(
                    "Please do not press back or close the app.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension for Color to Hex string for Razorpay theme
extension ColorHex on Color {
  String toHex() {
    return '#${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }
}