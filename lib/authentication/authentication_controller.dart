import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/globle.dart';
import 'package:email_validator/email_validator.dart';
import 'package:tiktok/home/home_screen.dart';

//ignore: library_prefixes
import 'user.dart' as userModle;

class AuthenticationController extends GetxController {
  static AuthenticationController instanceAuth = Get.find();
  late Rx<User?> _currentUser;
  late Rx<File?> _pickedFile;

  File? get profileImage => _pickedFile.value;
  User get user => _currentUser.value!;

  /// Select image from gallery
  void chooseImageFromGallery() async {
    try {
      final pickedImageFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedImageFile != null) {
        _pickedFile.value = File(pickedImageFile.path);
        update();

        Get.snackbar(
          "Success",
          "Profile image selected successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Info",
          "Image selection canceled",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to select image: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Capture image with camera
  void captureImageWithCamera() async {
    try {
      final pickedImageFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedImageFile != null) {
        _pickedFile.value = File(pickedImageFile.path);
        update();

        Get.snackbar(
          "Success",
          "Profile image captured successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Info",
          "Image capture canceled",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to capture image: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Create a new account
  Future<void> createAccountForNewUse(
    File? imagesFile,
    String userName,
    String userEmail,
    String userPassword,
  ) async {
    try {
      if (imagesFile == null) {
        Get.snackbar(
          "Image Required",
          "Please select a profile image",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        showProgressBar = false;
        return;
      }

      if (userName.isEmpty) {
        Get.snackbar(
          "Username Required",
          "Please enter a username",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        showProgressBar = false;
        return;
      }

      bool isValidEmail = EmailValidator.validate(userEmail);
      if (!isValidEmail) {
        Get.snackbar(
          "Invalid Email",
          "Please enter a valid email address",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        showProgressBar = false;
        return;
      }

      if (userPassword.length < 6) {
        Get.snackbar(
          "Weak Password",
          "Password must be at least 6 characters",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
        showProgressBar = false;
        return;
      }

      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: userEmail,
            password: userPassword,
          );

      String imagesDownloadUrl = await uploadImageToStorage(imagesFile);

      userModle.AppUser user = userModle.AppUser(
        name: userName,
        email: userEmail,
        image: imagesDownloadUrl,
        uid: credential.user!.uid,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set(user.toJson());

      Get.snackbar(
        "Success",
        "Congratulations! Your account has been created",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      showProgressBar = false;
    } catch (e) {
      String errorMessage = "An error occurred. Please try again.";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage =
                "This email is already registered. Please login instead.";
            break;
          case 'weak-password':
            errorMessage =
                "The password is too weak. Please choose a stronger password.";
            break;
          case 'invalid-email':
            errorMessage =
                "The email address is invalid. Please check and try again.";
            break;
          case 'operation-not-allowed':
            errorMessage =
                "Email/password accounts are not enabled. Please contact support.";
            break;
          default:
            errorMessage = "Authentication error: ${e.message}";
        }
      }

      Get.snackbar(
        "Registration Failed",
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      showProgressBar = false;

      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        Get.offAll(() => LoginScreen());
      }
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadImageToStorage(File imageFile) async {
    Reference reference = FirebaseStorage.instance
        .ref()
        .child("Profile Images")
        .child(FirebaseAuth.instance.currentUser!.uid);

    UploadTask uploadTask = reference.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  /// Login user
  Future<void> loginUser(String userEmail, String userPassword) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      Get.snackbar(
        "Success",
        "You're logged in successfully.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );

      showProgressBar = false;
      Get.offAll(() => HomeScreen());
    } catch (e) {
      String errorMessage = "An error occurred during login. Please try again.";

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No account found with this email.";
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password. Please try again.";
            break;
          case 'invalid-email':
            errorMessage = "The email address is invalid.";
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled.";
            break;
          default:
            errorMessage = "Login error: ${e.message}";
        }
      }

      Get.snackbar(
        "Login Failed",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );

      showProgressBar = false;
    }
  }

  /// Navigate based on auth state
  void goToScreen(User? currentUser) {
    if (currentUser == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => HomeScreen());
    }
  }

  @override
  void onReady() {
    super.onReady();
    _pickedFile = Rx<File?>(null);
    _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _currentUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_currentUser, goToScreen);
  }
}
