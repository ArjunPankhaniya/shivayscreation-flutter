import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
      await user?.sendEmailVerification(); // ✅ Send Verification Email

      // Firestore me user data save karo
      await _firestore.collection('users').doc(user?.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now(),
        'emailVerified': false, // Initially false
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check your inbox.'),
        ),
      );

      await _auth.signOut(); // ✅ Logout the user after signup

      Navigator.pushReplacementNamed(context, '/login'); // ✅ Redirect to login
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sign up failed. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email is already registered. Please log in.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format. Please enter a valid email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Use a stronger password.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // **Login ke baad check karna ki email verified hai ya nahi**
  Future<void> checkEmailVerification(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      return;
    }

    await user.reload(); // 🔄 Refresh user data

    // 🔄 Firebase ka delay handle karne ke liye 3-second wait karte hain
    await Future.delayed(const Duration(seconds: 3));

    if (user.emailVerified) {
      // Firestore me update karo ki user verified hai
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home'); // ✅ Navigate only if mounted
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email before logging in.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      backgroundColor: Colors.teal[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please fill the details below to create an account.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                const SizedBox(height: 15),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                    isPhone: true),
                const SizedBox(height: 15),
                _buildTextField(
                    _addressController, 'Address', Icons.location_on),
                const SizedBox(height: 15),
                _buildTextField(
                    _emailController, 'Email Address', Icons.email,
                    isEmail: true),
                const SizedBox(height: 15),
                _buildTextField(_passwordController, 'Password', Icons.lock,
                    isPassword: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context, '/login');// ✅ Navigate to Login Page
                    },
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {bool isEmail = false, bool isPhone = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : isPhone
          ? TextInputType.phone
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (isEmail && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        if (isPhone && !RegExp(r'^\d{10}$').hasMatch(value)) {
          return 'Enter a valid 10-digit phone number';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }
}
