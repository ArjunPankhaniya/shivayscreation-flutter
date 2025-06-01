import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Constants ---
const String homeRoute = '/home';
const String signupRoute = '/signup';
const String forgotPasswordRoute = '/forgot-password';
const String usersCollection = 'users';
// ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  User? _currentUserForVerification; // Store the user if email is not verified

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateEmailVerifiedStatusInFirestore(User user, bool isVerified) async {
    if (!mounted) return;
    try {
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'emailVerified': isVerified,
      });
      // print("Firestore emailVerified status updated for ${user.uid}");
    } catch (e) {
      // print("Error updating emailVerified status in Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update verification status: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_currentUserForVerification == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user context for resending email. Please try logging in again.')),
        );
      }
      return;
    }

    if (_currentUserForVerification!.emailVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your email is already verified!')),
        );
      }
      return;
    }

    // Important: Set loading true for THIS operation, independent of login button's loading
    if (mounted) setState(() => _isLoading = true);
    try {
      await _currentUserForVerification!.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent! Please check your inbox (and spam folder).')),
        );
      }
    } on FirebaseAuthException catch (e) {
      // print("Error resending verification email: ${e.code} - ${e.message}");
      String friendlyMessage = "Could not resend verification email.";
      if (e.code == 'too-many-requests') {
        friendlyMessage = "Too many requests. Please wait a bit before trying to resend.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$friendlyMessage Error: ${e.message}')),
        );
      }
    } catch (e) {
      // print("Error resending verification email: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resend verification email: ${e.toString()}')),
        );
      }
    } finally {
      // Stop loading for THIS operation
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCurrentUserEmailVerification() async {
    User? userToCheck = _auth.currentUser;

    if (userToCheck == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently logged in to check.')),
        );
      }
      return;
    }

    // Important: Set loading true for THIS operation
    if (mounted) setState(() => _isLoading = true);

    try {
      await userToCheck.reload();
      User? refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        await _updateEmailVerifiedStatusInFirestore(refreshedUser, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Email verified! Redirecting to home...')),
          );
          // Navigation happens, so the button's loading state is less critical here,
          // but good to ensure it's false in finally.
          Navigator.pushReplacementNamed(context, homeRoute);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Email still not verified. Please check your inbox.'),
              action: SnackBarAction(
                label: 'Resend',
                onPressed: () {
                  _currentUserForVerification = refreshedUser;
                  _resendVerificationEmail(); // This will manage its own loading
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // print("Error during manual email verification check: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification: ${e.toString()}')),
        );
      }
    } finally {
      // Stop loading for THIS operation
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!mounted) return;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Email and Password cannot be empty')),
      );
      return; // No loading started, so no need to set it false
    }

    setState(() => _isLoading = true);
    _currentUserForVerification = null;

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload();
        User? refreshedUser = _auth.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          await _updateEmailVerifiedStatusInFirestore(refreshedUser, true);
          if (mounted) {
            Navigator.pushReplacementNamed(context, homeRoute);
            // After navigation, this screen might be disposed,
            // but setting isLoading to false is still good practice.
          }
        } else if (refreshedUser != null && !refreshedUser.emailVerified) {
          _currentUserForVerification = refreshedUser;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('⚠️ Please verify your email to log in.'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resend Email',
                  onPressed: _resendVerificationEmail, // This manages its own loading state
                ),
              ),
            );
            // IMPORTANT: Since we showed a SnackBar and are waiting for user action,
            // stop the main login button's loading indicator here.
            // The 'finally' block will also catch this.
            setState(() => _isLoading = false);
          }
        } else { // refreshedUser is null after successful signIn (should not happen)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful, but user data is unavailable. Please try again.')),
            );
            setState(() => _isLoading = false); // Stop loading on this unexpected state
          }
        }
      } else { // userCredential.user was null (unexpected)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login attempt failed unexpectedly. Please try again.')),
          );
          setState(() => _isLoading = false); // Stop loading
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;

      if (e.code == 'user-not-found') {
        errorMessage = 'Account not found for this email.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage Would you like to sign up?'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'Sign Up', onPressed: () { if (mounted) Navigator.pushNamed(context, signupRoute); }),
            ),
          );
          setState(() => _isLoading = false);
        }
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Account not found for this email or invalid details provided.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage Would you like to sign up?'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'Sign Up', onPressed: () { if (mounted) Navigator.pushNamed(context, signupRoute); }),
            ),
          );
          setState(() => _isLoading = false);
        }
      } else if (e.code == 'wrong-password') {
        errorMessage = '⚠️ Incorrect password for the provided email.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() => _isLoading = false);
        }
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() => _isLoading = false);
        }
      } else if (e.code == 'too-many-requests') {
        errorMessage = '⚠️ Too many login attempts. Please try again later.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() => _isLoading = false);
        }
      } else if (e.code == 'network-request-failed') {
        errorMessage = '⚠️ Network error. Please check your connection.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() => _isLoading = false);
        }
      } else {
        errorMessage = e.message ?? "An unknown authentication error occurred.";
        // print('Firebase Auth Error Code: ${e.code}, Message: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      // print("Login error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
        );
        setState(() => _isLoading = false);
      }
    } finally {
      // This finally block ensures that if _isLoading is still true for any reason
      // (e.g. successful login before navigation completes, or an unhandled path),
      // it gets reset. The specific cases above should handle most scenarios.
      // The most important role of this 'finally' now is for successful navigation
      // or if an earlier 'setState' was missed.
      if (mounted && _isLoading) {
        // Check _currentUserForVerification: if it's set and email not verified,
        // we've already handled _isLoading=false in the try block for that specific case.
        // So, only set to false if we are NOT in that "waiting for verification" state OR
        // if it's a success path.
        if (!(_currentUserForVerification != null && !_currentUserForVerification!.emailVerified)) {
          setState(() => _isLoading = false);
        } else if (_currentUserForVerification == null && _auth.currentUser == null) {
          // If no user is set for verification (e.g. login failed before user object creation)
          // and no user is logged in, definitely stop loading.
          setState(() => _isLoading = false);
        }
        // If _currentUserForVerification != null AND !emailVerified, _isLoading
        // should have been set to false when its SnackBar was shown.
        // If an action (like resend) is pressed, THAT function will set _isLoading true then false.
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, forgotPasswordRoute);
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, signupRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
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
        title: const Text('Login Page', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Login to continue your journey',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _navigateToForgotPassword, // Disable if loading
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isLoading
                    ? Container(
                  key: const ValueKey<String>('loadingIndicator'),
                  height: 50,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Colors.teal, strokeWidth: 3.0),
                )
                    : ElevatedButton(
                  key: const ValueKey<String>('loginButton'),
                  onPressed: _login, // _isLoading is implicitly handled by AnimatedSwitcher
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Login', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
              if (_currentUserForVerification != null && !_currentUserForVerification!.emailVerified)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      Text(
                        "Waiting for email verification for:",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _currentUserForVerification!.email ?? "your email",
                        style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("I've Verified, Check Again"),
                        // Disable this button if the main login (_isLoading) or its own action is loading
                        onPressed: _isLoading ? null : _checkCurrentUserEmailVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[700])),
                  TextButton(
                    onPressed: _isLoading ? null : _navigateToSignUp, // Disable if loading
                    child: const Text(
                      'Sign up',
                      style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}