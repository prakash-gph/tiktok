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

          home: Scaffold(
            backgroundColor: Colors.black,
            body: LayoutBuilder(
              builder: (context, constraints) {
                // 🔹 Calculate logo size based on screen width
                double logoSize =
                    constraints.maxWidth * 0.25; // 25% of screen width
                if (logoSize < 80) logoSize = 80; // Minimum size
                if (logoSize > 150) logoSize = 150; // Maximum size

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Responsive App Logo
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "images/logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 25),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading TikTok...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
