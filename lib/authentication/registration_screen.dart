// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/authentication/login_screen.dart';
// import 'package:tiktok/globle.dart';
// import 'package:tiktok/widgets/input_text_widgets.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   TextEditingController userNameTextEditingController = TextEditingController();
//   TextEditingController emailTextEditingController = TextEditingController();
//   TextEditingController passwordTextEditingController = TextEditingController();

//   var authenticationController = AuthenticationController.instanceAuth;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Center(
//           child: Column(
//             children: [
//               const SizedBox(height: 50),
//               Text(
//                 "Create Account",
//                 style: GoogleFonts.acme(
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               //profile avatar
//               const SizedBox(height: 20),
//               GestureDetector(
//                 onTap: () {
//                   //users choose image
//                   authenticationController.chooseImageFromGallery();
//                   //authenticationController.captureImageWithCamera();
//                 },
//                 child: const CircleAvatar(
//                   radius: 85,
//                   backgroundImage: AssetImage("images/reg.jpeg"),
//                   backgroundColor: Colors.black,
//                 ),
//               ),

//               const SizedBox(height: 20),
//               //username input
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 child: InputTextWidget(
//                   controller: userNameTextEditingController,
//                   label: "UserName",
//                   icon: Icons.person_outlined,
//                   isObscure: false,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               //email input
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 child: InputTextWidget(
//                   controller: emailTextEditingController,
//                   label: "Email",
//                   icon: Icons.email_outlined,
//                   isObscure: false,
//                 ),
//               ),

//               const SizedBox(height: 20),
//               //password input
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 child: InputTextWidget(
//                   controller: passwordTextEditingController,
//                   label: "Password",
//                   icon: Icons.lock_outline,
//                   isObscure: true,
//                 ),
//               ),

//               const SizedBox(height: 38),

//               // login & signup button
//               if (showProgressBar == false)
//                 Column(
//                   children: [
//                     //login
//                     Container(
//                       width: MediaQuery.of(context).size.width - 40,
//                       height: 55,
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.all(Radius.circular(10)),
//                       ),
//                       child: InkWell(
//                         onTap: () {
//                           // create a new account for user

//                           if (authenticationController.profileImage != null &&
//                               userNameTextEditingController.text.isNotEmpty &&
//                               emailTextEditingController.text.isNotEmpty &&
//                               passwordTextEditingController.text.isNotEmpty) {
//                             setState(() {
//                               showProgressBar = true;
//                             });

//                             authenticationController.createAccountForNewUse(
//                               authenticationController.profileImage!,
//                               userNameTextEditingController.text,
//                               emailTextEditingController.text,
//                               passwordTextEditingController.text,
//                             );

//                             // ignore: avoid_print
//                             print(emailTextEditingController.text);
//                           }
//                         },
//                         child: const Center(
//                           child: Text(
//                             "SignUp",
//                             style: TextStyle(
//                               fontSize: 20,
//                               color: Colors.black,

//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // not have a account , signup now button
//                     const SizedBox(height: 55),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "Already have an Account?",
//                           style: TextStyle(fontSize: 15, color: Colors.grey),
//                         ),
//                         InkWell(
//                           onTap: () {
//                             // signup screen
//                             Get.to(LoginScreen());
//                           },
//                           child: const Text(
//                             "  Login Now",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),

//                         //
//                       ],
//                     ),
//                   ],
//                 )
//               else
//                 // const SizedBox(height: 51),
//                 SimpleCircularProgressBar(
//                   progressColors: [
//                     Colors.pink,
//                     Colors.green,
//                     Colors.blueAccent,
//                     Colors.amber,
//                     Colors.red,
//                     Colors.purpleAccent,
//                   ],
//                   animationDuration: 7,
//                   backColor: Colors.white38,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/authentication/login_screen.dart';
// import 'package:tiktok/widgets/input_text_widgets.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final userNameTextEditingController = TextEditingController();
//   final emailTextEditingController = TextEditingController();
//   final passwordTextEditingController = TextEditingController();
//   final authenticationController = AuthenticationController.instanceAuth;
//   final _isLoading = false.obs;
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void dispose() {
//     userNameTextEditingController.dispose();
//     emailTextEditingController.dispose();
//     passwordTextEditingController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleRegistration() async {
//     if (_formKey.currentState!.validate()) {
//       if (authenticationController.profileImage != null) {
//         authenticationController.createAccountForNewUse(
//           authenticationController.profileImage!,
//           userNameTextEditingController.text.trim(),
//           emailTextEditingController.text.trim(),
//           passwordTextEditingController.text.trim(),
//         );
//         _isLoading.value = true;
//       } else {
//         Get.snackbar(
//           "Error",
//           "Please select a profile image",
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red.withOpacity(0.9),
//           colorText: Colors.white,
//           margin: const EdgeInsets.all(20),
//           borderRadius: 12,
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const SizedBox(height: 30),
//                 Text(
//                   "Create Account",
//                   style: GoogleFonts.acme(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 GestureDetector(
//                   onTap: () {
//                     authenticationController.chooseImageFromGallery();
//                   },
//                   child: Obx(() {
//                     return Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 85,
//                           backgroundColor: Colors.grey[800],
//                           backgroundImage:
//                               authenticationController.profileImage != null
//                               ? FileImage(
//                                   authenticationController.profileImage!,
//                                 )
//                               : const AssetImage("images/reg.jpeg"),
//                           //           as ImageProvider,
//                           // child: authenticationController.profileImage == null
//                           //     ? const Icon(
//                           //         Icons.person,
//                           //         size: 80,
//                           //         color: Color.fromARGB(179, 16, 16, 16),
//                           //       )
//                           //     : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: const BoxDecoration(
//                               color: Colors.pink,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.camera_alt,
//                               size: 20,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }),
//                 ),
//                 const SizedBox(height: 30),
//                 InputTextWidget(
//                   controller: userNameTextEditingController,
//                   label: "Username",
//                   icon: Icons.person_outlined,
//                   obscureText: false,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a username';
//                     }
//                     if (value.length < 3) {
//                       return 'Username must be at least 3 characters';
//                     }
//                     return null;
//                   },
//                   isObscure: true,
//                 ),
//                 const SizedBox(height: 20),
//                 InputTextWidget(
//                   controller: emailTextEditingController,
//                   label: "Email",
//                   icon: Icons.email_outlined,
//                   obscureText: false,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!GetUtils.isEmail(value)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                   isObscure: true,
//                 ),
//                 const SizedBox(height: 20),
//                 InputTextWidget(
//                   controller: passwordTextEditingController,
//                   label: "Password",
//                   icon: Icons.lock_outline,
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 6 characters';
//                     }
//                     return null;
//                   },
//                   isObscure: true,
//                 ),
//                 const SizedBox(height: 38),
//                 Obx(() {
//                   if (_isLoading.value) {
//                     return Column(
//                       children: [
//                         // SimpleCircularProgressBar(
//                         //   progressColors: const [
//                         //     Colors.pink,
//                         //     Colors.purple,
//                         //     Colors.blueAccent,
//                         //   ],
//                         //   backColor: Colors.grey[800]!,
//                         //   animationDuration: 1,
//                         //   size: 80,
//                         //   onGetText: (double value) {
//                         //     return Text(
//                         //       "${value.toInt()}%",
//                         //       style: const TextStyle(
//                         //         color: Colors.white,
//                         //         fontSize: 18,
//                         //         fontWeight: FontWeight.bold,
//                         //       ),
//                         //     );
//                         //   },
//                         // ),
//                         SimpleCircularProgressBar(
//                           progressColors: [
//                             Colors.pink,
//                             Colors.green,
//                             Colors.blueAccent,
//                             Colors.amber,
//                             Colors.red,
//                             Colors.purpleAccent,
//                           ],
//                           animationDuration: 7,
//                           backColor: Colors.white38,
//                         ),
//                         const SizedBox(height: 20),
//                         const Text(
//                           "Creating your account...",
//                           style: TextStyle(color: Colors.white70),
//                         ),
//                       ],
//                     );
//                   } else {
//                     return Column(
//                       children: [
//                         SizedBox(
//                           width: double.infinity,
//                           height: 55,
//                           child: ElevatedButton(
//                             onPressed: _isLoading.value
//                                 ? null
//                                 : _handleRegistration,

//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.pink,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 10,
//                               shadowColor: Colors.pink.withOpacity(0.4),
//                             ),
//                             child: _isLoading.value
//                                 ? const SizedBox(
//                                     height: 20,
//                                     width: 20,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                       strokeWidth: 2,
//                                     ),
//                                   )
//                                 : const Text(
//                                     "Sign Up",
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w900,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                         const SizedBox(height: 25),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               "Already have an Account?",
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(width: 5),
//                             TextButton(
//                               onPressed: () {
//                                 Get.offAll(() => const LoginScreen());
//                               },
//                               style: TextButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                 ),
//                               ),
//                               child: const Text(
//                                 "Login Now",
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   color: Colors.pink,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     );
//                   }
//                 }),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
                  print("${!_isLoading.value}...........................");
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
