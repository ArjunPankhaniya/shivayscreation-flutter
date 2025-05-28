import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shivayscreation/screens/about_screen.dart';
import 'package:shivayscreation/screens/contact_screen.dart';
import 'package:shivayscreation/screens/help_screen.dart';
import 'package:shivayscreation/screens/settings_screen.dart';
import '../providers/navigation_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'home_content.dart';
import 'package:shivayscreation/providers/cart_provider.dart';
import 'my_order.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shivayscreation/providers/order_provider.dart';

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

  void _onItemTapped(int index) async {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    navigationProvider.updateIndex(index, context);
    cartProvider.fetchCart();

    if (index == 3) {
      // Fetch orders with context for showing snackbar on error
      await Provider.of<OrdersProvider>(context, listen: false).fetchOrders(context);
    }

    setState(() {});  // Refresh UI after async calls complete
  }


  // void _navigateTo(BuildContext context, Widget screen) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => screen),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shivay\'s Creation',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 4, // ✅ Adds subtle shadow
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
                    child: userImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.teal)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? "No Email",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(Icons.home, 'Home', 0),
                  _buildDrawerTile(Icons.category, 'Categories', 1),
                  _buildDrawerTile(Icons.shopping_cart, 'Cart', 2),
                  _buildDrawerTile(Icons.person, 'Profile', 4),
                  const Divider(),
                  // _buildDrawerTile(Icons.info, 'About Us', 5),
                  // _buildDrawerTile(
                  //   Icons.settings,
                  //   'Settings',
                  //   6,  // dummy index because we're overriding navigation
                  //   onTapOverride: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  //     );
                  //   },
                  // ),
                  // _buildDrawerTile(Icons.help, 'Help & Support', 7),
                  // _buildDrawerTile(Icons.contact_phone, 'Contact', 8),
                  _buildDrawerTile(Icons.info, 'About Us', 0, onTapOverride: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  }),
                  _buildDrawerTile(Icons.settings, 'Settings', 0, onTapOverride: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }),
                  _buildDrawerTile(Icons.help, 'Help & Support', 0, onTapOverride: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  }),
                  _buildDrawerTile(Icons.contact_phone, 'Contact', 0, onTapOverride: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactScreen()),
                    );
                  }),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
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
          // const SettingsScreen(),
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

  // Widget _buildDrawerTile(IconData icon, String title, int index) {
  //   return ListTile(
  //     leading: Icon(icon, color: Colors.teal),
  //     title: Text(title, style: GoogleFonts.lato(fontSize: 16)),
  //     onTap: () {
  //       _onItemTapped(index);
  //       Navigator.pop(context);
  //     },
  //   );
  // }
  Widget _buildDrawerTile(IconData icon, String title, int index, {VoidCallback? onTapOverride}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: GoogleFonts.lato(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          _onItemTapped(index);
        }
      },
    );
  }

}
