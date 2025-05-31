import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:shivayscreation/screens/add_category_product_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Fetching...";
  String userImageUrl = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Real-time listener to user data doc
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      _userStream.listen((snapshot) {
        if (mounted && snapshot.exists) {
          final data = snapshot.data();
          setState(() {
            userName = data?['name'] ?? "User Name";
            userImageUrl = data?['imageUrl'] ?? "";
          });
        }
      });
    } else {
      userName = "Guest";
      userImageUrl = "";
      _userStream = const Stream.empty();
    }

    Future.microtask(() {
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).fetchCart();
      }
    });
  }

  void _logout() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _onItemTapped(BuildContext navContext, int index, {VoidCallback? actionAfterPop}) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(navContext);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      if (actionAfterPop != null) {
        actionAfterPop();
      } else {
        final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

        navigationProvider.updateIndex(index, context);

        if (index == 2) {
          cartProvider.fetchCart();
        } else if (index == 3) {
          ordersProvider.fetchOrders(context);
        }
      }
    });
  }

  Widget _buildDrawerTile(
      BuildContext tileContext,
      IconData icon,
      String title,
      int index, {
        VoidCallback? onTapOverride,
        bool isSelected = false,
      }) {
    final color = isSelected ? Theme.of(tileContext).primaryColor : Colors.grey[700];
    final backgroundColor = isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent;

    return Material(
      color: backgroundColor,
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        onTap: () {
          if (onTapOverride != null) {
            _onItemTapped(tileContext, -1, actionAfterPop: onTapOverride);
          } else {
            _onItemTapped(tileContext, index);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Shivay\'s Creation',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.lightBlue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Builder(
        builder: (drawerContext) {
          return Drawer(
            elevation: 16.0,
            child: Column(
              children: [
                _UserHeader(
                  userName: userName,
                  userImageUrl: userImageUrl,
                  email: currentUser?.email ?? "Not logged in",
                  onEditProfile: () => _onItemTapped(drawerContext, 4),
                ),
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerTile(drawerContext, Icons.home_outlined, 'Home', 0,
                              isSelected: navigationProvider.selectedIndex == 0),
                          _buildDrawerTile(drawerContext, Icons.category_outlined, 'Categories', 1,
                              isSelected: navigationProvider.selectedIndex == 1),
                          _buildDrawerTile(drawerContext, Icons.shopping_cart_outlined, 'Cart', 2,
                              isSelected: navigationProvider.selectedIndex == 2),
                          _buildDrawerTile(drawerContext, Icons.receipt_long_outlined, 'My Orders', 3,
                              isSelected: navigationProvider.selectedIndex == 3),
                          _buildDrawerTile(drawerContext, Icons.person_outline, 'Profile', 4,
                              isSelected: navigationProvider.selectedIndex == 4),
                          const Divider(thickness: 1, indent: 16, endIndent: 16, height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: Text(
                              "More Options",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          _buildDrawerTile(drawerContext, Icons.add, 'Add', -1,
                              onTapOverride: () {
                                Navigator.push(
                                    drawerContext,
                                    MaterialPageRoute(
                                        builder: (context) => const AddCategoryProductScreen()));
                              }),
                          _buildDrawerTile(drawerContext, Icons.info_outline, 'About Us', -1,
                              onTapOverride: () {
                                Navigator.push(
                                    drawerContext,
                                    MaterialPageRoute(
                                        builder: (context) => const AboutScreen()));
                              }),
                          _buildDrawerTile(drawerContext, Icons.settings_outlined, 'Settings', -1,
                              onTapOverride: () {
                                Navigator.push(
                                    drawerContext,
                                    MaterialPageRoute(
                                        builder: (context) => const SettingsScreen()));
                              }),
                          _buildDrawerTile(drawerContext, Icons.help_outline, 'Help & Support', -1,
                              onTapOverride: () {
                                Navigator.push(
                                    drawerContext,
                                    MaterialPageRoute(
                                        builder: (context) => const HelpScreen()));
                              }),
                          _buildDrawerTile(drawerContext, Icons.contact_phone_outlined, 'Contact Us', -1,
                              onTapOverride: () {
                                Navigator.push(
                                    drawerContext,
                                    MaterialPageRoute(
                                        builder: (context) => const ContactScreen()));
                              }),
                          const Divider(thickness: 1, indent: 16, endIndent: 16, height: 20),
                          ListTile(
                            leading:
                            const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 24),
                            title: Text(
                              'Logout',
                              style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600),
                            ),
                            onTap: _logout,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: IndexedStack(
        index: navigationProvider.selectedIndex,
        children: [
          HomeContent(onNavigateToCategories: () => _onItemTapped(context, 1)),
          const CategoriesScreen(),
          const CartScreen(),
          MyOrdersScreen(onRefresh: () {
            if (mounted) setState(() {});
          }),
          const ProfileScreen(),
          // const AddCategoryProductScreen(),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (bottomNavContext) {
          return Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return BottomNavigationBar(
                currentIndex: navigationProvider.selectedIndex,
                onTap: (index) => _onItemTapped(bottomNavContext, index),
                selectedItemColor: Colors.teal,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart),
                        if (cartProvider.cartItems.isNotEmpty)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Colors.red, borderRadius: BorderRadius.circular(8)),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${cartProvider.cartItems.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  // const BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String userName;
  final String userImageUrl;
  final String email;
  final VoidCallback onEditProfile;

  const _UserHeader({
    Key? key,
    required this.userName,
    required this.userImageUrl,
    required this.email,
    required this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.lightBlue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: userImageUrl.isEmpty
            ? Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : "?",
          style: const TextStyle(fontSize: 36, color: Colors.teal),
        )
            : ClipOval(
          child: CachedNetworkImage(
            imageUrl: userImageUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) =>
            const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
      accountName: Text(userName,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )),
      accountEmail: Text(email,
          style: GoogleFonts.lato(
            fontSize: 14,
          )),
      otherAccountsPictures: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          tooltip: "Edit Profile",
          onPressed: onEditProfile,
        )
      ],
    );
  }
}
