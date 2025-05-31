import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shivayscreation/screens/payment_screen.dart'; // <<<--- ADD THIS IMPORT
import '../providers/navigation_provider.dart';
import 'package:shivayscreation/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  void _navigateToCategoriesScreen() {
    final navigationProvider =
    Provider.of<NavigationProvider>(context, listen: false);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      navigationProvider.updateIndex(1, context);
    });
  }

  void _proceedToPayment(BuildContext context, CartProvider cartProvider) async {
    double calculatedSubtotal = cartProvider.getTotalPrice();
    double calculatedShippingFee = 50.0; // Example: Fixed shipping fee
    double calculatedDiscount =
    cartProvider.getDiscount(promoCode: _appliedPromoCode);
    double calculatedFinalAmount =
        calculatedSubtotal + calculatedShippingFee - calculatedDiscount;

    if (calculatedSubtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your cart is empty. Add items to proceed.')),
      );
      return;
    }

    if (calculatedFinalAmount < 0 ) { // Check if final amount is negative
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order amount is invalid after discounts. Please review.')),
      );
      return;
    }
    if (calculatedFinalAmount == 0 && calculatedSubtotal > 0) {
      // Allow checkout if final amount is 0 due to discount making it free
      // But still, usually, you'd want to prevent if subtotal was 0 initially
      // print("Proceeding with a zero final amount due to full discount.");
    }


    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          subtotal: calculatedSubtotal,
          shippingFee: calculatedShippingFee,
          discount: calculatedDiscount,
          finalAmount: calculatedFinalAmount,
        ),
      ),
    );

    if (mounted) { // Check if the widget is still in the tree
      if (paymentResult != null && paymentResult is Map) {
        bool success = paymentResult['success'] ?? false;
        String? orderId = paymentResult['orderId'];

        if (success && orderId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Successful! Order ID: $orderId')),
          );
          // Potentially navigate away or clear local state if needed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Payment failed, was cancelled, or order could not be saved.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment process was not completed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Shopping Cart'),
        backgroundColor: Colors.transparent   ,
        foregroundColor: Colors.black,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCartView(context)
          : _buildCartItemsListView(context, cartProvider),
    );
  }

  Widget _buildEmptyCartView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.lightBlue),
          const SizedBox(height: 10),
          const Text('Your cart is empty!',
              style: TextStyle(fontSize: 18, color: Colors.lightBlue)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToCategoriesScreen,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
            child: const Text('Explore Products',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildCartItemsListView(
      BuildContext context, CartProvider cartProvider) {
    double subtotal = cartProvider.getTotalPrice();
    double shipping = 50.0; // Example, make this dynamic if needed
    double discount = cartProvider.getDiscount(promoCode: _appliedPromoCode);
    double finalTotal = subtotal + shipping - discount;
    if (finalTotal < 0) finalTotal = 0; // Ensure total doesn't go negative

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];
                final itemPrice = (item['price'] ?? 0.0) as num;
                final itemQuantity = (item['quantity'] ?? 1) as int;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          item['imageUrl'] ??
                              'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                    title: Text(item['name'] ?? 'Unnamed Product',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price: ₹${itemPrice.toStringAsFixed(2)}'),
                        Text(
                            'Total: ₹${(itemPrice * itemQuantity).toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent),
                          onPressed: () => cartProvider.removeFromCart(item),
                        ),
                        Text('$itemQuantity',
                            style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.green),
                          onPressed: () => cartProvider.addToCart(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter Promo Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) { // Apply on submit
                      setState(() {
                        _appliedPromoCode = value.trim().toUpperCase();
                      });
                      if (value.trim().isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Promo code "$_appliedPromoCode" applied.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Promo code removed.')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final code = _promoCodeController.text.trim().toUpperCase();
                    setState(() {
                      _appliedPromoCode = code.isNotEmpty ? code : null;
                    });
                    if (code.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Promo code "$code" applied.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promo code cleared.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          _buildPriceDetailRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
          _buildPriceDetailRow('Shipping:', '₹${shipping.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildPriceDetailRow('Discount:', '- ₹${discount.toStringAsFixed(2)}',
                isDiscount: true),
          const Divider(),
          _buildPriceDetailRow('Total Amount:', '₹${finalTotal.toStringAsFixed(2)}',
              isTotal: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (subtotal > 0) // Only enable if cart is not empty
                ? () => _proceedToPayment(context, cartProvider)
                : null, // Disable button if cart is empty
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            child: const Center(
              child: Text('Proceed to Checkout',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPriceDetailRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isDiscount
                      ? Colors.green
                      : (isTotal ? Colors.teal : Colors.black87))),
        ],
      ),
    );
  }
}