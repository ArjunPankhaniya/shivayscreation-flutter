import 'package:flutter/material.dart';
import 'package:shivayscreation/screens/about_screen.dart';

// Assuming your HomeScreen is in 'home_screen.dart' and you have a named route '/home'
// import 'home_screen.dart'; // Import if you need the HomeScreen class directly

class SettingsScreen extends StatefulWidget { // Changed to StatefulWidget for potential stateful settings
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkModeEnabled = false; // Example state for a switch
  bool _areNotificationsEnabled = true; // Example state

  // Helper widget for section titles
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.teal.shade700, // Use a slightly darker shade of your theme color
          fontWeight: FontWeight.bold,
          fontSize: 13.0,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Helper for standard list tiles
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade600, size: 26),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (Route<dynamic> route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100], // A slightly off-white background for the page
        appBar: AppBar(
          title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.teal,
          elevation: 1, // Subtle elevation
          iconTheme: const IconThemeData(color: Colors.white), // Ensure back arrow is white
        ),
        body: ListView(
          children: <Widget>[
            _buildSectionHeader('General'),
            Card( // Wrap sections in Cards for a more modern feel
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text(_areNotificationsEnabled ? 'You will receive updates' : 'You will not receive updates', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    secondary: Icon(Icons.notifications_active_outlined, color: Colors.teal.shade600, size: 26),
                    value: _areNotificationsEnabled,
                    activeColor: Colors.teal,
                    onChanged: (bool value) {
                      setState(() {
                        _areNotificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notifications ${value ? "enabled" : "disabled"}')),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  _buildSettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (US)', // Example
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language settings tapped (Not Implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),

            _buildSectionHeader('Appearance'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text(_isDarkModeEnabled ? 'Enabled' : 'Disabled', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    secondary: Icon(Icons.brightness_6_outlined, color: Colors.teal.shade600, size: 26),
                    value: _isDarkModeEnabled,
                    activeColor: Colors.teal,
                    onChanged: (bool value) {
                      setState(() {
                        _isDarkModeEnabled = value;
                      });
                      // Here you would typically also change the app's theme
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dark Mode ${value ? "enabled" : "disabled"} (UI Placeholder)')),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  _buildSettingsTile(
                    icon: Icons.text_fields_outlined,
                    title: 'Font Size',
                    subtitle: 'Default',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Font Size settings tapped (Not Implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),


            _buildSectionHeader('Account & Data'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    subtitle: 'Manage account security and data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy settings tapped (Not Implemented)')),
                      );
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  _buildSettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear Cache',
                    onTap: () {
                      // Implement cache clearing logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared (Not Implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),


            _buildSectionHeader('About'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About App',
                    subtitle: 'Version, licenses, terms of service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutScreen(), // Or a dedicated address screen
                        ),);
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  _buildSettingsTile(
                    icon: Icons.policy_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service tapped (Not Implemented)')),
                      );
                      // Typically, you'd open a web page or another screen
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy tapped (Not Implemented)')),
                      );
                      // Typically, you'd open a web page or another screen
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Some spacing at the bottom
          ],
        ),
      ),
    );
  }
}