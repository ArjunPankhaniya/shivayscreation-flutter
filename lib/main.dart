import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shivayscreation/firebase_options.dart';


// Screens
import 'package:shivayscreation/screens/cart_screen.dart';
import 'package:shivayscreation/screens/forgot_password_screen.dart';
import 'package:shivayscreation/screens/my_order.dart';
import 'package:shivayscreation/screens/navigation_provider.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);


  // 🔥 Clear stored login data on first launch
  await clearStoredAuthData();

  // 🔥 Fetch Firebase Token
  await getFirebaseToken();

  // 🔥 Initialize Local Notifications
  await setupLocalNotifications();

  // 🔥 Request Notification Permission
  await requestNotificationPermissions();

  // 🔥 Firebase Messaging Setup
  setupFirebaseMessaging();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ✅ Clear stored user login session on first launch
Future<void> clearStoredAuthData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool("is_first_launch") ?? true;

  if (isFirstLaunch) {
    await FirebaseAuth.instance.signOut(); // Force logout on fresh install
    await prefs.setBool("is_first_launch", false);
  }
}

// ✅ Fetch Firebase Token
Future<void> getFirebaseToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedToken = prefs.getString("fcm_token");

  if (storedToken == null) {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await prefs.setString("fcm_token", fcmToken);
      debugPrint("🔥 New Firebase FCM Token: $fcmToken");
    }
  } else {
    debugPrint("✅ Existing Firebase FCM Token: $storedToken");
  }
}

// ✅ Request Notification Permission
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint("✅ Notification permission requested.");
}

// ✅ Setup Local Notifications
Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
  debugPrint("✅ Local notifications initialized.");
}

// ✅ Firebase Messaging Setup
void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Foreground message received: ${message.notification?.title}");
    showNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("➡️ User tapped the notification: ${message.notification?.title}");
  });
}

// ✅ Show Local Notification
Future<void> showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "",
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clothing Store',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthStateHandler(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/about': (context) => AboutScreen(), // 👈 Named route
        '/settings': (context) => SettingsScreen(), // 👈 Named route
        '/help': (context) => HelpScreen(),
        '/contact': (context) => ContactScreen(),
        '/my-order': (context) => const MyOrdersScreen(),
        '/payment': (context) => const PaymentScreen(), // ✅ Payment screen ka route
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
      future: FirebaseAuth.instance.authStateChanges().first, // Check login state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          cartProvider.fetchCart(); // Ensure cart fetches correctly
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
