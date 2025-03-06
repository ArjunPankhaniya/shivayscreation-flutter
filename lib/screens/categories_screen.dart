import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart_screen.dart';
import 'products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const CategoriesScreen({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.onCartUpdated,
  });

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch categories from Firestore in real-time
  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      _firestore.collection('categories').snapshots().listen((snapshot) {
        if (mounted) {
          setState(() {
            categories = snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
          });
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching categories: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }


  // Show SnackBar for error messages with retry option
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _fetchCategories, // Retry fetching categories
        ),
      ),
    );
  }

  // Navigate to CartScreen
  void _goToCartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: widget.cartItems,
          onCartUpdated: widget.onCartUpdated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _goToCartScreen, // Navigate to CartScreen
          ),
        ],
      ),
      body: isLoadingCategories
          ? const Center(
          child: CircularProgressIndicator()) // Show loading spinner
          : categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No categories available. Try again later.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      ) // Show message if no categories exist
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'] ?? 'Unnamed Category';
          final categoryImageUrl = category['imageUrl'] ??
              'assets/images/placeholder.png';

          return InkWell(
            onTap: () {
              // Navigate to ProductsScreen when a category is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductsScreen(
                    category: categoryName,
                    onAddToCart: widget.onAddToCart,
                    onCartUpdated: widget.onCartUpdated,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // CachedNetworkImage for category image
                    CachedNetworkImage(
                      imageUrl: categoryImageUrl,
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    ),
                    const SizedBox(height: 10),
                    // Display category name
                    Text(
                      categoryName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
