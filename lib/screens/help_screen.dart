import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri.parse("mailto:support@shivayscreation.com?subject=Help Request");
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint("Could not launch Email");
    }
  }

  void _launchFAQ(BuildContext context) {
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

  void _openGoogleSupport() async {
    final Uri url = Uri.parse("https://support.google.com/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not open Google Support.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Need Help? Contact our 24/7 support team!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email Support"),
              subtitle: const Text("Click to send an email"),
              onTap: _launchEmail,
            ),

            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.green),
              title: const Text("View FAQs"),
              subtitle: const Text("Frequently Asked Questions"),
              onTap: () => _launchFAQ(context),
            ),

            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.orange),
              title: const Text("Google Support"),
              subtitle: const Text("Visit Google support page"),
              onTap: _openGoogleSupport,
            ),
          ],
        ),
      ),
    );
  }
}
