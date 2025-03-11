import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreenUpdate extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreenUpdate({super.key, required this.userData});

  @override
  _ProfileScreenUpdateState createState() => _ProfileScreenUpdateState();
}

class _ProfileScreenUpdateState extends State<ProfileScreenUpdate> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>(); // ✅ Form key for validation
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSaving = false; // ✅ Track loading state
  bool _hasChanges = false; // ✅ Detect unsaved changes

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(text: widget.userData['address']);

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ✅ Show Snackbar with Custom Styling
  void _showSnackbar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        backgroundColor: color,
      ),
    );
  }

  // ✅ Save Profile Changes with Validation
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return; // Stop if form is invalid

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        });

        _showSnackbar('Profile updated successfully!', color: Colors.green);
        setState(() => _hasChanges = false);
        Navigator.pop(context, true); // ✅ Send back update signal
      } else {
        throw 'User not found!';
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ✅ Discard Changes Confirmation Dialog
  Future<bool> _showExitConfirmation() async {
    if (!_hasChanges) return true;

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?'),
        content: Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmation, // ✅ Prevent accidental exit
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // ✅ Form widget added
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  autofocus: true, // ✅ Auto-focus on name field
                  validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
                  textInputAction: TextInputAction.next, // ✅ Move to next field
                  textCapitalization: TextCapitalization.words, // ✅ Capitalize words
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Phone number is required';
                    if (value.trim().length < 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences, // ✅ Capitalize sentences
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges, // Disable if saving
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? CircularProgressIndicator(color: Colors.white) // ✅ Show loader
                        : Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
