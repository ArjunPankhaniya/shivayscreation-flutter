import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shivayscreation/screens/cart_screen.dart';
import 'package:shivayscreation/screens/forgot_password_screen.dart';
import 'package:shivayscreation/screens/products_screen.dart';
import 'package:shivayscreation/screens/profile_screen_update.dart';
import 'package:shivayscreation/screens/login_screen.dart';
import 'package:shivayscreation/screens/signup_screen.dart';
import 'package:shivayscreation/screens/home_screen.dart';
import 'package:shivayscreation/screens/profile_screen.dart';
import 'package:shivayscreation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clothing Store',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: AuthStateHandler(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(
          onCartUpdated: (updatedCartItems) {
            // Handle cart update globally or pass to another widget
          },
        ),
        '/cart': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          return CartScreen(
            cartItems: args?['cartItems'] ?? [],
            onCartUpdated: (updatedCartItems) {
              // Handle cart update here, update the cart in HomeScreen or globally
            },
          );
        },
        '/productsscreen': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null || !args.containsKey('category')) {
            return Scaffold(
              body: Center(child: Text('Error: Missing category argument')),
            );
          }

          return ProductsScreen(
            category: args['category'],
            onAddToCart: (product) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product['name']} added to cart!')),
              );
            },
            onCartUpdated: (updatedCartItems) {
              // Handle cart updated logic here, such as updating cart in HomeScreen
            },
          );
        },
        '/profile': (context) => ProfileScreen(),
        '/profilepageupdate': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return Scaffold(
              body: Center(child: Text('Error: Missing user data')),
            );
          }

          return ProfileScreenUpdate(userData: args);
        },
        '/forgot-password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 3)), // Simulate splash duration
      builder: (context, splashSnapshot) {
        if (splashSnapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (snapshot.hasData && snapshot.data != null) {
              // User is logged in
              return HomeScreen(
                onCartUpdated: (updatedCartItems) {
                  // Handle the cart update globally
                },
              );
            } else {
              // User is not logged in
              return LoginScreen();
            }
          },
        );
      },
    );
  }
}

