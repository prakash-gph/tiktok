// ignore_for_file: library_private_types_in_public_api

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
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

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
    _usernameController.text = widget.user.name ?? "";
    _bioController.text = widget.user.bio ?? "";
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
    if (_imageFile == null) {
      debugPrint(
        "No image selected - this is normal if user didn't change image=================================",
      );
      return null;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final ref = _storage.ref().child(
        'profile_images/$userId-${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint("$ref-----------------------------------------------------");
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase Storage error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Username cannot be empty');
      return;
    }
    final regex = RegExp(r'^[a-z0-9_]+$');
    if (!regex.hasMatch(_usernameController.text)) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Only lowercase letters & numbers,underscore(_) are allowed',
        );
      }
      return;
    }
    final bio = _bioController.text.trim();
    if (bio.length > 150) {
      if (mounted) {
        setState(() => _errorMessage = 'Bio cannot exceed 150 characters');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final userId = _auth.currentUser!.uid;
      final String? imageUrl = await _uploadImage();

      final updateData = {
        'name': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['image'] = imageUrl;
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      await widget.onProfileUpdated();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          //   _errorMessage = 'Failed to update profile: $e';

          _isLoading = false;
          Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                            border: Border.all(
                              color: isDarkMode ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: widget.user.image ?? "",
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
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
                  const SizedBox(height: 24),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color?.withOpacity(0.3) ??
                              Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[900]
                          : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio Field
                  TextFormField(
                    controller: _bioController,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color?.withOpacity(0.3) ??
                              Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      counterText: '${_bioController.text.length}/150',
                    ),
                    onChanged: (_) {
                      if (mounted) setState(() {}); // updates live counter
                    },
                  ),

                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),

                  // Additional Info
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your profile information will be visible to other users',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
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
