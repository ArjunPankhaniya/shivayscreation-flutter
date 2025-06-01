import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ADDED
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart'; // ADDED
import 'package:shivayscreation/screens/help_screen.dart';
import 'package:shivayscreation/screens/settings_screen.dart';

import 'profile_screen_update.dart';
// Import your screen for full order history
// import 'order_history_screen.dart';
// Import your screen for full wishlist
// import 'wishlist_screen.dart';
// Import your screen for managing addresses
// import 'saved_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // ADDED
  File? _profileImage;
  bool _isUploading = false;

  // GlobalKey for the Scaffold, useful for accessing ScaffoldMessenger or Scaffold state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void initState() {
    super.initState();
    // _fetchAdditionalSummaryData(); // Uncomment if you use it
  }

  // Ensure this method uses a context that is a descendant of the Scaffold
  // if you were facing issues with SnackBar.
  // The 'bodyContext' will be provided by a Builder in the Scaffold's body.
  Future<void> _pickAndUploadImage(BuildContext bodyContext) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      File compressedImage = await _compressImage(File(image.path));
      User? user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }

      String filePath = 'profile_pics/${user.uid}.webp';
      UploadTask uploadTask = _storage.ref(filePath).putFile(compressedImage);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({'imageUrl': downloadUrl});

      if (mounted) {
        // setState(() {
        //   // _profileImage = compressedImage; // Update local image for immediate display only if you want to override network
        // });
        ScaffoldMessenger.of(bodyContext).showSnackBar( // Use bodyContext
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(bodyContext).showSnackBar( // Use bodyContext
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.webp';

    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      format: CompressFormat.webp,
    );
    return compressedXFile != null ? File(compressedXFile.path) : file;
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = Colors.blue,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis,)
            : null,
        trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]) : null),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
    );
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext dialogContext) async {
    return await showDialog<bool>(
      context: dialogContext, // Use the context passed to the dialog
      builder: (BuildContext alertContext) { // This is the context for the AlertDialog's contents
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(alertContext).pop(false),
            ),
            TextButton(
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(alertContext).pop(true);
                }
            ),
          ],
        );
      },
    ) ?? false;
  }

  // MODIFIED/NEW method to handle all logout steps
  Future<void> _handleLogout(BuildContext scaffoldContextForSnackbar) async {
    try {
      // 1. Delete FCM token from Firebase server
      await _firebaseMessaging.deleteToken();
      debugPrint("FCM token deleted from Firebase server.");

      // 2. Clear FCM token from local SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token'); // Using the string key directly
      debugPrint("FCM token removed from local SharedPreferences.");

      // 3. Sign out from Firebase Auth
      await _auth.signOut();
      debugPrint("User signed out from Firebase Auth.");

      // 4. Navigate to login screen
      if (mounted) {
        // Show a success message (optional)
        ScaffoldMessenger.of(scaffoldContextForSnackbar).showSnackBar(
          const SnackBar(
            content: Text('You have been logged out.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(scaffoldContextForSnackbar).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold( // This Scaffold is separate, its context is fine for its children
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No user logged in.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Go to Login'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey, // Assign key to the main Scaffold
      appBar: AppBar(
        // backgroundColor: Colors.blue.shade50,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        elevation: 0,
        actions: [
          Builder(
              builder: (actionButtonContext) { // This context is under the Scaffold
                return IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  tooltip: 'Logout',
                  onPressed: () async {
                    // Pass the actionButtonContext (which is under the Scaffold)
                    bool confirmLogout = await _showLogoutConfirmationDialog(actionButtonContext); // Pass context for dialog
                    if (confirmLogout && mounted) {
                      // Pass the actionButtonContext to _handleLogout
                      // for its SnackBar.
                      await _handleLogout(actionButtonContext);
                    }
                  },
                );
              }
          ),
        ],
      ),
      body: Builder(
          builder: (bodyContext) { // bodyContext is a descendant of the Scaffold
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) { // This 'context' is from StreamBuilder
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }
                if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Could not load user data.', textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: () => setState(() {}), child: const Text("Retry"))
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String primaryAddressDisplay = "Address not set";
                final addressData = userData['primaryAddress'];
                if (addressData != null) {
                  if (addressData is String && addressData.isNotEmpty) {
                    primaryAddressDisplay = addressData;
                  } else if (addressData is Map) {
                    String street = addressData['street']?.toString() ?? '';
                    String city = addressData['city']?.toString() ?? '';
                    String zip = addressData['zip']?.toString() ?? '';
                    List<String> parts = [];
                    if (street.isNotEmpty) parts.add(street);
                    if (city.isNotEmpty) parts.add(city);
                    if (zip.isNotEmpty) parts.add(zip);
                    if (parts.isNotEmpty) {
                      primaryAddressDisplay = parts.join(', ');
                    } else {
                      primaryAddressDisplay = "Address details incomplete";
                    }
                  } else {
                    primaryAddressDisplay = "Invalid address format";
                  }
                }

                String lastOrderInfo = "No recent orders";
                if (userData['lastOrderDate'] != null && userData['lastOrderDate'] is Timestamp) {
                  Timestamp lastOrderTimestamp = userData['lastOrderDate'] as Timestamp;
                  lastOrderInfo = "Last order: ${DateFormat('dd MMM, yyyy').format(lastOrderTimestamp.toDate())}";
                } else if (userData['lastOrderSummary'] != null && userData['lastOrderSummary'] is String) {
                  lastOrderInfo = userData['lastOrderSummary'];
                }

                int wishlistItemsCount = userData['wishlistCount'] as int? ?? 0;
                String wishlistSubtitle = wishlistItemsCount > 0
                    ? "$wishlistItemsCount item${wishlistItemsCount == 1 ? '' : 's'}"
                    : "No items in wishlist";
                // int loyaltyPoints = userData['loyaltyPoints'] as int? ?? 0;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      color: Colors.teal.shade50,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(bodyContext), // Pass bodyContext here
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.blue.shade200,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (userData['imageUrl'] != null && (userData['imageUrl'] as String).isNotEmpty
                                      ? NetworkImage(userData['imageUrl'] as String)
                                      : null) as ImageProvider?,
                                  child: (_profileImage == null && (userData['imageUrl'] == null || (userData['imageUrl'] as String).isEmpty))
                                      ? Icon(Icons.person, size: 50, color: Colors.white.withOpacity(0.7))
                                      : null,
                                ),
                                if (_isUploading)
                                  const CircularProgressIndicator(color: Colors.white),
                                if (!_isUploading)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userData['name'] ?? 'User Name', // Ensure this matches your Firestore field
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? 'No email',
                            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Joined: ${userData['createdAt'] != null ? DateFormat('dd MMM, yyyy').format((userData['createdAt'] as Timestamp).toDate()) : ''}", // Ensure this matches your Firestore field
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon:  Icon(color: Colors.white, Icons.edit_outlined, size: 18),
                            label:  Text('Edit Profile Details'),
                            onPressed: () {
                              Navigator.push(
                                context, // This context should be fine for navigation
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreenUpdate(userData: userData),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              textStyle: const TextStyle(fontSize: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildProfileOption(
                        icon: Icons.location_on_outlined,
                        title: "Primary Address",
                        subtitle: primaryAddressDisplay,
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => SavedAddressesScreen()));
                          ScaffoldMessenger.of(bodyContext).showSnackBar(
                              const SnackBar(content: Text('Navigate to Saved Addresses (Not Implemented)')));
                        }
                    ),
                    _buildProfileOption(
                        icon: Icons.receipt_long_outlined,
                        title: "Order History",
                        subtitle: lastOrderInfo,
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
                          ScaffoldMessenger.of(bodyContext).showSnackBar(
                              const SnackBar(content: Text('Navigate to Order History (Not Implemented)')));
                        }
                    ),
                    _buildProfileOption(
                        icon: Icons.favorite_border_outlined,
                        title: "My Wishlist",
                        subtitle: wishlistSubtitle,
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => WishlistScreen()));
                          ScaffoldMessenger.of(bodyContext).showSnackBar(
                              const SnackBar(content: Text('Navigate to Wishlist (Not Implemented)')));
                        }
                    ),

                    // const Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    //   child: Divider(),
                    // ),

                    _buildProfileOption(
                        icon: Icons.settings_outlined,
                        title: "Settings",
                        // iconColor: Colors.blueGrey.shade700,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                        }),
                    _buildProfileOption(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        // iconColor: Colors.blueGrey.shade700,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                        }),
                  ],
                );
              },
            );
          }
      ),
    );
  }
}