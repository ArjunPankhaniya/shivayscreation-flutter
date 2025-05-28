import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'product_details_screen.dart';
import 'categories_screen.dart';
import 'package:shivayscreation/providers/cart_provider.dart';

class HomeContent extends StatelessWidget {
  final VoidCallback onNavigateToCategories;

  const HomeContent({required this.onNavigateToCategories, super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
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
                  final imageUrl = categoryData['imageUrl']?.toString().isNotEmpty == true
                      ? categoryData['imageUrl']
                      : placeholderImage;

                  return GestureDetector(
                    onTap: () {
                      String categoryId = category.id;
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
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(placeholderImage, fit: BoxFit.cover);
                                },
                              ),
                            ),
                          ),
                          Container(
                            height: 40,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              categoryData['name'] ?? 'Unknown Category',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 240.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
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
                  crossAxisCount: 2,          // ✅ Number of columns (2 in this case)
                  crossAxisSpacing: 0,       // ✅ Horizontal spacing between grid items
                  mainAxisSpacing: 0,        // ✅ Vertical spacing between grid items
                  childAspectRatio: 0.70,     // ✅ Width-to-height ratio of each grid item
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productId = products[index].id;
                  final productData = products[index].data() as Map<String, dynamic>;
                  final product = {...productData, 'id': productId};

                  final imageUrl = product['imageUrl']?.toString().isNotEmpty == true
                      ? product['imageUrl']
                      : placeholderImage;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(placeholderImage, fit: BoxFit.cover);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Column(
                              children: [
                                Text(
                                  product['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${product['price'] ?? 0.0}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Consumer<CartProvider>(
                                  builder: (context, cartProvider, child) {
                                    final bool isInCart = cartProvider.cartItems.any((item) => item['id'] == productId);

                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isInCart ? null : () {
                                          cartProvider.addToCart(product);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isInCart ? Colors.grey[400] : Colors.blue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        child: Text(
                                          isInCart ? 'In Cart' : 'Add to Cart',
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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
