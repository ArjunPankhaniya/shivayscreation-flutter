import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'product_details_screen.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class ProductsScreen extends StatelessWidget {
  final String category;

  const ProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('products').where('category', isEqualTo: category).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products available in this category.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // ✅ Fix: Adjust height to prevent button cut
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productData = {
                  'id': product.id,
                  'name': product['name'] ?? 'Unnamed Product',
                  'price': product['price'] ?? 0.0,
                  'image': product['image'] ?? '',
                  'description': product['description'] ?? '',
                  'category': product['category'] ?? '',
                };

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: productData),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.grey.withAlpha((0.5 * 255).toInt()),
                    child: Column( // ✅ Fix: Ensure cart button is visible
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildProductImage(productData['image']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                productData['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${productData['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildAddToCartButton(context, productData), // ✅ Fix: Button now always visible
                        const SizedBox(height: 8), // ✅ Ensure spacing at bottom
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }



  Widget _buildProductImage(String? imageUrl) {
    const String placeholderImage = 'assets/images/placeholder.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage( // ✅ Use CachedNetworkImage for network images
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Image.asset(
            placeholderImage,
            fit: BoxFit.cover,
          ),
          errorWidget: (context, url, error) => Image.asset(
            placeholderImage,
            fit: BoxFit.cover,
          ),
        )
            : Image.asset(
          placeholderImage,
          fit: BoxFit.cover,
        ),
      ),
    );
  }


  Widget _buildAddToCartButton(BuildContext context, Map<String, dynamic> product) {
    final cartProvider = Provider.of<CartProvider>(context);
    final bool isInCart = cartProvider.cartItems.any((item) => item['id'] == product['id']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        onPressed: isInCart ? null : () => cartProvider.addToCart(product),
        icon: const Icon(Icons.shopping_cart),
        label: Text(isInCart ? 'In Cart' : 'Add to Cart'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart ? Colors.grey : Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}
