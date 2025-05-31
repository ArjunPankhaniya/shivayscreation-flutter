import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).primaryColor, // Or your success color
      duration: const Duration(seconds: 4),
    ));
  }

  static Future<File?> pickImage(BuildContext context, ImageSource source) async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70, // Initial quality, compression will reduce further
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Failed to pick image: ${e.toString()}', isError: true);
      }
    }
    return null;
  }

  static Future<File?> compressImage(BuildContext context, File file) async {
    _showSnackBar(context,'Compressing image...', );
    try {
      final dir = await getTemporaryDirectory();
      // Ensure unique filename for compressed image
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last.split('.').first}.webp';

      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 30, // Adjust quality as needed
        format: CompressFormat.webp,
      );
      if (context.mounted && compressedXFile == null) {
        _showSnackBar(context,'Image compression resulted in null file.', isError: true);
      }
      return compressedXFile != null ? File(compressedXFile.path) : null;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context,'Image compression failed: ${e.toString()}', isError: true);
      }
      return null;
    }
  }

  static Future<String?> uploadImage(BuildContext context, File image, String path) async {
    _showSnackBar(context,'Uploading image...');
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      UploadTask uploadTask = ref.putFile(image, SettableMetadata(contentType: 'image/webp'));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (context.mounted) {
        _showSnackBar(context,"Image upload failed: ${e.message ?? e.code}", isError: true);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context,"Image upload error: ${e.toString()}", isError: true);
      }
      return null;
    }
  }

  static Future<void> deleteOldImage(BuildContext context, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      // print("Successfully deleted old image: $imageUrl");
    } catch (e) {
      // print("Failed to delete old image ($imageUrl): $e");
      // Optionally show a non-critical error or just log it
      // _showSnackBar(context, "Could not delete old image: $e", isError: true); // Be cautious with this
    }
  }
}