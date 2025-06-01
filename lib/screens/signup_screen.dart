import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();

        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(), // Use Firestore Timestamp for consistency
          'emailVerified': user.emailVerified, // Will be false initially after signup
          'uid': user.uid, // Good practice to store UID for easier queries
        });

        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent. Please check your inbox and log in.'),
              backgroundColor: Colors.green,
            ),
          );
          await _auth.signOut(); // Log out to force login after verification
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sign up failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered. Please log in.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      } else if (e.code == 'weak-password') {
        errorMessage = "The password is too weak (minimum 6 characters).";
      }
      // ... handle other specific Firebase Auth error codes if needed

      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        // backgroundColor: Colors.teal,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.lightBlue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0, // No shadow for a flatter look
        centerTitle: true,
      ),
      backgroundColor: Colors.teal[50], // Light teal background for the body
      body: Center( // Center the card on the screen
        child: SingleChildScrollView( // Allow scrolling on smaller screens
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 5.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Card takes minimum vertical space
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Make button full width
                  children: [
                    const Text(
                      'Welcome!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your 10-digit phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isPhone: true,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your current address',
                      icon: Icons.home_outlined, // Changed icon
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isEmail: true,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password (min. 6 characters)',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline,
                      isPassword: true, // To obscure text
                      isConfirmPassword: true,
                      originalPasswordController: _passwordController,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      child: _isLoading
                          ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                          : const Text('Sign Up', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?", style: TextStyle(color: Colors.grey[700])),
                        TextButton(
                          onPressed: () {
                            // Navigate to Login Page
                            // Ensure '/login' route exists in your MaterialApp
                            if (ModalRoute.of(context)?.settings.name != '/login') {
                              Navigator.pushReplacementNamed(context, '/login');
                            } else {
                              // If already on login or login is the immediate previous route that can be popped.
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                                color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isConfirmPassword = false,
    TextEditingController? originalPasswordController,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.teal.withOpacity(0.05), // Subtle fill color
        border: OutlineInputBorder( // Default border
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border by default, rely on enabled/focused
        ),
        enabledBorder: OutlineInputBorder( // Border when text field is enabled
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade100), // Light teal border
        ),
        focusedBorder: OutlineInputBorder( // Border when text field is focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5), // Prominent teal border
        ),
        errorBorder: OutlineInputBorder( // Border when there's a validation error
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder( // Border when focused and there's an error
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isEmail && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        if (isPhone && !RegExp(r'^\d{10}$').hasMatch(value)) {
          // Basic 10-digit phone validation. You might want a more robust regex.
          return 'Please enter a valid 10-digit phone number';
        }
        // Check password length only for the password field, not confirm password field
        if (isPassword && !isConfirmPassword && value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        // Check if confirm password matches the original password
        if (isConfirmPassword && value != originalPasswordController?.text) {
          return 'Passwords do not match';
        }
        return null; // Return null if validation passes
      },
    );
  }
}