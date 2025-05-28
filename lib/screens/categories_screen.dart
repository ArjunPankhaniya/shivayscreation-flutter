import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? selectedCategoryId;
  const CategoriesScreen({this.selectedCategoryId, super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? selectedCategoryId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = false;
  bool hasNavigated = false;
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.selectedCategoryId;
    _fetchCategories();
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      _categorySubscription =
          _firestore.collection('categories').snapshots().listen((snapshot) {
            if (mounted) {
              setState(() {
                categories = snapshot.docs.map((doc) {
                  return {
                    'id': doc.id,
                    ...Map<String, dynamic>.from(doc.data()),
                  };
                }).toList();

                if (selectedCategoryId != null && !hasNavigated) {
                  final selectedCategoryIndex =
                  categories.indexWhere((cat) => cat['id'] == selectedCategoryId);
                  if (selectedCategoryIndex != -1) {
                    hasNavigated = true;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductsScreen(
                          category: categories[selectedCategoryIndex]['name'],
                        ),
                      ),
                    );
                  }
                }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _fetchCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Categories',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: Colors.teal,
      //   centerTitle: true,
      // ),
      body: isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
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
      )
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
          final categoryName =
              category['name'] ?? 'Unnamed Category';
          final categoryImageUrl =
          category['imageUrl']?.toString().isNotEmpty == true
              ? category['imageUrl']
              : 'assets/images/placeholder.png';

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductsScreen(category: categoryName),
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
                    CachedNetworkImage(
                      imageUrl: categoryImageUrl,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/images/placeholder.png',
                              height: 40, width: 40),
                    ),
                    const SizedBox(height: 10),
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