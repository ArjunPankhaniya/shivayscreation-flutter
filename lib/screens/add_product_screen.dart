import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'image_utils.dart'; // Your image utility

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  AddProductScreenState createState() => AddProductScreenState();
}

class AddProductScreenState extends State<AddProductScreen> {
  final _productFormKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();

  final FocusNode _productNameFocusNode = FocusNode();
  final FocusNode _productPriceFocusNode = FocusNode();
  final FocusNode _productDescriptionFocusNode = FocusNode();

  String? selectedCategory;
  List<String> categories = [];
  bool _isLoadingCategories = true;
  bool _isSavingProduct = false;
  File? _productImage;

  StreamSubscription<QuerySnapshot>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _listenToCategories();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    _productNameFocusNode.dispose();
    _productPriceFocusNode.dispose();
    _productDescriptionFocusNode.dispose();
    super.dispose();
  }

  void _showAppSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _listenToCategories() {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

    _categoriesSubscription = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (!mounted) return;
      final fetchedCategories = <String>[];
      for (var doc in snapshot.docs) {
        fetchedCategories.add(doc['name'] as String);
      }
      setState(() {
        categories = fetchedCategories;
        _isLoadingCategories = false;
        if (selectedCategory != null && !categories.contains(selectedCategory)) {
          selectedCategory = null; // Reset if current selection is no longer valid
        } else if (selectedCategory == null && categories.isNotEmpty) {
          // selectedCategory = categories.first; // Optionally auto-select first
        }
      });
    }, onError: (error) {
      if (mounted) {
        _showAppSnackBar('Error fetching categories: ${error.toString()}', isError: true);
        setState(() => _isLoadingCategories = false);
      }
    });
  }

  Future<void> _handlePickImage(ImageSource source) async {
    File? pickedImage = await ImageUtils.pickImage(context, source);
    if (pickedImage != null && mounted) {
      setState(() => _productImage = pickedImage);
    }
  }

  Future<void> _addProduct() async {
    FocusScope.of(context).unfocus();
    if (!_productFormKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      _showAppSnackBar('Please select a category for the product.', isError: true);
      return;
    }
    if (_productImage == null) {
      _showAppSnackBar('Please select a product image.', isError: true);
      return;
    }
    if (!mounted) return;

    setState(() => _isSavingProduct = true);

    try {
      File? compressedImage = await ImageUtils.compressImage(context, _productImage!);
      if (compressedImage == null) {
        if (mounted) setState(() => _isSavingProduct = false);
        return;
      }

      String userUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      String productName = _productNameController.text.trim();
      String productNameSafe = productName.replaceAll(RegExp(r'[^\w\s-]+'), '').replaceAll(' ', '_').toLowerCase();
      if (productNameSafe.isEmpty) productNameSafe = "product";
      String fileName = 'products/${userUid}_${productNameSafe}_${DateTime.now().millisecondsSinceEpoch}.webp';

      String? imageUrl = await ImageUtils.uploadImage(context, compressedImage, fileName);
      if (imageUrl == null) {
        if (mounted) setState(() => _isSavingProduct = false);
        return;
      }

      await FirebaseFirestore.instance.collection('products').add({
        'name': productName,
        'price': double.parse(_productPriceController.text.trim()),
        'description': _productDescriptionController.text.trim(),
        'category': selectedCategory,
        'imageUrl': imageUrl,
        'uploaderUid': userUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showAppSnackBar('Product added successfully!');
        _productNameController.clear();
        _productPriceController.clear();
        _productDescriptionController.clear();
        setState(() {
          _productImage = null;
          // selectedCategory = null; // Optionally reset category
        });
        // Consider Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showAppSnackBar('Failed to add product: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingProduct = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Product Details',
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _productFormKey,
                  child: Column(
                    children: [
                      _buildCategoryDropdown(theme),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _productNameController,
                        focusNode: _productNameFocusNode,
                        label: 'Product Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a product name';
                          if (value.trim().length < 3) return 'Product name must be at least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _productPriceController,
                        focusNode: _productPriceFocusNode,
                        label: 'Product Price',
                        isNumeric: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a product price';
                          final price = double.tryParse(value.trim());
                          if (price == null) return 'Please enter a valid number';
                          if (price <= 0) return 'Price must be greater than zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _productDescriptionController,
                        focusNode: _productDescriptionFocusNode,
                        label: 'Product Description (Optional)',
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                            return 'Description should be at least 10 characters if provided';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmittedAction: _addProduct,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildImagePickerSection(
                  title: 'Product Image*',
                  imageFile: _productImage,
                  onGalleryPick: () => _handlePickImage(ImageSource.gallery),
                  onCameraPick: () => _handlePickImage(ImageSource.camera),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  text: 'Add Product',
                  icon: Icons.add_shopping_cart,
                  onPressed: _addProduct,
                  isLoading: _isSavingProduct,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData currentTheme) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: categories.map((categoryDisplayName) {
        return DropdownMenuItem(
          value: categoryDisplayName,
          child: Text(categoryDisplayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => selectedCategory = value);
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: 'Select Category',
        hintText: _isLoadingCategories
            ? 'Loading categories...'
            : categories.isEmpty
            ? 'No categories. Add one first.'
            : 'Select Category',
      ),
      disabledHint: _isLoadingCategories
          ? const Text('Loading categories...')
          : const Text('No categories - Add one first'),
      validator: (value) => value == null ? 'Please select a category' : null,
      isExpanded: true,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    bool isNumeric = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    VoidCallback? onFieldSubmittedAction,
  }) {
    TextInputType keyboardType;
    if (isNumeric) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else if (maxLines > 1) {
      keyboardType = TextInputType.multiline;
    } else {
      keyboardType = TextInputType.text;
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      onFieldSubmitted: (value) {
        if (onFieldSubmittedAction != null) {
          onFieldSubmittedAction();
        } else if (focusNode != null) {
          if (textInputAction == TextInputAction.next) {
            FocusScope.of(context).nextFocus();
          } else {
            focusNode.unfocus();
          }
        } else {
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildImagePickerSection({
    required String title,
    required File? imageFile,
    required VoidCallback onGalleryPick,
    required VoidCallback onCameraPick,
  }) {
    ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onGalleryPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  foregroundColor: theme.primaryColor,
                  elevation: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCameraPick,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Camera"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  foregroundColor: theme.primaryColor,
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (imageFile != null)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
                ),
              ),
            ),
          )
        else
          _buildImagePlaceholder(),
        const SizedBox(height: 16), // Added to match original structure if needed
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100], // Softer grey
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('No image selected', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red[50], // Light red background for error
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          SizedBox(height: 8),
          Text('Preview Error', style: TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}