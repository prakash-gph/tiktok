import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/registration_screen.dart';
import 'package:tiktok/widgets/input_text_widgets.dart';
import 'package:get/get.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   TextEditingController emailTextEditingController = TextEditingController();
//   TextEditingController passwordTextEditingController = TextEditingController();
//   bool showProgressBar = false;

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
//                 "Welcome",
//                 style: GoogleFonts.acme(
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               ClipOval(
//                 child: SizedBox.fromSize(
//                   size: Size.fromRadius(115),
//                   child: Image.asset(
//                     "images/login-profile.jpg",
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // const SizedBox(height: 50),
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

//               const SizedBox(height: 55),

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
//                           //login user
//                           if (emailTextEditingController.text.isNotEmpty &&
//                               passwordTextEditingController.text.isNotEmpty) {
//                             setState(() {
//                               showProgressBar = true;
//                             });

//                             authenticationController.loginUser(
//                               emailTextEditingController.text,
//                               passwordTextEditingController.text,
//                             );
//                           }
//                         },
//                         child: const Center(
//                           child: Text(
//                             "Login",
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
//                     const SizedBox(height: 65),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "Don't have an Account?",
//                           style: TextStyle(fontSize: 15, color: Colors.grey),
//                         ),
//                         InkWell(
//                           onTap: () {
//                             // signup screen
//                             Get.to(RegistrationScreen());
//                           },
//                           child: const Text(
//                             "  Signup Now",
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 )
//               else
//                 SimpleCircularProgressBar(
//                   progressColors: [
//                     Colors.pink,
//                     Colors.green,
//                     Colors.blueAccent,
//                     Colors.amber,
//                     Colors.red,
//                     Colors.purpleAccent,
//                   ],
//                   animationDuration: 3,
//                   backColor: Colors.white38,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailTextEditingController = TextEditingController();
  final passwordTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isLoading = false.obs;
  final authenticationController = AuthenticationController.instanceAuth;

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      await authenticationController.loginUser(
        emailTextEditingController.text.trim(),
        passwordTextEditingController.text.trim(),
      );
      _isLoading.value = false;
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
                const SizedBox(height: 50),
                Text(
                  "Welcome Back",
                  style: GoogleFonts.acme(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "images/login-profile.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                InputTextWidget(
                  controller: emailTextEditingController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  isObscure: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                InputTextWidget(
                  controller: passwordTextEditingController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: () {
                //       // Add forgot password functionality
                //     },
                //     child: const Text(
                //       "Forgot Password?",
                //       style: TextStyle(color: Colors.pink),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 30),
                Obx(() {
                  if (_isLoading.value) {
                    return SimpleCircularProgressBar(
                      progressColors: const [
                        Colors.pink,
                        Colors.purple,
                        Colors.blueAccent,
                      ],
                      animationDuration: 5,
                      backColor: Colors.grey[800]!,
                      size: 60,
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: Colors.pink.withOpacity(0.4),
                            ),
                            child: const Text(
                              "Login",
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
                              "Don't have an Account?",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            TextButton(
                              onPressed: () {
                                Get.to(() => const RegistrationScreen());
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                "Sign Up Now",
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
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
