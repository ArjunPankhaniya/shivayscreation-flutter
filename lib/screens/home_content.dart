import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'product_details_screen.dart';
import 'categories_screen.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class HomeContent extends StatelessWidget {
  final VoidCallback onNavigateToCategories; // Callback to switch tab

  const HomeContent({required this.onNavigateToCategories, super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    // final cartProvider = Provider.of<CartProvider>(context);
    const String placeholderImage = 'assets/images/placeholder.png';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 CATEGORIES SECTION
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('categories').limit(7).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No categories available.'),
                );
              }

              final categories = snapshot.data!.docs;

              return CarouselSlider(
                items: categories.map((category) {
                  final categoryData = category.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      String categoryId = category.id; // ✅ Correct usage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoriesScreen(selectedCategoryId: categoryId),
                        ),
                      );

                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              categoryData['imageUrl'] ?? '',
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  placeholderImage,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              categoryData['name'] ?? 'Unknown Category',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                options: CarouselOptions(height: 230.0, autoPlay: true, enlargeCenterPage: true),
              );
            },
          ),

          /// 🔹 PRODUCTS SECTION
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('products').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No products available.'),
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
                  final productId = products[index].id; // Firestore se directly document id lo
                  final productData = products[index].data() as Map<String, dynamic>;

                  // ✅ Create a new map instead of modifying Firestore data
                  final product = {...productData, 'id': productId};

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              product['imageUrl'] ?? '',
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(placeholderImage, height: 130, fit: BoxFit.contain);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              product['name'] ?? 'Unknown Product',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '₹${product['price'] ?? 0.0}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              final bool isInCart = cartProvider.cartItems.any((item) => item['id'] == productId);

                              return ElevatedButton(
                                onPressed: isInCart ? null : () {
                                  cartProvider.addToCart(product);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInCart ? Colors.grey : Colors.blue,
                                ),
                                child: Text(
                                  isInCart ? 'In Cart' : 'Add to Cart',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            },
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
