import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'add_category_product_screen.dart';
import 'home_content.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    // ✅ Fetch cart once when the screen initializes
    Future.delayed(Duration(milliseconds: 300), () {
      GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          body: Column(
            children: [
              TextField(),
            ],
          ),
        ),
      );
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  void _onItemTapped(int index) {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      navigationProvider.updateIndex(index,context); // ✅ Updates tab
      cartProvider.fetchCart(); // ✅ Fetch cart on every tab switch
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shivay\'s Creation',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue[800],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Go to Profile',
                onPressed: () {
                  final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                  navigationProvider.updateIndex(4, context); // ✅ Set index to Cart Tab
                },
              ),
              // if (cartProvider.cartItems.isNotEmpty)
              //   Positioned(
              //     right: 6,
              //     top: 6,
              //     child: Container(
              //       padding: const EdgeInsets.all(4),
              //       decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              //       child: Text(
              //         '${cartProvider.cartItems.length}',
              //         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: navigationProvider.selectedIndex,
        children: [
          HomeContent(onNavigateToCategories: () => _onItemTapped(1)), // ✅ Switch to Categories tab
          const CategoriesScreen(),
          const CartScreen(),
          const AddCategoryProductScreen(),
          const ProfileScreen(),


        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationProvider.selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),

          // Cart Icon with Badge
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartProvider.cartItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${cartProvider.cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),

          const BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),

    );
  }
}
