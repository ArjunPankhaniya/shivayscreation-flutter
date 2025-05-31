import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfileScreenUpdate extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreenUpdate({super.key, required this.userData});

  @override
  _ProfileScreenUpdateState createState() => _ProfileScreenUpdateState();
}

class _ProfileScreenUpdateState extends State<ProfileScreenUpdate> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  // Address components
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  // late TextEditingController _countryController; // Uncomment if needed

  DateTime? _selectedDateOfBirth;
  // Controller to display the formatted date in the TextFormField
  late TextEditingController _dobDisplayController;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');

    Map<String, dynamic>? addressData = widget.userData['address'] is Map
        ? widget.userData['address'] as Map<String, dynamic>
        : null;

    _streetController = TextEditingController(text: addressData?['street'] ?? '');
    _cityController = TextEditingController(text: addressData?['city'] ?? '');
    _zipController = TextEditingController(text: addressData?['zip'] ?? '');
    // _countryController = TextEditingController(text: addressData?['country'] ?? 'USA');

    _dobDisplayController = TextEditingController(); // Initialize the controller

    // Initialize DOB and update the display controller
    if (widget.userData['dateOfBirth'] != null &&
        widget.userData['dateOfBirth'] is Timestamp) {
      _selectedDateOfBirth = (widget.userData['dateOfBirth'] as Timestamp).toDate();
      // Update the display controller with the formatted date
      _dobDisplayController.text = DateFormat('dd MMMM, yyyy').format(_selectedDateOfBirth!);
    } else {
      _dobDisplayController.text = ''; // Or 'Select your date of birth'
    }

    // Add listeners to track changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _streetController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _zipController.addListener(_onFieldChanged);
    // _countryController.addListener(_onFieldChanged);
    // No listener needed for DOB controller as change is handled by _selectDateOfBirth
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _dobDisplayController.dispose(); // Dispose the DOB controller
    // _countryController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {Color color = Colors.red, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        DateTime? oldDob = _selectedDateOfBirth;
        _selectedDateOfBirth = picked;
        _dobDisplayController.text = DateFormat('dd MMMM, yyyy').format(_selectedDateOfBirth!);

        // Check if the actual DOB value has changed from what was initially loaded
        // This is important if the user picks the same date that was already there.
        DateTime? initialDobFromWidget = (widget.userData['dateOfBirth'] as Timestamp?)?.toDate();
        if (oldDob != _selectedDateOfBirth || (initialDobFromWidget != null && _selectedDateOfBirth != initialDobFromWidget) ) {
          _hasChanges = true;
        }

      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please correct the errors in the form.', icon: Icons.error_outline);
      return;
    }

    // Check if any actual data has changed
    bool dobChanged = false;
    if (_selectedDateOfBirth != null) {
      final initialDobTimestamp = widget.userData['dateOfBirth'] as Timestamp?;
      if (initialDobTimestamp == null || _selectedDateOfBirth != initialDobTimestamp.toDate()) {
        dobChanged = true;
      }
    } else if (widget.userData['dateOfBirth'] != null) {
      // DOB was cleared
      dobChanged = true;
    }


    if (!_hasChanges && !dobChanged) {
      _showSnackbar('No changes to save.', color: Colors.orange, icon: Icons.info_outline);
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic> updatedData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': {
            'street': _streetController.text.trim(),
            'city': _cityController.text.trim(),
            'zip': _zipController.text.trim(),
            // 'country': _countryController.text.trim(),
          },
          // Only include dateOfBirth in updatedData if it has actually changed or is being set
          // To clear it, send null (or use FieldValue.delete() if you prefer)
        };

        if (dobChanged) {
          if (_selectedDateOfBirth != null) {
            updatedData['dateOfBirth'] = Timestamp.fromDate(_selectedDateOfBirth!);
          } else {
            updatedData['dateOfBirth'] = null; // To clear the date
          }
        }


        await _firestore.collection('users').doc(user.uid).update(updatedData);

        _showSnackbar('Profile updated successfully!', color: Colors.green, icon: Icons.check_circle_outline);
        if (mounted) {
          setState(() {
            _hasChanges = false;
            // Optionally update widget.userData here if you need to reflect the saved state immediately
            // For example, if you allow clearing DOB, widget.userData['dateOfBirth'] should be updated.
            if (dobChanged) {
              widget.userData['dateOfBirth'] = _selectedDateOfBirth != null ? Timestamp.fromDate(_selectedDateOfBirth!) : null;
            }
          });
          Navigator.pop(context, true);
        }
      } else {
        throw 'User not found!';
      }
    } catch (e) {
      _showSnackbar('Error updating profile: $e', icon: Icons.error_outline);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _showExitConfirmation() async {
    // Check for changes before showing confirmation
    bool dobChanged = false;
    if (_selectedDateOfBirth != null) {
      final initialDobTimestamp = widget.userData['dateOfBirth'] as Timestamp?;
      if (initialDobTimestamp == null || _selectedDateOfBirth != initialDobTimestamp.toDate()) {
        dobChanged = true;
      }
    } else if (widget.userData['dateOfBirth'] != null) {
      dobChanged = true; // It was cleared
    }

    if (!_hasChanges && !dobChanged) return true; // No text changes and no DOB changes

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them and go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ??
        false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile Details'),
          backgroundColor: Colors.teal,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Personal Information"),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(labelText: 'Full Name', hintText: 'Enter your full name', icon: Icons.person_outline),
                  autofocus: true,
                  validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(labelText: 'Phone Number', hintText: 'Enter your phone number', icon: Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Phone number is required';
                    if (value.trim().length < 10 || !RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                _buildDateOfBirthField(),

                const SizedBox(height: 25),
                _buildSectionTitle("Primary Address"),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _streetController,
                  decoration: _inputDecoration(labelText: 'Street Address', hintText: 'e.g., 123 Main St, Apt 4B', icon: Icons.home_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value!.trim().isEmpty ? 'Street address cannot be empty' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: _inputDecoration(labelText: 'City', hintText: 'e.g., Anytown', icon: Icons.location_city_outlined),
                        textInputAction: TextInputAction.next,
                        validator: (value) => value!.trim().isEmpty ? 'City cannot be empty' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _zipController,
                        decoration: _inputDecoration(labelText: 'ZIP / Postal Code', hintText: 'e.g., 12345', icon: Icons.markunread_mailbox_outlined),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (value) => value!.trim().isEmpty ? 'ZIP code cannot be empty' : null,
                      ),
                    ),
                  ],
                ),
                // SizedBox(height: 15),
                // TextFormField( // Uncomment if you add country
                //   controller: _countryController,
                //   decoration: _inputDecoration(labelText: 'Country', hintText: 'e.g., USA', icon: Icons.public_outlined),
                //   textInputAction: TextInputAction.done,
                //   validator: (value) => value!.trim().isEmpty ? 'Country cannot be empty' : null,
                //   textCapitalization: TextCapitalization.words,
                // ),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.save_alt_outlined, color: Colors.white),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade700,
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, String? hintText, IconData? icon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText ?? 'Enter $labelText',
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal.shade300, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.teal.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.teal.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.teal, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.teal.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDateOfBirthField() {
    return TextFormField(
      controller: _dobDisplayController, // Use the controller here
      readOnly: true,
      onTap: () => _selectDateOfBirth(context),
      decoration: _inputDecoration(
        labelText: 'Date of Birth',
        // Hint text can be simpler now or removed if the controller handles emptiness
        hintText: 'Select your date of birth',
        icon: Icons.calendar_today_outlined,
      ),
      // Optional: Validator if DOB is mandatory
      // validator: (value) {
      //   if (_selectedDateOfBirth == null) { // or value!.isEmpty
      //     return 'Please select your date of birth';
      //   }
      //   return null;
      // },
    );
  }
}