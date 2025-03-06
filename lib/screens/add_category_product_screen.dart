import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String placeholderImage = "assets/images/placeholder.png";

class AddCategoryProductScreen extends StatefulWidget {
  const AddCategoryProductScreen({super.key});

  @override
  _AddCategoryProductScreenState createState() =>
      _AddCategoryProductScreenState();
}

class _AddCategoryProductScreenState extends State<AddCategoryProductScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();

  String? selectedCategory;
  List<String> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    super.dispose();
  }

  /// Fetch existing categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      final fetchedCategories =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      if (mounted) {
        setState(() {
          categories = fetchedCategories;
        });
      }
    } catch (error) {
      
      _showSnackBar('Error fetching categories');
    }
  }

  /// Add a new category to Firestore
  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();

    if (categoryName.isEmpty) {
      _showSnackBar('Category name cannot be empty');
      return;
    }
    if (categories.contains(categoryName)) {
      _showSnackBar('Category "$categoryName" already exists');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': categoryName,
      });

      _categoryController.clear();
      _fetchCategories(); // Refresh categories
      _showSnackBar('Category "$categoryName" added successfully');
    } catch (e) {
      _showSnackBar('Error adding category: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Add a new product to Firestore
  Future<void> _addProduct() async {
    final productName = _productNameController.text.trim();
    final productPrice = _productPriceController.text.trim();
    final productDescription = _productDescriptionController.text.trim();

    if (selectedCategory == null) {
      _showSnackBar('Please select a category');
      return;
    }
    if (productName.isEmpty) {
      _showSnackBar('Product name cannot be empty');
      return;
    }
    if (productPrice.isEmpty || double.tryParse(productPrice) == null) {
      _showSnackBar('Please enter a valid price');
      return;
    }
    if (productDescription.isEmpty) {
      _showSnackBar('Product description cannot be empty');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final productData = {
        'name': productName,
        'price': double.parse(productPrice),
        'description': productDescription,
        'category': selectedCategory,
        'image': placeholderImage, // Placeholder image
      };

      await FirebaseFirestore.instance.collection('products').add(productData);

      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      _showSnackBar('Product "$productName" added successfully');
    } catch (e) {
      _showSnackBar('Error adding product: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Show a SnackBar with a custom message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category & Product'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add New Category
                    Text(
                      'Add New Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _addCategory,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Divider(height: 30, color: Colors.grey),

                    // Add New Product
                    Text(
                      'Add New Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedCategory = value;
                      }),
                      decoration: InputDecoration(
                        labelText: 'Select Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _productPriceController,
                      decoration: InputDecoration(
                        labelText: 'Product Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _productDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Product Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _addProduct,
                      icon: const Icon(Icons.add_shopping_cart,
                          color: Colors.white),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
