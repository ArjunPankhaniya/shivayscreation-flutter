import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // ✅ Function to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url); // ✅ Safe URL parsing
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  // ✅ Contact Functions
  void _sendEmail() => _launchURL("mailto:support@shivayscreation.com");
  void _makeCall() => _launchURL("tel:+919876543210");
  void _openFacebook() => _launchURL("https://www.facebook.com/");
  void _openInstagram() => _launchURL("https://www.instagram.com/");
  void _openWebsite() => _launchURL("https://www.shivayscreation.com");
  void _openGoogleMaps() => _launchURL("https://www.google.com/maps?q=Delhi,India");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Header Section
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      'Need Help? Contact Us!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'We are here to assist you 24/7',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Contact Details
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue, size: 30),
                title: const Text('support@shivayscreation.com'),
                onTap: _sendEmail, // 👈 Open Email
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green, size: 30),
                title: const Text('+91 8460427367'),
                onTap: _makeCall, // 👈 Open Phone Dialer
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
                    onPressed: _openFacebook,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.pink, size: 30),
                    onPressed: _openInstagram,
                  ),
                  IconButton(
                    icon: const Icon(Icons.web, color: Colors.green, size: 30),
                    onPressed: _openWebsite,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Google Map Location (Static Preview)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'https://maps.googleapis.com/maps/api/staticmap?center=Delhi,India&zoom=14&size=400x200&key=YOUR_GOOGLE_MAPS_API_KEY',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.location_on, color: Colors.teal),
                label: const Text('View on Google Maps'),
                onPressed: _openGoogleMaps,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
