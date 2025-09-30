// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import 'package:tiktok/theme/theme.dart';
// import './authentication/login_screen.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   ).then((value) {
//     Get.put(AuthenticationController());
//     Get.put(NotificationController());
//   });
//   try {
//      if (kDebugMode) {
//       // Use debug provider in development
//       await FirebaseAppCheck.instance.activate(
//         androidProvider: AndroidProvider.debug,
//         appleProvider: AppleProvider.debug,
//         //webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'), // For web
//       );
//       print('App Check initialized in debug mode');
//     } else {
//       // Use production providers in release mode
//       await FirebaseAppCheck.instance.activate(
//         androidProvider: AndroidProvider.playIntegrity,
//         appleProvider: AppleProvider.appAttest,
//         //webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
//       );
//       print('App Check initialized in production mode');
//     }
//   } catch (e) {
//     print('Error initializing App Check: $e');
//     // Continue without App Check if initialization fails
//   }

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => ThemeProvider(),
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);

//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "TikTok",
//       theme: themeProvider.darkTheme,
//       darkTheme: themeProvider.lightTheme,
//       themeMode: themeProvider.themeMode, // this controls app-wide theme
//       home: LoginScreen(),
//     );
//   }
// }

// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import 'package:tiktok/theme/theme.dart';
// import './authentication/login_screen.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/firebase_options.dart';

// /// Main entry point with comprehensive error handling and performance optimization
// void main() {
//   runApp(const MyApp());
// }

// /// Root application widget with proper initialization sequence
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   final Future<FirebaseApp> _initialization = _initializeFirebase();
//   // ignore: unused_field, prefer_final_fields
//   bool _initializationError = false;
//   // ignore: unused_field
//   String? _errorMessage;

//   /// Firebase and App Check initialization with robust error handling
//   static Future<FirebaseApp> _initializeFirebase() async {
//     try {
//       WidgetsFlutterBinding.ensureInitialized();

//       // Initialize Firebase Core
//       final FirebaseApp app = await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );

//       // Initialize GetX controllers
//       Get.put(AuthenticationController());
//       Get.put(NotificationController(), permanent: true);

//       // Initialize App Check with proper error handling and retry logic
//       await _initializeAppCheckWithRetry();

//       return app;
//     } catch (e, stackTrace) {
//       debugPrint('Firebase initialization failed: $e');
//       debugPrint('Stack trace: $stackTrace');
//       rethrow;
//     }
//   }

//   /// App Check initialization with retry logic and proper error handling
//   static Future<void> _initializeAppCheckWithRetry() async {
//     const int maxRetries = 2;

//     for (int attempt = 1; attempt <= maxRetries; attempt++) {
//       try {
//         if (kDebugMode) {
//           // Debug provider for development
//           await FirebaseAppCheck.instance.activate(
//             androidProvider: AndroidProvider.debug,
//             appleProvider: AppleProvider.debug,
//           );
//           debugPrint('✅ App Check initialized in debug mode');
//         } else {
//           // Production providers for release
//           await FirebaseAppCheck.instance.activate(
//             androidProvider: AndroidProvider.playIntegrity,
//             appleProvider: AppleProvider.appAttest,
//           );
//           debugPrint('✅ App Check initialized in production mode');
//         }
//         return; // Success - exit the function
//       } catch (e) {
//         debugPrint('❌ App Check initialization attempt $attempt failed: $e');

//         if (attempt == maxRetries) {
//           debugPrint('⚠️ App Check disabled after $maxRetries attempts');
//           // Don't rethrow - allow app to continue without App Check
//           return;
//         }

//         // Exponential backoff before retry
//         await Future.delayed(Duration(seconds: attempt));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<FirebaseApp>(
//       future: _initialization,
//       builder: (context, snapshot) {
//         // Handle different states of Firebase initialization
//         switch (snapshot.connectionState) {
//           case ConnectionState.done:
//             if (snapshot.hasError) {
//               return _buildErrorWidget(snapshot.error!);
//             }
//             return _buildMainApp();

//           case ConnectionState.waiting:
//           case ConnectionState.active:
//             return _buildSplashScreen();

//           case ConnectionState.none:
//             return _buildErrorWidget(Exception('Initialization not started'));
//         }
//       },
//     );
//   }

//   /// Main application widget after successful initialization
//   Widget _buildMainApp() {
//     return ChangeNotifierProvider(
//       create: (context) => ThemeProvider(),
//       builder: (context, child) {
//         final themeProvider = Provider.of<ThemeProvider>(context);

//         return GetMaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: "TikTok",
//           theme: themeProvider.darkTheme,
//           darkTheme: themeProvider.lightTheme,
//           themeMode: themeProvider.themeMode,
//           home: const LoginScreen(),

//           // home: Scaffold(
//           //   body: Center(
//           //     child: CircularProgressIndicator(
//           //       valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
//           //     ),
//           //   ),

//           // builder: (context, child) {
//           //   return MediaQuery(
//           //     data: MediaQuery.of(context).copyWith(
//           //       // Prevent font scaling for consistent UI
//           //       textScaleFactor: 1.0,
//           //     ),
//           //     child: child!,
//           //   );
//           // },
//         );
//       },
//     );
//   }

//   /// Splash screen during initialization
//   Widget _buildSplashScreen() {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // App logo or loading indicator
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Icon(
//                   Icons.video_library,
//                   color: Colors.white,
//                   size: 40,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Loading TikTok...',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Error widget for initialization failures
//   Widget _buildErrorWidget(Object error) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 64),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Initialization Error',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   error.toString(),
//                   style: const TextStyle(color: Colors.white70, fontSize: 14),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Restart the app
//                     runApp(MyApp());
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//   correct code .......>

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/notification/notification_controller.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   Get.put(AuthenticationController()); // register auth controller
//   Get.put(NotificationController(), permanent: true);

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "TikTok Clone",
//       theme: ThemeData(primarySwatch: Colors.red),
//       // 👇 Start with loader, controller will handle navigation
//       home: Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/theme/theme.dart';
import 'package:tiktok/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase Core
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize App Check
  await _initializeAppCheckWithRetry();

  // ✅ Inject controllers
  Get.put(AuthenticationController());
  Get.put(NotificationController(), permanent: true);

  runApp(const MyApp());
}

/// 🔐 App Check initialization with retry & fallback
Future<void> _initializeAppCheckWithRetry() async {
  const int maxRetries = 2;

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('✅ App Check initialized in debug mode');
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
        debugPrint('✅ App Check initialized in production mode');
      }
      return; // success
    } catch (e) {
      debugPrint('❌ App Check init attempt $attempt failed: $e');

      if (attempt == maxRetries) {
        debugPrint('⚠️ App Check disabled after $maxRetries attempts');
        return; // continue without App Check
      }

      await Future.delayed(Duration(seconds: attempt)); // retry delay
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: "TikTok",
          theme: themeProvider.darkTheme,
          darkTheme: themeProvider.lightTheme,
          themeMode: themeProvider.themeMode,

          // 👇 Splash screen loader, auth controller will handle navigation
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ App Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading TikTok...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
