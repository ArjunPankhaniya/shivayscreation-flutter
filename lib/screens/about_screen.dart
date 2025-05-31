import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.teal, // AppBar color
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Header Section with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/logo.png'), // 👈 Your Logo
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Shivay\'s Creation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Your Trusted E-Commerce Partner',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Description Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Welcome to Shivay\'s Creation! We are committed to delivering high-quality products with a seamless shopping experience. Our goal is to ensure customer satisfaction with top-notch service and unique collections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Social Media Links
                  const Text(
                    'Follow us on:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.facebook, color: Colors.blue, size: 30),
                        onPressed: () {}, // 👈 Add Facebook link
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.pink, size: 30),
                        onPressed: () {}, // 👈 Add Instagram link
                      ),
                      IconButton(
                        icon: const Icon(Icons.web, color: Colors.green, size: 30),
                        onPressed: () {}, // 👈 Add Website link
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ Contact Us Section
                  const Text(
                    'Contact Us:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.teal),
                    title: const Text('support@shivayscreation.com'),
                    onTap: () {}, // 👈 Add Email Functionality
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.teal),
                    title: const Text('+91 8460427367'),
                    onTap: () {}, // 👈 Add Call Functionality
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
