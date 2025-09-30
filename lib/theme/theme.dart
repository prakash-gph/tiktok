// import 'package:flutter/material.dart';

// enum AppTheme { light, dark }

// class ThemeProvider with ChangeNotifier {
//   AppTheme _currentTheme = AppTheme.light;

//   AppTheme get currentTheme => _currentTheme;

//   bool get isDarkMode => _currentTheme == AppTheme.dark;

//   ThemeMode get themeMode =>
//       _currentTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;

//   void setTheme(AppTheme theme) {
//     _currentTheme = theme;
//     notifyListeners();
//   }

//   void toggleTheme() {
//     _currentTheme = _currentTheme == AppTheme.dark
//         ? AppTheme.light
//         : AppTheme.dark;
//     notifyListeners();
//   }

//   // Light theme
//   ThemeData get lightTheme => ThemeData(
//     brightness: Brightness.light,
//     primaryColor: Colors.red,
//     scaffoldBackgroundColor: Colors.white,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black,
//       titleTextStyle: TextStyle(
//         color: Color.fromARGB(255, 11, 11, 11),
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );

//   // Dark theme
//   ThemeData get darkTheme => ThemeData(
//     brightness: Brightness.dark,
//     primaryColor: Colors.red,
//     scaffoldBackgroundColor: Colors.black,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.black,
//       foregroundColor: Colors.white,
//       titleTextStyle: TextStyle(
//         color: Colors.white,
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark }

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.light;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _currentTheme == AppTheme.dark;

  ThemeMode get themeMode =>
      _currentTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme(); // load saved theme on startup
  }

  /// Set theme directly
  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
    _saveTheme(); // persist choice
  }

  /// Toggle theme
  void toggleTheme() {
    _currentTheme = _currentTheme == AppTheme.dark
        ? AppTheme.light
        : AppTheme.dark;
    notifyListeners();
    _saveTheme();
  }

  /// Load from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('appTheme');

    if (savedTheme != null && savedTheme == 'dark') {
      _currentTheme = AppTheme.dark;
    } else {
      _currentTheme = AppTheme.light;
    }

    notifyListeners();
  }

  /// Save to SharedPreferences
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'appTheme',
      _currentTheme == AppTheme.dark ? 'dark' : 'light',
    );
  }

  // Light theme
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 11, 11, 11),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // Dark theme
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
