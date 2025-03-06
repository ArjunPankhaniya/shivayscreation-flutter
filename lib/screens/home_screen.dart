import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'add_category_product_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const HomeScreen({super.key, required this.onCartUpdated});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _cartCount = 0;
  final List<Map<String, dynamic>> _cartItems = [];
  final String userId = "currentUserId";



  // set _firebaseCartItems(List<Map<String, dynamic>> _firebaseCartItems) {} // Replace with the current user's ID

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Update Firestore with the cart item
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(product['name'])
        .set({
      'name': product['name'],
      'price': product['price'],
      'quantity': (product['quantity'] ?? 0) + 1,
      'imageUrl': product['imageUrl'],
    }, SetOptions(merge: true));

    setState(() {
      final existingProduct = _cartItems.firstWhere(
            (item) => item['name'] == product['name'],
        orElse: () => {},
      );

      if (existingProduct.isNotEmpty) {
        existingProduct['quantity'] += 1;
      } else {
        _cartItems.add({
          'name': product['name'] ?? 'Unknown Product',
          'price': product['price'] ?? 0.0,
          'imageUrl': product['imageUrl'] ?? 'assets/images/placeholder.png',
          'quantity': 1,
        });
      }

      // Recalculate the cart count
      _cartCount = _cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

      widget.onCartUpdated(_cartItems);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} added to cart!'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              _removeFromCart(product);
            },
          ),
        ),
      );
    });
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      _cartItems.removeWhere((item) => item['name'] == product['name']);
      _cartCount = _cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
      widget.onCartUpdated(_cartItems);
    });

    // Remove from Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(product['name'])
        .delete();
  }

  Future<void> _fetchCartFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');
        final cartSnapshot = await cartRef.get();
        final cartItems = cartSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Include document ID for reference
          return data;
        }).toList();

        setState((dynamic _firebaseCartItems) {
          _firebaseCartItems = cartItems;
          _cartCount = _firebaseCartItems.fold(0, (sum, item) => sum + (item['quantity'] ?? 0)); // Sum the quantities
          widget.onCartUpdated(_firebaseCartItems); // Notify the parent widget of the update
        } as VoidCallback);
      }
    } catch (e) {
      print("Error fetching cart from Firebase: $e");
    }
  }


  // Fetch cart items from Firestore
  void _fetchCartItems() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _cartItems.clear();
        snapshot.docs.forEach((doc) {
          _cartItems.add(doc.data() as Map<String, dynamic>);
        });
        _cartCount = _cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCartItems();  // Fetch cart items when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shivay\'s Creation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Go to Cart',
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 6, // Slightly reduce from 10 to position better
                  top: 6,   // Adjust the vertical position
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),



      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeContent(
            onAddToCart: _addToCart,
            onRemoveFromCart: _removeFromCart,
            onCartUpdated: widget.onCartUpdated,
          ),
          CartScreen(
            cartItems: _cartItems,
            onCartUpdated: widget.onCartUpdated,
          ),
          const ProfileScreen(),
          const AddCategoryProductScreen(),
          CategoriesScreen(
            cartItems: _cartItems,
            onAddToCart: _addToCart,
            onCartUpdated: widget.onCartUpdated,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onRemoveFromCart;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const _HomeContent({
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    const String placeholderImage = 'assets/images/placeholder.png';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('categories').limit(7).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading categories. Please try again later.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No categories available. Add some categories!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final categories = snapshot.data!.docs;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: CarouselSlider(
                  items: categories.map((category) {
                    final categoryData =
                    category.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoriesScreen(
                              cartItems: [],
                              onAddToCart: onAddToCart,
                              onCartUpdated: onCartUpdated,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10)),
                              child: Image.network(
                                categoryData['imageUrl'] ?? placeholderImage,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    placeholderImage,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                categoryData['name'] ?? 'Unknown Category',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 230.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.8,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('products').limit(10).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading products. Please try again later.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No products available. Add some products!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final products = snapshot.data!.docs;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.70,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product =
                  products[index].data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            product: product,
                            onAddToCart: onAddToCart,
                            onRemoveFromCart: onRemoveFromCart,
                            onCartUpdated: onCartUpdated,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Image.network(
                              product['imageUrl'] ?? placeholderImage,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  placeholderImage,
                                  height: 120,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              product['name'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '\$${product['price'] ?? 0.0}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () => onAddToCart(product),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
