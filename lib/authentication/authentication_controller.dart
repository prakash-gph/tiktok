import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/authentication/registration_screen.dart';
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

  void chooseImageFromGallery() async {
    final pickedImageFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImageFile != null) {
      Get.snackbar(
        "Profile image",
        "you have successfully selected your profile image.",
      );
    }

    _pickedFile = Rx<File?>(File(pickedImageFile!.path));
  }

  void captureImageWithCamera() async {
    final pickedImageFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedImageFile != null) {
      Get.snackbar(
        "Profile image",
        "you have successfully captured your profile image with Phone Camera.",
      );
    }
    _pickedFile = Rx<File?>(File(pickedImageFile!.path));
  }

  void createAccountForNewUse(
    File imagesFile,
    String userName,
    String userEmail,
    String userPassword,
  ) async {
    //user authentication

    try {
      bool isValidEmail = EmailValidator.validate(userEmail);

      if (!isValidEmail) {
        Get.snackbar("Email Error", "Must be Validate Email Format");
        showProgressBar = false;
        return;
      }

      if (userPassword.length < 6) {
        Get.snackbar("Password Error", "Must be Six charater");
        showProgressBar = false;
        return;
      }

      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: userEmail,
            password: userPassword,
          );

      // save the user datas in firebase

      Future<String> uploadImageToStorage(File imageFile) async {
        Reference reference = FirebaseStorage.instance
            .ref()
            .child("Profile Images")
            .child(FirebaseAuth.instance.currentUser!.uid);

        UploadTask uploadTaskTask = reference.putFile(imageFile);
        TaskSnapshot taskSanpshot = await uploadTaskTask;

        String downloadUrlOfloadedImage = await taskSanpshot.ref
            .getDownloadURL();

        return downloadUrlOfloadedImage;
      }

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
        "Account Created",
        "Congratulation,Your account has been created",
      );
      showProgressBar = false;
      // Get.to(LoginScreen());
    } catch (e) {
      // ignore: avoid_print
      print(e);

      Get.snackbar(
        "Account Creation Unsuccessful",
        "Error occurred while create account. Try Again ",
      );
      Get.offAll(LoginScreen());
      showProgressBar = false;
    }
  }

  void loginUser(String userEamil, String userPassword) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEamil,
        password: userPassword,
      );

      Get.snackbar("Login Successful", "Your're logged-in successfully.");
      showProgressBar = false;
      Get.offAll(HomeScreen());
    } catch (e) {
      Get.snackbar(
        "Login Failed",
        "Error occurred during signin authentication.",
      );

      showProgressBar = false;
      Get.to(RegistrationScreen());
    }
  }

  goToScreen(User? currentUser) {
    if (currentUser == null) {
      Get.offAll(LoginScreen());
    } else {
      Get.offAll(HomeScreen());
    }
  }

  @override
  void onReady() {
    super.onReady();

    _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _currentUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_currentUser, goToScreen);
  }
}
