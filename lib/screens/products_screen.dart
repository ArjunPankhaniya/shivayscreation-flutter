import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'product_details_screen.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

class ProductsScreen extends StatefulWidget {
  final String category;

  const ProductsScreen({super.key, required this.category});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? productStream;

  @override
  void initState() {
    print("currently on products screen");
    super.initState();
    productStream = firestore
        .collection('products')
        .where('category', isEqualTo: widget.category)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productStream,
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
                childAspectRatio: 0.70, // ✅ Ensures button visibility
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productData = {
                  'id': product.id,
                  'name': product['name'] ?? 'Unnamed Product',
                  'price': product['price'] ?? 0.0,
                  'imageUrl': product['imageUrl'] ?? '',
                  'description': product['description'] ?? '',
                  'category': product['category'] ?? '',
                };

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: productData),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.grey.withAlpha((0.5 * 255).toInt()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildProductImage(productData['imageUrl']),
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
                        _buildAddToCartButton(context, productData),
                        const SizedBox(height: 8), // ✅ Ensures spacing at bottom
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
            ? CachedNetworkImage(
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
    final bool isInCart =
    cartProvider.cartItems.any((item) => item['id'] == product['id']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        onPressed: isInCart ? null : () => cartProvider.addToCart(product),
        icon: const Icon(Icons.shopping_cart),
        label: Text(isInCart ? 'In Cart' : 'Add to Cart'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart ? Colors.grey : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}
