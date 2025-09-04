import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/globle.dart';
import 'package:tiktok/widgets/input_text_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

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
                "Create Account",
                style: GoogleFonts.acme(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              //profile avatar
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  //users choose image
                  authenticationController.chooseImageFromGallery();
                  //authenticationController.captureImageWithCamera();
                },
                child: const CircleAvatar(
                  radius: 85,
                  backgroundImage: AssetImage("images/reg.jpeg"),
                  backgroundColor: Colors.black,
                ),
              ),

              const SizedBox(height: 20),
              //username input
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: InputTextWidget(
                  textEditingController: userNameTextEditingController,
                  lableStringe: "UserName",
                  iconData: Icons.person_outlined,
                  isObscure: false,
                ),
              ),
              const SizedBox(height: 20),
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

              const SizedBox(height: 38),

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
                          // create a new account for user

                          if (authenticationController.profileImage != null &&
                              userNameTextEditingController.text.isNotEmpty &&
                              emailTextEditingController.text.isNotEmpty &&
                              passwordTextEditingController.text.isNotEmpty) {
                            setState(() {
                              showProgressBar = true;
                            });

                            authenticationController.createAccountForNewUse(
                              authenticationController.profileImage!,
                              userNameTextEditingController.text,
                              emailTextEditingController.text,
                              passwordTextEditingController.text,
                            );

                            // ignore: avoid_print
                            print(emailTextEditingController.text);
                          }
                        },
                        child: const Center(
                          child: Text(
                            "SignUp",
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
                    const SizedBox(height: 55),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an Account?",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () {
                            // signup screen
                            Get.to(LoginScreen());
                          },
                          child: const Text(
                            "  Login Now",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        //
                      ],
                    ),
                  ],
                )
              else
                // const SizedBox(height: 51),
                SimpleCircularProgressBar(
                  progressColors: [
                    Colors.pink,
                    Colors.green,
                    Colors.blueAccent,
                    Colors.amber,
                    Colors.red,
                    Colors.purpleAccent,
                  ],
                  animationDuration: 7,
                  backColor: Colors.white38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
