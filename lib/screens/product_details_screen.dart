import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shivayscreation/providers/cart_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final cartProvider = Provider.of<CartProvider>(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name']?.toString() ?? 'Unnamed Product'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final bool isInCart = cartProvider.cartItems.any((item) => item['id'] == widget.product['id']);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(widget.product['image']),
                  const SizedBox(height: 16),
                  Text(
                    widget.product['name']?.toString() ?? 'Unnamed Product',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: ${currencyFormatter.format((widget.product['price'] as num?)?.toDouble() ?? 0.0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.teal),
                  ),
                  const SizedBox(height: 16),

                  if (widget.product['description'] != null && widget.product['description'].isNotEmpty)
                    _buildDescription(widget.product['description']),

                  const SizedBox(height: 24),

                  // ✅ Fix: Ensure button updates when item is added
                  ElevatedButton.icon(
                    onPressed: isInCart
                        ? null  // Disable button if product is already in cart
                        : () async {
                      await cartProvider.addToCart(widget.product);
                    },
                    icon: Icon(isInCart ? Icons.check_circle : Icons.shopping_cart),
                    label: Text(isInCart ? 'Added to Cart' : 'Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInCart ? Colors.grey : Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    const String placeholderImage = 'assets/images/placeholder.png';

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200, // Background color
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? FadeInImage.assetNetwork(
            placeholder: placeholderImage,
            image: imageUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) => Image.asset(
              placeholderImage,
              fit: BoxFit.cover,
            ),
          )
              : Image.asset(
            placeholderImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }


  Widget _buildDescription(String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).toInt()), // ✅ Fix opacity issue
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        description.length > 100 ? '${description.substring(0, 100)}...' : description,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }
}
