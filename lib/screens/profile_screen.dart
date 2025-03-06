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
  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>;
        } else {
          throw 'User data not found in Firestore.';
        }
      } else {
        throw 'User not logged in.';
      }
    } catch (e) {
      throw 'Error fetching user data: $e';
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
  void _navigateToEditProfile(Map<String, dynamic> userData) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreenUpdate(
            userData: userData,
          ),
        ),
      );
      // Refresh profile details after returning from the edit screen
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to edit profile: $e')),
      );
    }
  }

  // Pick an image from the gallery and upload to Firebase Storage
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Upload the image to Firebase Storage
      String fileName =
          'profile_pics/${_auth.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      try {
        // Upload the image to Firebase Storage
        TaskSnapshot snapshot =
            await _storage.ref(fileName).putFile(_profileImage!);

        // Get the URL of the uploaded image
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the user's profile with the image URL in Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'profileImage': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile image updated successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('Profile', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        leading: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Container(); // Show nothing if there is an error or no data
            }
            return IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => _navigateToEditProfile(snapshot.data!),
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
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
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
                      onTap: _pickImage, // Pick image on tap
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : userData['profileImage'] != null
                                ? NetworkImage(userData['profileImage'])
                                : null,
                        child: _profileImage == null &&
                                userData['profileImage'] == null
                            ? Text(
                                userData['name']
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
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
                      title:
                          Text(userData['address'] ?? 'Address not available'),
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
