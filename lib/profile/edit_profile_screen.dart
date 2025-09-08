// lib/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tiktok/authentication/user.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  final Function onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _usernameController.text = "${widget.user.name}";
    // _bioController.text = widget.user.bio;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final userId = _auth.currentUser!.uid;
      final ref = _storage.ref().child(
        'profile_images/$userId-${DateTime.now().millisecondsSinceEpoch}',
      );
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload image: $e';
      });
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = _auth.currentUser!.uid;
      final String? imageUrl = await _uploadImage();

      await _firestore.collection('users').doc(userId).update({
        'name': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        if (imageUrl != null) 'image': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Call the callback to refresh the profile
      widget.onProfileUpdated();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: "${widget.user.image}",
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[800],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey[800],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Bio Field
                  TextFormField(
                    controller: _bioController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
