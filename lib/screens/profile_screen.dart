import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile_screen_update.dart'; // Ensure the import is correct

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      DocumentSnapshot snapshot =
      await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  // Navigate to edit profile screen
  void _navigateToEditProfile(Map<String, dynamic>? userData) async {
    if (userData == null) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreenUpdate(userData: userData),
        ),
      );
      // Refresh profile details after returning from edit screen
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to edit profile: $e')),
      );
    }
  }

  // Pick an image from gallery & upload to Firebase Storage
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _profileImage = File(image.path);
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String fileName =
          'profile_pics/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(_profileImage!);

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile image updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('Profile', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        leading: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Container(); // Show nothing if there's an error
            }
            return IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => _navigateToEditProfile(snapshot.data),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No user data available.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade200, Colors.teal.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (userData['profileImage'] != null
                            ? NetworkImage(userData['profileImage'])
                            : null) as ImageProvider?,
                        child: _profileImage == null &&
                            (userData['profileImage'] == null ||
                                userData['profileImage'] == "")
                            ? Text(
                          userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      userData['name'] ?? 'User Name',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userData['email'] ?? 'Email not available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[200]),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.teal),
                      title: Text(userData['phone'] ?? 'Phone not available'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.location_on, color: Colors.teal),
                      title: Text(userData['address'] ?? 'Address not available'),
                    ),
                    Divider(),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToEditProfile(userData),
                      icon: Icon(Icons.edit, color: Colors.white),
                      label: Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
