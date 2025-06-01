import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitComplete;
  const SplashScreen({Key? key, this.onInitComplete}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    initializeAsync();
  }

  Future<void> initializeAsync() async {
    // Your existing initialization steps
    await clearStoredAuthData(); // Be careful with this, see note below
    await getFirebaseToken();
    await setupLocalNotifications();
    await requestNotificationPermissions();
    setupFirebaseMessaging();

    // Callback if passed from main.dart
    widget.onInitComplete?.call();

    // Optional: Keep a delay if you want the splash animation to always play for a minimum duration
    // Adjust the duration as needed, or make it conditional.
    await Future.delayed(const Duration(seconds: 1)); // Shorter delay, or adjust as you see fit

    if (!mounted) return; // Safety check

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user currently signed in (or was signed out by clearStoredAuthData)
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // User exists, now check email verification status
      try {
        await user.reload();
        User? refreshedUser = FirebaseAuth.instance.currentUser; // Get the refreshed user

        if (refreshedUser != null && refreshedUser.emailVerified) {
          // User exists AND email is verified
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // User exists BUT email is NOT verified (or refreshedUser became null)
          // Navigate to login screen. Your login screen should then handle
          // showing the "verify email" message if this user is still the currentUser.
          // Optionally, you could sign them out here if you want to be stricter:
          // await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        // print("Error reloading user on splash: $e");
        // Handle error, e.g., network issue. Default to login screen.
        // You might want to sign out the user if reload fails critically
        // await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> clearStoredAuthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool("is_first_launch") ?? true;

    if (isFirstLaunch) {
      await FirebaseAuth.instance.signOut();
      await prefs.setBool("is_first_launch", false);
    }
  }

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

  Future<void> setupLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    var flutterLocalNotificationsPlugin;
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    debugPrint("✅ Local notifications initialized.");
  }

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint("✅ Notification permission requested.");
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message: ${message.notification?.title}");
      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("➡️ User tapped notification: ${message.notification?.title}");
    });
  }

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

    var flutterLocalNotificationsPlugin;
    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "",
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "Shivay's Creation",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SpinKitRipple(
              color: Colors.white,
              size: 50,
              duration: Duration(milliseconds: 1500),
            ),
          ],
        ),
      ),
    );
  }
}
