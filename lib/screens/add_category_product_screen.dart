import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

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
  File? _categoryImage;  // ✅ Category ke liye
  File? _productImage;   // ✅ Product ke liye

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('categories').get();
      final fetchedCategories =
      querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (_) {
      _showSnackBar('Error fetching categories');
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.webp';

    XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      format: CompressFormat.webp,
    );

    return compressedXFile != null ? File(compressedXFile.path) : file;
  }

  Future<String?> _uploadImage(File image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      UploadTask uploadTask =
      ref.putFile(image, SettableMetadata(contentType: 'image/webp'));
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnackBar("❌ Upload Failed: $e");
      return null;
    }
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty || _categoryImage == null) {
      _showSnackBar('Category name and image required');
      return;
    }

    setState(() => isLoading = true);

    try {
      File compressedImage = await _compressImage(_categoryImage!);
      String fileName = 'categories/$categoryName.webp';
      String? imageUrl = await _uploadImage(compressedImage, fileName);
      if (imageUrl == null) return;

      await FirebaseFirestore.instance.collection('categories').add({
        'name': categoryName,
        'imageUrl': imageUrl,
      });

      _categoryController.clear();
      _fetchCategories();
      _showSnackBar('Category added successfully!');
      setState(() => _categoryImage = null); // ✅ Category image clear
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    if (selectedCategory == null || _productImage == null) {
      _showSnackBar('Please fill all details and select an image');
      return;
    }

    double? price;
    try {
      price = double.parse(_productPriceController.text.trim());
    } catch (_) {
      _showSnackBar("Invalid price entered");
      return;
    }

    setState(() => isLoading = true);

    try {
      File compressedImage = await _compressImage(_productImage!);
      String fileName =
          'products/${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.webp';
      String? imageUrl = await _uploadImage(compressedImage, fileName);
      if (imageUrl == null) return;

      await FirebaseFirestore.instance.collection('products').add({
        'name': _productNameController.text.trim(),
        'price': price,
        'description': _productDescriptionController.text.trim(),
        'category': selectedCategory,
        'imageUrl': imageUrl,
      });

      _showSnackBar('Product added successfully!');
      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      setState(() => _productImage = null); // ✅ Product image clear
    } finally {
      setState(() => isLoading = false);
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  Future<void> _pickImage(ImageSource source, bool isCategory) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isCategory) {
            _categoryImage = File(pickedFile.path);  // ✅ Category ke liye
          } else {
            _productImage = File(pickedFile.path);   // ✅ Product ke liye
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Add Category & Product'),
          backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField(_categoryController, 'Category Name'),
              // _buildImagePicker(),
              _buildActionButton('Add Category', Icons.add, _addCategory),
              _buildCategoryImagePicker(),  // ✅ Category ke liye

              const Divider(height: 30, color: Colors.grey),

              const Text('Add New Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
                decoration: _inputDecoration('Select Category'),
              ),
              const SizedBox(height: 12), // ✅ Yeh line spacing add karega
              _buildTextField(_productNameController, 'Product Name'),
              _buildTextField(_productPriceController, 'Product Price',
                  isNumeric: true),
              _buildTextField(_productDescriptionController,
                  'Product Description',
                  maxLines: 3),
              // _buildImagePicker(),
              _buildProductImagePicker(),   // ✅ Product ke liye
              _buildActionButton('Add Product', Icons.add_shopping_cart, _addProduct),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumeric = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: _inputDecoration(label),
        maxLines: maxLines,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }
  // ✅ Category Image Picker
  Widget _buildCategoryImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery, true),
              icon: const Icon(Icons.photo_library),
              label: const Text("Gallery"),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera, true),
              icon: const Icon(Icons.camera),
              label: const Text("Camera"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_categoryImage != null)
          Image.file(_categoryImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
        const SizedBox(height: 10),
      ],
    );
  }

// ✅ Product Image Picker
  Widget _buildProductImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery, false),
              icon: const Icon(Icons.photo_library),
              label: const Text("Gallery"),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera, false),
              icon: const Icon(Icons.camera),
              label: const Text("Camera"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_productImage != null)
          Image.file(_productImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
        const SizedBox(height: 10),
      ],
    );
  }




  // Widget _buildImagePicker() {
  //   return Column(
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           ElevatedButton.icon(
  //             onPressed: () => _pickImage(ImageSource.gallery, true),  // ✅ Category Image
  //             icon: const Icon(Icons.photo_library),
  //             label: const Text("Category Image"),
  //           ),
  //           ElevatedButton.icon(
  //             onPressed: () => _pickImage(ImageSource.camera, true),
  //             icon: const Icon(Icons.camera),
  //             label: const Text("Category Camera"),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 10),
  //       if (_categoryImage != null) Image.file(_categoryImage!, height: 150, width: double.infinity, fit: BoxFit.cover),  // ✅ Category Image Preview
  //
  //       const SizedBox(height: 20),
  //
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           ElevatedButton.icon(
  //             onPressed: () => _pickImage(ImageSource.gallery, false),  // ✅ Product Image
  //             icon: const Icon(Icons.photo_library),
  //             label: const Text("Product Image"),
  //           ),
  //           ElevatedButton.icon(
  //             onPressed: () => _pickImage(ImageSource.camera, false),
  //             icon: const Icon(Icons.camera),
  //             label: const Text("Product Camera"),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 10),
  //       if (_productImage != null) Image.file(_productImage!, height: 150, width: double.infinity, fit: BoxFit.cover),  // ✅ Product Image Preview
  //     ],
  //   );
  // }
}
