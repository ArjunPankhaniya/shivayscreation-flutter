import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Frequently Asked Questions"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text("🔹 How to use the app?"),
                  subtitle: Text("You can explore categories and add products to the cart."),
                ),
                const ListTile(
                  title: Text("🔹 How to contact support?"),
                  subtitle: Text("You can email us at support@shivayscreation.com."),
                ),
                const ListTile(
                  title: Text("🔹 How to track my order?"),
                  subtitle: Text("Go to 'Orders' section to track your orders."),
                ),
                const Divider(),
                const ListTile(
                  title: Text("🔹 What is the refund policy?"),
                  subtitle: Text(
                    "Refunds will be processed within 7 to 10 business days after receiving the product.\n"
                        "If the customer has violated the return policies (e.g., changed the product), the payment will not be processed.",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text('Notifications'),
            subtitle: const Text('Manage app notifications'),
            onTap: () => _showDialog(context, "Notifications", "Enable or disable app notifications."),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text('Privacy'),
            subtitle: const Text('Manage privacy settings'),
            onTap: () => _showDialog(context, "Privacy Settings", "Adjust your privacy preferences."),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.orange),
            title: const Text('Account Settings'),
            subtitle: const Text('Manage your account details'),
            onTap: () => _showDialog(context, "Account Settings", "Update your account details and preferences."),
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.purple),
            title: const Text('Help & Support'),
            subtitle: const Text('Get support or FAQs'),
            onTap: () => _showFAQDialog(context),
          ),
        ],
      ),
    );
  }
}
