import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';


// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  @override
  void initState() {
    super.initState();

    // 🔹 Fetch latest cart data when entering this screen
    Future.delayed(Duration.zero, () {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }
  void _navigateToCategoriesScreen() {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // ✅ Close Cart Screen first
    }

    Future.delayed(Duration(milliseconds: 200), () { // ✅ Delay to ensure navigation update works
      navigationProvider.updateIndex(1,context); // ✅ Switch to Categories tab
    });
  }


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.teal,
      ),
      body: cartItems.isEmpty ? _buildEmptyCartView() : _buildCartItemsListView(cartProvider),
    );
  }

  /// UI for empty cart
  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.teal),
          const SizedBox(height: 10),
          const Text('Your cart is empty!', style: TextStyle(fontSize: 18, color: Colors.teal)),
          const SizedBox(height: 20),
          // ElevatedButton(
          //   onPressed: () {
          //     // ✅ FIX: Instead of opening a new "CategoriesScreen", return to Home & switch tab
          //     Navigator.pop(context);
          //   },
          //   style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          //   child: const Text('Explore Products', style: TextStyle(fontSize: 16)),
          // ),
          ElevatedButton(
            onPressed: _navigateToCategoriesScreen, // ✅ Fix navigation
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Explore Products', style: TextStyle(fontSize: 16)),
          )
      ],
      ),
    );
  }

  /// UI for cart items
  Widget _buildCartItemsListView(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];

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
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.red),
                      ),
                    ),
                    title: Text(item['name'] ?? 'Unnamed Product'),
                    subtitle: Text('Price: ₹${item['price'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => cartProvider.removeFromCart(item),
                        ),
                        Text('${item['quantity'] ?? 1}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => cartProvider.addToCart(item),
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
                const Text('Total Price:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '₹${cartProvider.getTotalPrice()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/payment'); // ✅ Navigate to Payment Screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Center(
              child: Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
