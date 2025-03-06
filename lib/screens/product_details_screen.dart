import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onRemoveFromCart;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCartUpdated,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkIfProductInCart();
  }

  Future<void> _checkIfProductInCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        CollectionReference cartRef = userRef.collection('cart');

        QuerySnapshot cartSnapshot = await cartRef
            .where('name', isEqualTo: widget.product['name'])
            .get();

        if (cartSnapshot.docs.isNotEmpty) {
          setState(() {
            isInCart = true;
          });
        }
      } catch (e) {
        print('Error checking cart: $e');
      }
    }
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Add product to cart logic
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        CollectionReference cartRef = userRef.collection('cart');

        // Check if product already exists in the cart
        QuerySnapshot cartSnapshot = await cartRef
            .where('name', isEqualTo: widget.product['name'])
            .get();

        if (cartSnapshot.docs.isEmpty) {
          await cartRef.add({
            'name': widget.product['name'],
            'price': widget.product['price'],
            'image': widget.product['image'],
            'description': widget.product['description'],
            'quantity': 1, // Set quantity to 1 when first added
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added to cart!')),
          );
          setState(() {
            isInCart = true;
          });
          widget.onAddToCart(widget.product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product already in cart!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to add to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String productName = widget.product['name']?.toString() ?? 'Unnamed Product';
    final double productPrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final String? productImage = widget.product['image'];
    final String? productDescription = widget.product['description'];
    final NumberFormat currencyFormatter =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(productImage),
              const SizedBox(height: 16),
              Text(
                productName,
                style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Price: ${currencyFormatter.format(productPrice)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal),
              ),
              const SizedBox(height: 16),
              if (productDescription != null && productDescription.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    productDescription.length > 100
                        ? '${productDescription.substring(0, 100)}...'
                        : productDescription,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              if (productDescription != null && productDescription.length > 100)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Product Description'),
                          content: SingleChildScrollView(
                            child: Text(productDescription),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    'Read More',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isInCart ? null : () => _handleAddToCart(context),
                icon: const Icon(Icons.shopping_cart),
                label: Text(isInCart ? 'In Cart' : 'Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInCart ? Colors.grey : Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
          )
              : const Center(
            child: Icon(Icons.image, size: 50),
          ),
        ),
      ),
    );
  }
}
