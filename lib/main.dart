import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import './authentication/login_screen.dart';
import 'package:get/get.dart';
import 'package:tiktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((vlaue) {
    Get.put(AuthenticationController());
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TikTok",
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: LoginScreen(),
    );
  }
}
