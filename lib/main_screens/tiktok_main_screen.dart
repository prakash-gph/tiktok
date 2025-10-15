// import 'package:flutter/material.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   void _onHorizontalPageChanged(int index) {
//     setState(() => _currentTabIndex = index);
//   }

//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),

//           _animatedTab('Following', 1),
//         ],
//       ),
//     );
//   }

//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: [
//               const ForYouVideoScreen(),
//               FollowingScreen(userId: userId),
//             ],
//           ),
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen> {
//   final String authUserId = AuthenticationController.instanceAuth.user.uid;

//   final PageController _pageController = PageController(initialPage: 0);
//   int _selectedIndex = 0;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: authUserId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _unreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }

//   // 🔔 Notification Icon with Badge → switches to Notification Page
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () {
//         _pageController.animateToPage(
//           2,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _selectedIndex = 2);
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Icon(
//             _selectedIndex == 2
//                 ? Ionicons.notifications
//                 : Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // 🏷 For You / Following Tabs
//   Widget _buildTabButton(String label, int index) {
//     final bool isSelected = _selectedIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _pageController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _selectedIndex = index);
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.white70,
//             fontSize: isSelected ? 18 : 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   // 🧭 Top Bar with Tabs
//   Widget _buildTopBar() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 10,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildTabButton('For You', 0),
//                 _buildTabButton('Following', 1),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const ForYouVideoScreen(),
//       FollowingScreen(userId: authUserId),
//       NotificationsScreen(userId: authUserId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // 🔄 Swipe left/right between ForYou, Following, Notifications
//           PageView(
//             controller: _pageController,
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             onPageChanged: (index) {
//               setState(() => _selectedIndex = index);
//             },
//             children: screens,
//           ),

//           // 🧭 Tabs (center)
//           _buildTopBar(),

//           // 🔔 Notification Icon (top-right)s
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 10,
//             right: 16,
//             child: _buildNotificationIcon(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

//   /// 🔔 Listen to unread notifications in Firestore
//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _unreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _horizontalController.dispose();
//     super.dispose();
//   }

//   /// 🔔 Notification Icon with Badge → switches to Notification Page
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           2,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = 2);
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Icon(
//             _currentTabIndex == 2
//                 ? Ionicons.notifications
//                 : Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _onHorizontalPageChanged(int index) {
//     setState(() => _currentTabIndex = index);
//   }

//   /// 🧭 Top Bar with Tabs and Notification Icon
//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),
//           _animatedTab('Following', 1),
//           const SizedBox(width: 24),
//           _buildNotificationIcon(),
//         ],
//       ),
//     );
//   }

//   /// ✨ Animated Tabs with underline effect
//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const ForYouVideoScreen(),
//       FollowingScreen(userId: userId),
//       NotificationsScreen(userId: userId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// Swipe horizontally between ForYou / Following / Notifications
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: screens,
//           ),

//           /// Top Tabs + Notification Icon
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

//   /// 🔔 Listen to unread notifications in Firestore
//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _unreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _horizontalController.dispose();
//     super.dispose();
//   }

//   /// 🔔 Notification Icon with Badge → opens Notification Screen
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NotificationsScreen(userId: userId),
//           ),
//         );
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           const Icon(
//             Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _onHorizontalPageChanged(int index) {
//     setState(() => _currentTabIndex = index);
//   }

//   /// 🧭 Top Bar with Tabs and Notification Icon
//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),
//           _animatedTab('Following', 1),
//           const SizedBox(width: 24),
//           _buildNotificationIcon(),
//         ],
//       ),
//     );
//   }

//   /// ✨ Animated Tabs with underline effect
//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const ForYouVideoScreen(),
//       FollowingScreen(userId: userId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// Swipe only between ForYou & Following
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: screens,
//           ),

//           /// Top Tabs + Notification Icon
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

// ForYouVideoScreen.pauseAllVideos();
// FollowingScreen.pauseAllVideos();
// ForYouVideoScreen.resumeVideos();
// static void pauseAllVideos() {
//   _videoControllers.forEach((c) => c.pause());
// }

// static void resumeVideos() {
//   _videoControllers.forEach((c) => c.play());
// }

//   /// 🔔 Listen to unread notifications in Firestore
//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//       if (mounted) {
//         setState(() {
//           _unreadCount = snapshot.docs.length;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _horizontalController.dispose();
//     super.dispose();
//   }

//   /// 🔔 Notification Icon with Badge → opens Notification Screen (pauses videos first)
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () async {
//         // 🛑 Stop or pause all playing videos before navigating
//         try {
//           ForYouVideoScreen.pauseAllVideos();
//           FollowingScreen.pauseAllVideos();
//         } catch (_) {
//           // Fail-safe: ignore if pause methods not found or not implemented
//         }

//         // 🧭 Navigate to Notifications Screen
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NotificationsScreen(userId: userId),
//           ),
//         );

//         // Resume videos when coming back
//         try {
//           if (_currentTabIndex == 0) {
//             ForYouVideoScreen.resumeVideos();
//           } else if (_currentTabIndex == 1) {
//             FollowingScreen.resumeVideos();
//           }
//         } catch (_) {}
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           const Icon(
//             Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints:
//                     const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _onHorizontalPageChanged(int index) {
//     setState(() => _currentTabIndex = index);
//   }

//   /// 🧭 Top Bar with Tabs and Notification Icon
//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),
//           _animatedTab('Following', 1),
//           const SizedBox(width: 24),
//           _buildNotificationIcon(),
//         ],
//       ),
//     );
//   }

//   /// ✨ Animated Tabs with underline effect
//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const ForYouVideoScreen(),
//       FollowingScreen(userId: userId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// Swipe only between ForYou & Following
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: screens,
//           ),

//           /// Top Tabs + Notification Icon
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

//   /// 🔔 Listen to unread notifications in Firestore
//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _unreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _horizontalController.dispose();
//     super.dispose();
//   }

//   /// 🔔 Notification Icon with Badge → opens Notification Screen (pauses videos first)
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () async {
//         // 🛑 Pause all playing videos before navigating
//         try {
//           // ForYouVideoScreen.pauseAllVideos();
//           FollowingScreen.pauseAllVideos();
//         } catch (_) {}

//         // 🧭 Navigate to Notifications Screen
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NotificationsScreen(userId: userId),
//           ),
//         );

//         // ▶️ Resume videos when returning
//         try {
//           if (_currentTabIndex == 0) {
//             //  ForYouVideoScreen.resumeVideos();
//           } else if (_currentTabIndex == 1) {
//             FollowingScreen.resumeVideos();
//           }
//         } catch (_) {}
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           const Icon(
//             Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _onHorizontalPageChanged(int index) {
//     setState(() => _currentTabIndex = index);
//   }

//   /// 🧭 Top Bar with Tabs and Notification Icon
//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),
//           _animatedTab('Following', 1),
//           const SizedBox(width: 24),
//           _buildNotificationIcon(),
//         ],
//       ),
//     );
//   }

//   /// ✨ Animated Tabs with underline and smooth transition
//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       const ForYouVideoScreen(),
//       FollowingScreen(userId: userId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// Swipe horizontally between ForYou & Following
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: screens,
//           ),

//           /// Top Tabs + Notification Icon
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/for_you/for_you_video_screen.dart';
// import 'package:tiktok/for_you/following_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';

// class TikTokMainScreen extends StatefulWidget {
//   const TikTokMainScreen({super.key});

//   @override
//   State<TikTokMainScreen> createState() => _TikTokMainScreenState();
// }

// class _TikTokMainScreenState extends State<TikTokMainScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _horizontalController = PageController(initialPage: 0);
//   int _currentTabIndex = 0;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   int _unreadCount = 0;

//   final GlobalKey<VideoScreenState> _forYouVideoScreenKey = GlobalKey();
//   final GlobalKey<FollowingScreenState> followingScreenKey = GlobalKey();

//   void _pauseAllVideos() {
//     _forYouVideoScreenKey.currentState?.pauseAllVideos();
//     followingScreenKey.currentState?.pauseAllVideos();
//   }

//   void _resumeCurrentVideo() {
//     if (_currentTabIndex == 0) {
//       _forYouVideoScreenKey.currentState?.resumeVideos();
//     } else if (_currentTabIndex == 1) {
//       followingScreenKey.currentState?.resumeVideos();
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _listenToNotifications();
//   }

//   /// 🔔 Listen to unread notifications in Firestore
//   void _listenToNotifications() {
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _unreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _horizontalController.dispose();
//     super.dispose();
//   }

//   /// 🔔 Notification Icon with Badge → opens Notification Screen
//   Widget _buildNotificationIcon() {
//     return GestureDetector(
//       onTap: () {
//         // Pause all videos before navigating
//         _pauseAllVideos();

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NotificationsScreen(userId: userId),
//           ),
//         ).then((_) {
//           // Optional: Resume videos when returning from notification screen
//           // You can remove this if you want videos to stay paused
//           _resumeCurrentVideo();
//         });
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           const Icon(
//             Ionicons.notifications_outline,
//             color: Colors.white,
//             size: 28,
//           ),
//           if (_unreadCount > 0)
//             Positioned(
//               right: -2,
//               top: -2,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   _unreadCount > 99 ? '99+' : '$_unreadCount',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _onHorizontalPageChanged(int index) {
//     // Pause previous tab's videos when switching tabs
//     if (_currentTabIndex != index) {
//       _pauseAllVideos();
//     }

//     setState(() => _currentTabIndex = index);

//     // Resume videos on the new tab
//     if (index == 0) {
//       _forYouVideoScreenKey.currentState?.resumeVideos();
//     } else if (index == 1) {
//       followingScreenKey.currentState?.resumeVideos();
//     }
//   }

//   /// 🧭 Top Bar with Tabs and Notification Icon
//   Widget _buildTopTabs() {
//     return Positioned(
//       top: MediaQuery.of(context).padding.top + 12,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _animatedTab('For You', 0),
//           const SizedBox(width: 24),
//           _animatedTab('Following', 1),
//           const SizedBox(width: 24),
//           _buildNotificationIcon(),
//         ],
//       ),
//     );
//   }

//   /// ✨ Animated Tabs with underline effect
//   Widget _animatedTab(String label, int index) {
//     final bool isActive = _currentTabIndex == index;
//     return GestureDetector(
//       onTap: () {
//         _horizontalController.animateToPage(
//           index,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         setState(() => _currentTabIndex = index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.white : Colors.transparent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         child: AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeInOut,
//           style: TextStyle(
//             fontSize: isActive ? 20 : 17,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.white60,
//             letterSpacing: isActive ? 0.5 : 0.2,
//           ),
//           child: Text(label),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screens = [
//       ForYouVideoScreen(key: _forYouVideoScreenKey),
//       FollowingScreen(key: followingScreenKey, userId: userId),
//     ];

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           /// Swipe only between ForYou & Following
//           PageView(
//             physics: const ClampingScrollPhysics(),
//             controller: _horizontalController,
//             onPageChanged: _onHorizontalPageChanged,
//             scrollDirection: Axis.horizontal,
//             children: screens,
//           ),

//           /// Top Tabs + Notification Icon
//           _buildTopTabs(),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/for_you/for_you_video_screen.dart';
import 'package:tiktok/for_you/following_screen.dart';

class TikTokMainScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap; // 👈 Callback to HomeScreen
  final VoidCallback? onProfileTab;
  const TikTokMainScreen({
    super.key,
    this.onNotificationTap,
    this.onProfileTab,
  });

  @override
  State<TikTokMainScreen> createState() => _TikTokMainScreenState();
}

class _TikTokMainScreenState extends State<TikTokMainScreen>
    with SingleTickerProviderStateMixin {
  final PageController _horizontalController = PageController(initialPage: 0);
  int _currentTabIndex = 0;
  final String userId = AuthenticationController.instanceAuth.user.uid;

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  int _unreadCount = 0;

  final GlobalKey<VideoScreenState> _forYouVideoScreenKey = GlobalKey();
  final GlobalKey<FollowingScreenState> followingScreenKey = GlobalKey();

  // void _pauseAllVideos() {
  //   _forYouVideoScreenKey.currentState?.pauseAllVideos();
  //   followingScreenKey.currentState?.pauseAllVideos();
  // }

  // void _resumeCurrentVideo() {
  //   if (_currentTabIndex == 0) {
  //     _forYouVideoScreenKey.currentState?.resumeVideos();
  //   } else if (_currentTabIndex == 1) {
  //     followingScreenKey.currentState?.resumeVideos();
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _unreadCount = snapshot.docs.length;
            });
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _horizontalController.dispose();
    super.dispose();
  }

  /// 🔔 Notification Icon with Badge → now triggers callback
  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () {
        // _pauseAllVideos();
        widget.onNotificationTap?.call(); // 👈 Triggers HomeScreen switch
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Ionicons.notifications_outline,
            color: Colors.white,
            size: 28,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onHorizontalPageChanged(int index) {
    if (_currentTabIndex != index) {
      // _pauseAllVideos();
    }
    setState(() => _currentTabIndex = index);
    // _resumeCurrentVideo();
  }

  Widget _buildTopTabs() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _animatedTab('For You', 0),
          const SizedBox(width: 24),
          _animatedTab('Following', 1),
          const SizedBox(width: 24),
          _buildNotificationIcon(), // 👈 Uses callback
        ],
      ),
    );
  }

  Widget _animatedTab(String label, int index) {
    final bool isActive = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        _horizontalController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.white : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontSize: isActive ? 20 : 17,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white60,
            letterSpacing: isActive ? 0.5 : 0.2,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ForYouVideoScreen(
        key: _forYouVideoScreenKey,
        onProfileTab: widget.onProfileTab,
      ),
      FollowingScreen(key: followingScreenKey, userId: userId),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _horizontalController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: _onHorizontalPageChanged,
            scrollDirection: Axis.horizontal,
            children: screens,
          ),
          _buildTopTabs(),
        ],
      ),
    );
  }
}
