import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: unused_import
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/widgets/input_text_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final userNameTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final authenticationController = AuthenticationController.instanceAuth;
  final _isLoading = false.obs;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    userNameTextEditingController.dispose();
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (authenticationController.profileImage != null) {
        _isLoading.value = true; // Set loading to true

        try {
          // ignore: await_only_futures
          await authenticationController.createAccountForNewUse(
            authenticationController.profileImage!,
            userNameTextEditingController.text.trim(),
            emailTextEditingController.text.trim(),
            passwordTextEditingController.text.trim(),
          );
          // _isLoading.value = true;
        } catch (e) {
          // Handle error
          Get.snackbar(
            "Error",
            "Registration failed: ${e.toString()}",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
          );
        } finally {
          _isLoading.value =
              false; // Set loading to false regardless of success or error
        }
      } else {
        Get.snackbar(
          "Error",
          "Please select a profile image",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          borderRadius: 12,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text(
                  "Create Account",
                  style: GoogleFonts.acme(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                Obx(() {
                  return GestureDetector(
                    onTap: _isLoading.value
                        ? null
                        : () {
                            authenticationController.chooseImageFromGallery();
                          },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 85,
                          backgroundColor: Colors.grey[800],
                          backgroundImage:
                              authenticationController.profileImage != null
                              ? FileImage(
                                  authenticationController.profileImage!,
                                )
                              : const AssetImage("images/reg.jpeg")
                                    as ImageProvider,
                        ),
                        if (!_isLoading.value)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 30),

                // Username field
                InputTextWidget(
                  controller: userNameTextEditingController,
                  label: "Username",
                  icon: Icons.person_outlined,
                  obscureText: false,
                  enabled: !_isLoading.value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    final regex = RegExp(r'^[a-z0-9_]+$');
                    if (!regex.hasMatch(value)) {
                      return 'Only lowercase letters & numbers,underscore(_) are allowed';
                    }
                    return null;
                  },
                  isObscure: true,
                ),

                const SizedBox(height: 20),

                // Email field
                InputTextWidget(
                  controller: emailTextEditingController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  enabled: !_isLoading.value,
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  isObscure: true,
                ),

                const SizedBox(height: 20),

                // Password field
                InputTextWidget(
                  controller: passwordTextEditingController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  enabled: !_isLoading.value,
                  obscureText: true,
                  isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 38),

                Obx(() {
                  debugPrint("${!_isLoading.value}...........................");
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading.value
                              ? null
                              : _handleRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 10,
                            shadowColor: Colors.pink.withOpacity(0.4),
                          ),
                          child: _isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an Account?",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            onPressed: _isLoading.value
                                ? null
                                : () {
                                    Get.offAll(() => const LoginScreen());
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text(
                              "Login Now",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
