import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/registration_screen.dart';
import 'package:tiktok/widgets/input_text_widgets.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  bool showProgressBar = false;

  var authenticationController = AuthenticationController.instanceAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                "Welcome",
                style: GoogleFonts.acme(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              ClipOval(
                child: SizedBox.fromSize(
                  size: Size.fromRadius(115),
                  child: Image.asset(
                    "images/login-profile.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // const SizedBox(height: 50),
              //email input
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: InputTextWidget(
                  textEditingController: emailTextEditingController,
                  lableStringe: "Email",
                  iconData: Icons.email_outlined,
                  isObscure: false,
                ),
              ),

              const SizedBox(height: 20),
              //password input
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: InputTextWidget(
                  textEditingController: passwordTextEditingController,
                  lableStringe: "Password",
                  iconData: Icons.lock_outline,
                  isObscure: true,
                ),
              ),

              const SizedBox(height: 55),

              // login & signup button
              if (showProgressBar == false)
                Column(
                  children: [
                    //login
                    Container(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),

                      child: InkWell(
                        onTap: () {
                          //login user
                          if (emailTextEditingController.text.isNotEmpty &&
                              passwordTextEditingController.text.isNotEmpty) {
                            setState(() {
                              showProgressBar = true;
                            });

                            authenticationController.loginUser(
                              emailTextEditingController.text,
                              passwordTextEditingController.text,
                            );
                          }
                        },
                        child: const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,

                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // not have a account , signup now button
                    const SizedBox(height: 65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an Account?",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () {
                            // signup screen
                            Get.to(RegistrationScreen());
                          },
                          child: const Text(
                            "  Signup Now",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                SimpleCircularProgressBar(
                  progressColors: [
                    Colors.pink,
                    Colors.green,
                    Colors.blueAccent,
                    Colors.amber,
                    Colors.red,
                    Colors.purpleAccent,
                  ],
                  animationDuration: 3,
                  backColor: Colors.white38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
