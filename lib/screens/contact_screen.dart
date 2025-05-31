import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Function to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
      // Optionally: Show a SnackBar to the user here
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open link")));
    }
  }

  // Contact Functions
  void _sendEmail() => _launchURL("mailto:support@shivayscreation.com");
  void _makeCall() => _launchURL("tel:+918460427367"); // Example number
  void _openFacebook() => _launchURL("https://www.facebook.com/");
  void _openInstagram() => _launchURL("https://www.instagram.com/");
  void _openWebsite() => _launchURL("https://www.shivayscreation.com");

  // This function now primarily focuses on opening the Maps app with a query.
  // The API key is not typically needed for this specific intent URL.
  void _openGoogleMaps() => _launchURL("https://www.google.com/maps?q=Jamnagar,India"); // Changed to Jamnagar as per static map


  @override
  Widget build(BuildContext context) {
    // --- Access the API Key for Static Map ---
    // Make sure 'GOOGLE_MAPS_API_KEY' matches the key name in your .env file
    // (or local.properties if you configured flutter_dotenv for that).
    final String? staticMapApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    // Construct the map URL. Use a fallback if the API key is not found.
    final String mapImageUrl = (staticMapApiKey != null && staticMapApiKey.isNotEmpty)
        ? 'https://maps.googleapis.com/maps/api/staticmap?center=Jamnagar,India&zoom=14&size=400x200&key=$staticMapApiKey'
        : 'https://via.placeholder.com/400x200.png?text=Map+Preview+Not+Available+(API+Key+Missing)'; // Fallback image

    // For debugging: Print the key and URL
    // debugPrint("Static Map API Key: $staticMapApiKey");
    // debugPrint("Static Map URL: $mapImageUrl");

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
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  // borderRadius: BorderRadius.circular(12), // Optional: if you want rounded corners
                ),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      'Need Help? Contact Us!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'We are here to assist you 24/7',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30), // Increased spacing

              // Contact Details
              _buildContactTile(
                icon: Icons.email_outlined, // Changed to outlined
                text: 'support@shivayscreation.com',
                onTap: _sendEmail,
                iconColor: Colors.redAccent,
              ),
              _buildContactTile(
                icon: Icons.phone_outlined, // Changed to outlined
                text: '+91 8460427367', // Make sure this is the correct number
                onTap: _makeCall,
                iconColor: Colors.green,
              ),

              const SizedBox(height: 30), // Increased spacing

              // Social Media Links
              const Text(
                'Follow us on:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.facebook, // Standard Facebook icon
                    onPressed: _openFacebook,
                    color: Color(0xFF1877F2), // Facebook blue
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    // A common way to represent Instagram
                    iconWidget: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737), Color(0xFFE1306C)],
                        tileMode: TileMode.mirror,
                      ).createShader(bounds),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 30), // Outlined
                    ),
                    onPressed: _openInstagram,
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    icon: Icons.language_outlined, // Changed to outlined 'language' or 'public' for website
                    onPressed: _openWebsite,
                    color: Colors.blueAccent,
                  ),
                ],
              ),

              const SizedBox(height: 30), // Increased spacing

              // Google Map Location (Static Preview)
              Text(
                "Our Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12), // More modern rounded corners
                child: Image.network(
                  mapImageUrl, // Use the dynamically built mapUrl
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Error loading static map: $error"); // Log the error
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 40),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Could not load map preview.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600)
                ),
                icon: const Icon(Icons.pin_drop_outlined), // Changed to outlined
                label: const Text('View on Google Maps'),
                onPressed: _openGoogleMaps,
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for contact tiles for a cleaner build method
  Widget _buildContactTile({required IconData icon, required String text, required VoidCallback onTap, Color? iconColor}) {
    return Card( // Giving it a card look for better separation
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.teal, size: 28),
        title: Text(text, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Helper widget for social buttons
  Widget _buildSocialButton({IconData? icon, Widget? iconWidget, required VoidCallback onPressed, Color? color}) {
    return IconButton(
      iconSize: 32,
      icon: iconWidget ?? Icon(icon, color: color ?? Colors.grey[700]),
      onPressed: onPressed,
      splashRadius: 28,
    );
  }
}