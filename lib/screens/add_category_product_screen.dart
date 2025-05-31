import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class AddCategoryProductScreen extends StatefulWidget {
  const AddCategoryProductScreen({super.key});

  @override
  _AddCategoryProductScreenState createState() => _AddCategoryProductScreenState();
}

class _AddCategoryProductScreenState extends State<AddCategoryProductScreen> {
  // Form Keys
  final _categoryFormKey = GlobalKey<FormState>();
  final _productFormKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
  TextEditingController();

  // Focus Nodes
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _productNameFocusNode = FocusNode();
  final FocusNode _productPriceFocusNode = FocusNode();
  final FocusNode _productDescriptionFocusNode = FocusNode();

  String? selectedCategory;
  List<String> categories = []; // This will store display names (can be mixed case)
  Map<String, String> categoryDisplayToOriginalName = {}; // For mapping display name back to original if needed

  bool _isLoadingCategories = true;
  bool _isSavingCategory = false;
  bool _isSavingProduct = false;

  File? _categoryImage;
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
    _categoryController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    _categoryFocusNode.dispose();
    _productNameFocusNode.dispose();
    _productPriceFocusNode.dispose();
    _productDescriptionFocusNode.dispose();
    super.dispose();
  }

  void _listenToCategories() {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

    _categoriesSubscription = FirebaseFirestore.instance
        .collection('categories')
    // Assuming 'nameStored' is the field for case-insensitive matching (e.g., lowercase)
    // And 'displayName' is what you actually show to the user.
    // If you only have one 'name' field and want to sort by it:
        .orderBy('name') // Or 'displayName' if that's your primary sort key
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (!mounted) return;
      final fetchedCategories = <String>[];

      for (var doc in snapshot.docs) {
        // Assuming your category documents have a 'name' field for display
        final categoryName = doc['name'] as String;
        fetchedCategories.add(categoryName);
        // If you store a separate 'nameStored' (lowercase) and 'displayName':
        // final displayName = doc['displayName'] as String;
        // final storedName = doc['nameStored'] as String;
        // fetchedCategories.add(displayName);
        // newCategoryMap[displayName] = storedName; // Map display to stored for lookups
      }

      setState(() {
        categories = fetchedCategories;
        // categoryDisplayToOriginalName = newCategoryMap; // If using mapping

        _isLoadingCategories = false;
        if (selectedCategory != null && !categories.contains(selectedCategory)) {
          selectedCategory = null;
        }
      });
    }, onError: (error) {
      if (mounted) {
        _showSnackBar('Error fetching categories: ${error.toString()}', isError: true);
        setState(() => _isLoadingCategories = false);
      }
    });
  }

  Future<File?> _compressImage(File file) async {
    if (!mounted) return null;
    _showSnackBar('Compressing image...', duration: const Duration(seconds: 2));
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}.webp';
      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 40,
        format: CompressFormat.webp,
      );
      return compressedXFile != null ? File(compressedXFile.path) : null;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Image compression failed: ${e.toString()}', isError: true);
      }
      return null;
    }
  }

  Future<String?> _uploadImage(File image, String path) async {
    if (!mounted) return null;
    _showSnackBar('Uploading image...', duration: const Duration(seconds: 3));
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      UploadTask uploadTask =
      ref.putFile(image, SettableMetadata(contentType: 'image/webp'));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (mounted) {
        _showSnackBar("Image upload failed: ${e.message ?? e.code}", isError: true);
      }
      return null;
    } catch (e) {
      if (mounted) {
        _showSnackBar("Image upload failed: ${e.toString()}", isError: true);
      }
      return null;
    }
  }

  Future<bool?> _showUpdateCategoryDialog(BuildContext context, String categoryName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Category Exists'),
          content: Text(
              'A category named "$categoryName" (or similar) already exists. Do you want to update its image?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
              child: const Text('Update Image'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOldImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      // print("Successfully deleted old image: $imageUrl");
    } catch (e) {
      // print("Failed to delete old image ($imageUrl): $e");
      // Optionally show a non-critical error or just log it
    }
  }

  Future<void> _addCategory() async {
    _categoryFocusNode.unfocus();
    if (!_categoryFormKey.currentState!.validate()) return;
    if (_categoryImage == null) {
      _showSnackBar('Please select a category image.', isError: true);
      return;
    }
    if (!mounted) return;

    setState(() => _isSavingCategory = true);
    String categoryDisplayName = _categoryController.text.trim();
    // For case-insensitive checking, always work with a consistent format (e.g., lowercase)
    String categoryNameToQuery = categoryDisplayName.toLowerCase();

    try {
      final existingCategorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('name_lowercase', isEqualTo: categoryNameToQuery) // Query the lowercase field
          .limit(1)
          .get();

      bool proceedWithUpload = true;
      DocumentSnapshot? existingDoc;
      String? oldImageUrl;

      if (existingCategorySnapshot.docs.isNotEmpty) {
        existingDoc = existingCategorySnapshot.docs.first;
        final bool? shouldUpdate = await _showUpdateCategoryDialog(context, categoryDisplayName);
        proceedWithUpload = shouldUpdate ?? false;

        if (!proceedWithUpload) {
          _showSnackBar('Operation cancelled by user.');
          return; // Abort, finally block will set _isSavingCategory = false
        }
        // User wants to update, get old image URL for potential deletion
        if ((existingDoc.data() as Map<String, dynamic>).containsKey('imageUrl')) {
          oldImageUrl = existingDoc['imageUrl'] as String?;
        }
      }

      // Proceed if category is new OR user chose to update existing one's image
      if (proceedWithUpload) {
        File? compressedImage = await _compressImage(_categoryImage!);
        if (compressedImage == null) return; // Error shown in _compressImage

        String safeFileName = categoryDisplayName
            .replaceAll(RegExp(r'[^\w\s-]+'), '')
            .replaceAll(' ', '_');
        if (safeFileName.isEmpty) safeFileName = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = 'categories/${safeFileName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.webp'; // Add timestamp for uniqueness

        String? newImageUrl = await _uploadImage(compressedImage, fileName);
        if (newImageUrl == null) return; // Error shown in _uploadImage

        if (existingDoc != null) { // User chose to update
          await existingDoc.reference.update({
            'imageUrl': newImageUrl,
            // 'name': categoryDisplayName, // Optionally update display name if it can change
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (mounted) _showSnackBar('Category image updated successfully!');
          if (oldImageUrl != null && oldImageUrl != newImageUrl) {
            await _deleteOldImage(oldImageUrl);
          }
        } else { // Category is new
          await FirebaseFirestore.instance.collection('categories').add({
            'name': categoryDisplayName, // Store the display name
            'name_lowercase': categoryNameToQuery, // Store the lowercase name for queries
            'imageUrl': newImageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (mounted) _showSnackBar('Category added successfully!');
        }
        _categoryController.clear();
        if (mounted) {
          setState(() => _categoryImage = null);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingCategory = false);
    }
  }

  Future<void> _addProduct() async {
    FocusScope.of(context).unfocus();
    if (!_productFormKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      _showSnackBar('Please select a category for the product.', isError: true);
      return;
    }
    if (_productImage == null) {
      _showSnackBar('Please select a product image.', isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _isSavingProduct = true);

    try {
      File? compressedImage = await _compressImage(_productImage!);
      if (compressedImage == null) return;

      String userUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      String productName = _productNameController.text.trim();
      String productNameSafe = productName
          .replaceAll(RegExp(r'[^\w\s-]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      if (productNameSafe.isEmpty) productNameSafe = "product";

      String fileName =
          'products/${userUid}_${productNameSafe}_${DateTime.now().millisecondsSinceEpoch}.webp';
      String? imageUrl = await _uploadImage(compressedImage, fileName);

      if (imageUrl == null) return;

      await FirebaseFirestore.instance.collection('products').add({
        'name': productName,
        'price': double.parse(_productPriceController.text.trim()),
        'description': _productDescriptionController.text.trim(),
        'category': selectedCategory, // This should be the display name
        'imageUrl': imageUrl,
        'uploaderUid': userUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) _showSnackBar('Product added successfully!');
      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      if (mounted) {
        setState(() {
          _productImage = null;
          // selectedCategory = null; // Optionally reset
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to add product: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingProduct = false);
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? Theme.of(context).colorScheme.error
          : Colors.teal, // Or your success color
      duration: duration,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickImage(ImageSource source, bool isCategory) async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            if (isCategory) {
              _categoryImage = File(pickedFile.path);
            } else {
              _productImage = File(pickedFile.path);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category & Product'),
        backgroundColor: Colors.teal,
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
                  'Add New Category',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.teal),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _categoryFormKey,
                  child: _buildTextFormField(
                    controller: _categoryController,
                    focusNode: _categoryFocusNode,
                    label: 'Category Name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      if (value.trim().length < 2) { // Adjusted min length
                        return 'Category name must be at least 2 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    currentTheme: theme,
                    onFieldSubmittedAction: _addCategory,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryImagePicker(),
                const SizedBox(height: 12),
                _buildActionButton(
                  text: 'Save Category',
                  icon: Icons.add_circle_outline,
                  onPressed: _addCategory,
                  isLoading: _isSavingCategory,
                  theme: theme,
                ),
                const Divider(height: 40, thickness: 1, color: Colors.grey),
                Text(
                  'Add New Product',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.teal),
                ),
                const SizedBox(height: 16),
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a product name';
                          }
                          if (value.trim().length < 3) {
                            return 'Product name must be at least 3 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        currentTheme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _productPriceController,
                        focusNode: _productPriceFocusNode,
                        label: 'Product Price',
                        isNumeric: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a product price';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null) {
                            return 'Please enter a valid number';
                          }
                          if (price <= 0) {
                            return 'Price must be greater than zero';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        currentTheme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _productDescriptionController,
                        focusNode: _productDescriptionFocusNode,
                        label: 'Product Description (Optional)',
                        maxLines: 3,
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length < 10) {
                            return 'Description should be at least 10 characters if provided';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        currentTheme: theme,
                        onFieldSubmittedAction: _addProduct,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildProductImagePicker(),
                const SizedBox(height: 12),
                _buildActionButton(
                  text: 'Add Product',
                  icon: Icons.add_shopping_cart,
                  onPressed: _addProduct,
                  isLoading: _isSavingProduct,
                  theme: theme,
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
      items: categories.map((categoryDisplayName) { // Use the display names
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
      decoration: _inputDecoration('Select Category', currentTheme).copyWith(
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

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2.0),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.teal.withOpacity(0.7),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
        ),
      ),
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
    required ThemeData currentTheme,
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
      decoration: _inputDecoration(label, currentTheme),
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction ??
          (maxLines > 1 ? TextInputAction.newline : TextInputAction.done),
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

  InputDecoration _inputDecoration(String label, ThemeData currentTheme) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: currentTheme.inputDecorationTheme.fillColor ??
          currentTheme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImagePickerUI(
      String title,
      File? imageFile,
      VoidCallback onGalleryPick,
      VoidCallback onCameraPick,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
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
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 32),
                            SizedBox(height: 8),
                            Text('Preview Error',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined,
                    size: 40, color: Colors.grey.shade500),
                const SizedBox(height: 8),
                Text('No image selected',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryImagePicker() {
    return _buildImagePickerUI(
      'Category Image*',
      _categoryImage,
          () => _pickImage(ImageSource.gallery, true),
          () => _pickImage(ImageSource.camera, true),
    );
  }

  Widget _buildProductImagePicker() {
    return _buildImagePickerUI(
      'Product Image*',
      _productImage,
          () => _pickImage(ImageSource.gallery, false),
          () => _pickImage(ImageSource.camera, false),
    );
  }
}