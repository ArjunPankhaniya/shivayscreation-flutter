import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'add_category_product_screen.dart';
import 'home_content.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'contact_screen.dart';
import 'settings_screen.dart';
import 'package:shivayscreation/providers/cart_provider.dart';
import 'my_order.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Fetching...";
  String userImageUrl = "";

  @override
  @override
  void initState() {
    super.initState();
    _fetchUserData();

    Future.microtask(() {
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).fetchCart();
      }
    });
  }


  void _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (mounted) {  // ✅ Ensure widget is still in the tree
          setState(() {
            userName = userDoc['name'] ?? "No Name";
            userImageUrl = userDoc['imageUrl'] ?? "";
          });
        }
      }
    }
  }


  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _onItemTapped(int index) {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      navigationProvider.updateIndex(index, context);
      cartProvider.fetchCart();
    });
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shivay\'s Creation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black, // ✅ Text BLACK rahega
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // ✅ Background transparent
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.teal], // ✅ Gradient Background
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlue, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(userName, style: const TextStyle(color: Colors.white)),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? "No Email", style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
                  child: userImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.teal)
                      : null,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Add Category'),
              onTap: () {
                _navigateTo(context, const AddCategoryProductScreen()); // ✅ Screen pe navigate karega
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                _navigateTo(context, const AboutScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                _navigateTo(context, const SettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                _navigateTo(context, const HelpScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone),
              title: const Text('Contact'),
              onTap: () {
                _navigateTo(context, const ContactScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: navigationProvider.selectedIndex,
        children: [
          HomeContent(onNavigateToCategories: () => _onItemTapped(1)),
          const CategoriesScreen(),
          const CartScreen(),
          MyOrdersScreen(onRefresh: () => setState(() {})), // ✅ Callback for refreshing
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
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${cartProvider.cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'My Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
