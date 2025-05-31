import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shivayscreation/firebase_options.dart';
import 'package:shivayscreation/providers/order_provider.dart';
import 'package:flutter/material.dart';
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
import 'package:shivayscreation/screens/payment_screen.dart';
import 'package:shivayscreation/screens/about_screen.dart';
import 'package:shivayscreation/screens/contact_screen.dart';
import 'package:shivayscreation/screens/help_screen.dart';
import 'package:shivayscreation/screens/settings_screen.dart';

// Providers
import 'package:shivayscreation/providers/cart_provider.dart';

// 🔥 Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(), // ✅ Start from splash
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/about': (context) => AboutScreen(),
        '/settings': (context) => SettingsScreen(),
        '/help': (context) => HelpScreen(),
        '/contact': (context) => ContactScreen(),
        '/my-order': (context) => const MyOrdersScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/productsscreen': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('category')) {
            return const Scaffold(
              body: Center(child: Text('Error: Missing category argument')),
            );
          }
          return ProductsScreen(category: args['category']);
        },
        '/profilepageupdate': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Missing user data')),
            );
          }
          return ProfileScreenUpdate(userData: args);
        },
      },
    );
  }
}


class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(
            onInitComplete: () {
              if (snapshot.hasData && snapshot.data != null) {
                cartProvider.fetchCart();
              }
            },
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          cartProvider.fetchCart();
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
