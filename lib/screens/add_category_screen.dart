import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'image_utils.dart'; // Your image utility

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  AddCategoryScreenState createState() => AddCategoryScreenState();
}

class AddCategoryScreenState extends State<AddCategoryScreen> {
  final _categoryFormKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final FocusNode _categoryFocusNode = FocusNode();
  bool _isSavingCategory = false;
  File? _categoryImage;

  @override
  void dispose() {
    _categoryController.dispose();
    _categoryFocusNode.dispose();
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

  Future<bool?> _showUpdateCategoryDialog(String categoryName) async {
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary),
              child: const Text('Update Image'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePickImage(ImageSource source) async {
    File? pickedImage = await ImageUtils.pickImage(context, source);
    if (pickedImage != null && mounted) {
      setState(() => _categoryImage = pickedImage);
    }
  }

  Future<void> _addOrUpdateCategory() async {
    _categoryFocusNode.unfocus();
    if (!_categoryFormKey.currentState!.validate()) return;
    if (_categoryImage == null) {
      _showAppSnackBar('Please select a category image.', isError: true);
      return;
    }
    if (!mounted) return;

    setState(() => _isSavingCategory = true);
    String categoryDisplayName = _categoryController.text.trim();
    String categoryNameToQuery = categoryDisplayName.toLowerCase();

    try {
      final categoriesRef = FirebaseFirestore.instance.collection('categories');
      final existingCategorySnapshot = await categoriesRef
          .where('name_lowercase', isEqualTo: categoryNameToQuery)
          .limit(1)
          .get();

      DocumentSnapshot? existingDoc;
      String? oldImageUrl;
      bool proceedWithUpload = true;

      if (existingCategorySnapshot.docs.isNotEmpty) {
        existingDoc = existingCategorySnapshot.docs.first;
        final bool? shouldUpdate = await _showUpdateCategoryDialog(categoryDisplayName);
        proceedWithUpload = shouldUpdate ?? false;

        if (!proceedWithUpload) {
          _showAppSnackBar('Operation cancelled by user.');
          if (mounted) setState(() => _isSavingCategory = false);
          return;
        }
        if ((existingDoc.data() as Map<String, dynamic>).containsKey('imageUrl')) {
          oldImageUrl = existingDoc['imageUrl'] as String?;
        }
      }

      if (proceedWithUpload) {
        File? compressedImage = await ImageUtils.compressImage(context, _categoryImage!);
        if (compressedImage == null) {
          if (mounted) setState(() => _isSavingCategory = false);
          return;
        }

        String safeFileName = categoryDisplayName
            .replaceAll(RegExp(r'[^\w\s-]+'), '')
            .replaceAll(' ', '_');
        if (safeFileName.isEmpty) safeFileName = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = 'categories/${safeFileName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.webp';

        String? newImageUrl = await ImageUtils.uploadImage(context, compressedImage, fileName);
        if (newImageUrl == null) {
          if (mounted) setState(() => _isSavingCategory = false);
          return;
        }

        if (existingDoc != null) { // Update existing
          await existingDoc.reference.update({
            'imageUrl': newImageUrl,
            'name': categoryDisplayName, // Update display name if it changed
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (mounted) _showAppSnackBar('Category image updated successfully!');
          if (oldImageUrl != null && oldImageUrl != newImageUrl) {
            await ImageUtils.deleteOldImage(context, oldImageUrl);
          }
        } else { // Add new
          await categoriesRef.add({
            'name': categoryDisplayName,
            'name_lowercase': categoryNameToQuery,
            'imageUrl': newImageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (mounted) _showAppSnackBar('Category added successfully!');
        }
        _categoryController.clear();
        if (mounted) {
          setState(() => _categoryImage = null);
          // Consider Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showAppSnackBar('An error occurred: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingCategory = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Category'),
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
                  'Category Details',
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
                ),
                const SizedBox(height: 20),
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
                      if (value.trim().length < 2) {
                        return 'Category name must be at least 2 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmittedAction: _addOrUpdateCategory,
                  ),
                ),
                const SizedBox(height: 16),
                _buildImagePickerSection(
                  title: 'Category Image*',
                  imageFile: _categoryImage,
                  onGalleryPick: () => _handlePickImage(ImageSource.gallery),
                  onCameraPick: () => _handlePickImage(ImageSource.camera),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  text: 'Save Category',
                  icon: Icons.add_circle_outline,
                  onPressed: _addOrUpdateCategory,
                  isLoading: _isSavingCategory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    VoidCallback? onFieldSubmittedAction,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction ?? TextInputAction.next,
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
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
        color: Colors.red[50],
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