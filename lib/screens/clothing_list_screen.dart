import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingListScreen extends StatefulWidget {
  const ClothingListScreen({super.key});

  @override
  _ClothingListScreenState createState() => _ClothingListScreenState();
}

class _ClothingListScreenState extends State<ClothingListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  String selectedCategory = '';
  bool isLoadingCategories = false;
  bool isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      if (mounted) {
        setState(() {
          categories = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching categories: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchProducts(String category) async {
    setState(() {
      isLoadingProducts = true;
      selectedCategory = category;
    });
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();
      if (mounted) {
        setState(() {
          products = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching products: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clothing Store'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Categories Section
          isLoadingCategories
              ? Center(child: CircularProgressIndicator())
              : categories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          var category = categories[index];
                          bool isSelected =
                              category['name'] == selectedCategory;
                          return GestureDetector(
                            onTap: () => _fetchProducts(category['name']),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 8.0),
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(8.0),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  category['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

          // Products Section
          Expanded(
            child: isLoadingProducts
                ? Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Text(
                          selectedCategory.isEmpty
                              ? 'Select a category to view products.'
                              : 'No products available in this category.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var product = products[index];
                          const String placeholderImage =
                              "Image.asset('assets/images/placeholder.png', fit: BoxFit.cover)";
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                product['name'] ?? 'No Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Price: ₹${product['price']?.toString() ?? '0.0'}'),
                              leading: product['image'] != null &&
                                      product['image'] != ''
                                  ? Image.network(
                                      product['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      placeholderImage,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                              onTap: () => _navigateToProductDetails(product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Product Details Screen
class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['image'] != null && product['image'] != '')
              Image.network(product['image'], height: 200, fit: BoxFit.cover)
            else
              Icon(Icons.image_not_supported, size: 100),
            SizedBox(height: 16),
            Text(
              product['name'] ?? 'No Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Price: ₹${product['price']?.toString() ?? '0.0'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              product['description'] ?? 'No Description Available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
