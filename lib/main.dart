import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Uncomment if used
import 'package:shivayscreation/firebase_options.dart';
import 'package:shivayscreation/providers/order_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'package:shivayscreation/screens/cart_screen.dart';
import 'package:shivayscreation/screens/forgot_password_screen.dart';
import 'package:shivayscreation/screens/my_order.dart';
import 'package:shivayscreation/providers/navigation_provider.dart';
import 'package:shivayscreation/screens/products_screen.dart';
import 'package:shivayscreation/screens/profile_screen_update.dart';
import 'package:shivayscreation/screens/login_screen.dart';
import 'package:shivayscreation/screens/signup_screen.dart';
import 'package:shivayscreation/screens/home_screen.dart';
import 'package:shivayscreation/screens/profile_screen.dart';
import 'package:shivayscreation/screens/splash_screen.dart';
import 'package:shivayscreation/screens/about_screen.dart';
import 'package:shivayscreation/screens/contact_screen.dart';
import 'package:shivayscreation/screens/help_screen.dart';
import 'package:shivayscreation/screens/settings_screen.dart';
import 'package:shivayscreation/screens/add_product_screen.dart';
import 'package:shivayscreation/screens/add_category_screen.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

// 🔥 Local Notifications Plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin(); // Uncomment and initialize if you use it

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env").catchError((e) {
    // print("Error loading .env file: $e. Make sure it's present in the root.");
    // Handle error or proceed without .env if appropriate
  });
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications if you use them
  // var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // Replace with your app icon
  // var initializationSettingsIOS = DarwinInitializationSettings();
  // var initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   iOS: initializationSettingsIOS,
  // );
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce Store',
      theme: ThemeData(
        primarySwatch: Colors.teal, // Consider using colorScheme for more modern theming
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.amberAccent, // Example accent
          brightness: Brightness.light,
        ).copyWith(
          secondary: Colors.amberAccent, // For FloatingActionButtons, etc.
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme, // Apply Poppins to existing theme
        ),
        useMaterial3: true, // Enable Material 3 features
      ),
      // home: const SplashScreen(), // Keep SplashScreen as home
      // Use AuthStateHandler to determine initial screen based on auth state
      home: const AuthWrapper(), // <<< MODIFIED: Use a wrapper for initial auth check

      routes: {
        '/login': (context) => const LoginScreen(),
        '/add-product': (context) => const AddProductScreen(),
        '/add-category': (context) => const AddCategoryScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/about': (context) => const AboutScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/contact': (context) => const ContactScreen(),
        '/my-order': (context) => const MyOrdersScreen(),
        // '/payment': (context) => const PaymentScreen(), // <<<--- COMMENTED OUT or REMOVE
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/productsscreen': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          if (args == null || !args.containsKey('category')) {
            return const Scaffold(
              body: Center(child: Text('Error: Missing category argument')),
            );
          }
          return ProductsScreen(category: args['category'] as String);
        },
        '/profilepageupdate': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          if (args == null) {
            // It's better to provide a default or handle this more gracefully
            // For now, an error message is fine.
            return const Scaffold(
              body: Center(child: Text('Error: Missing user data for profile update')),
            );
          }
          return ProfileScreenUpdate(userData: args);
        },
      },
    );
  }
}

// Renamed AuthStateHandler to AuthWrapper for clarity, and use StreamBuilder
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes in real-time
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show SplashScreen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Just the splash screen, no onInitComplete needed here
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Fetch cart data after user is confirmed logged in
          // Ensure this doesn't cause issues if CartProvider expects user to be non-null immediately
          // It's often better to trigger fetches from within the screens themselves (e.g., HomeScreen initState)
          // or after user is fully navigated to HomeScreen.
          // However, for simplicity here, this is one way.
          Provider.of<CartProvider>(context, listen: false).fetchCart();
          return const HomeScreen();
        }
        // User is not logged in
        else {
          return const LoginScreen();
        }
      },
    );
  }
}