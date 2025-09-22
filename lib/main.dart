// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import './authentication/login_screen.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/firebase_options.dart';
// import 'package:video_editor_sdk/video_editor_sdk.dart';
// // class AppBinding extends Bindings {
// //   @override
// //   void dependencies() {
// //     Get.lazyPut(() => NotificationController());
// //   }
// // }

// // ignore: non_constant_identifier_names
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await VideoEditorSdk.init(
//     'yn_Z1QwEjgPYqmRRQ9U-BctMhzuinO248to8wAcSMCvz8gWexL1rYgoQFS6PtsP_',
//   );

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   ).then((vlaue) {
//     Get.put(AuthenticationController());
//     Get.put(NotificationController());
//   });

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "TikTok",
//       theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
//       home: LoginScreen(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/notification/notification_controller.dart';
import './authentication/login_screen.dart';
import 'package:get/get.dart';
import 'package:tiktok/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    Get.put(AuthenticationController());
    Get.put(NotificationController());
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
