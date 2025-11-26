// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/main_screens/tiktok_main_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';
// import 'package:tiktok/profile/profile_screen.dart';
// import 'package:tiktok/search/search_screen.dart';
// import 'package:tiktok/upload_videos/upload_custom_icon.dart';
// import 'package:tiktok/videos_upload/screens/camera_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int screenIndex = 0;
//   int _cachedUnreadCount = 0;
//   StreamSubscription<QuerySnapshot>? _notificationSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _setupMessageListener();
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     super.dispose();
//   }

//   void _setupMessageListener() {
//     final currentUserId = AuthenticationController.instanceAuth.user.uid;

//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: currentUserId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _cachedUnreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     final List<Widget> screenList = [
//       TikTokMainScreen(
//         onNotificationTap: () {
//           setState(() => screenIndex = 3); // Go to Inbox tab
//         },
//         onProfileTab: () {
//           setState(() => screenIndex = 4); //  open Profile tab
//         },
//       ),

//       const SearchScreen(),
//       const CameraScreen(),
//       NotificationsScreen(userId: userId),
//       ProfileScreen(userId: userId, isCurrentUser: true),
//     ];

//     return Scaffold(
//       body: screenList[screenIndex],

//       bottomNavigationBar: SizedBox(
//         height: 63,
//         child: BottomNavigationBar(
//           currentIndex: screenIndex,
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           selectedItemColor: Colors.black,
//           unselectedItemColor: Colors.grey.shade500,
//           showSelectedLabels: true,
//           showUnselectedLabels: true,
//           onTap: (index) => setState(() => screenIndex = index),
//           items: [
//             BottomNavigationBarItem(
//               icon: _buildNavIcon(CupertinoIcons.house_fill, 0),
//               label: "Home",
//             ),
//             BottomNavigationBarItem(
//               icon: _buildNavIcon(CupertinoIcons.search, 1),
//               label: "Search",
//             ),
//             const BottomNavigationBarItem(
//               icon: UploadCustomIcon(), //  now perfectly centered
//               label: "",
//             ),
//             BottomNavigationBarItem(
//               icon: _buildNavIconWithBadge(
//                 CupertinoIcons.bubble_left_bubble_right_fill,
//                 3,
//                 _cachedUnreadCount,
//               ),
//               label: "Inbox",
//             ),
//             BottomNavigationBarItem(
//               icon: _buildNavIcon(CupertinoIcons.person_crop_circle_fill, 4),
//               label: "Me",
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavIcon(IconData icon, int index) {
//     final bool isSelected = screenIndex == index;
//     return AnimatedScale(
//       duration: const Duration(milliseconds: 200),
//       scale: isSelected ? 1.8 : 1.0,
//       child: Icon(
//         icon,
//         size: 17,
//         color: isSelected ? Colors.black : Colors.grey.shade500,
//       ),
//     );
//   }

//   Widget _buildNavIconWithBadge(IconData icon, int index, int unreadCount) {
//     final bool isSelected = screenIndex == index;
//     return Stack(
//       children: [
//         AnimatedScale(
//           duration: const Duration(milliseconds: 200),
//           // scale: isSelected ? 1.8 : 1.0,
//           scale: 1.0,

//           child: Icon(
//             icon,
//             size: isSelected ? 25 : 17,
//             color: isSelected ? Colors.black : Colors.grey.shade500,
//           ),
//         ),
//         if (unreadCount > 0)
//           Positioned(
//             right: -0,
//             top: -0,
//             child: Container(
//               padding: const EdgeInsets.all(2),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               constraints: const BoxConstraints(minWidth: 2, minHeight: 2),
//               child: Text(
//                 unreadCount > 99 ? '99+' : unreadCount.toString(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 8,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/main_screens/tiktok_main_screen.dart';
// import 'package:tiktok/notification/notification_screen.dart';
// import 'package:tiktok/profile/profile_screen.dart';
// import 'package:tiktok/search/search_screen.dart';
// import 'package:tiktok/upload_videos/upload_custom_icon.dart';
// import 'package:tiktok/videos_upload/screens/camera_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int screenIndex = 0;
//   int _cachedUnreadCount = 0;
//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   DateTime? lastBackPressed; // For double back to exit

//   @override
//   void initState() {
//     super.initState();
//     _setupMessageListener();
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     super.dispose();
//   }

//   void _setupMessageListener() {
//     final currentUserId = AuthenticationController.instanceAuth.user.uid;
//     _notificationSubscription = FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: currentUserId)
//         .where('read', isEqualTo: false)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted) {
//             setState(() {
//               _cachedUnreadCount = snapshot.docs.length;
//             });
//           }
//         });
//   }

//   Future<bool> _onWillPop() async {
//     if (screenIndex != 0) {
//       setState(() {
//         screenIndex = 0;
//       });
//       return false; // prevent app from closing
//     }

//     // if already on home tab, double tap back to exit
//     final now = DateTime.now();
//     if (lastBackPressed == null ||
//         now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
//       lastBackPressed = now;
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(
//       //     content: Text('Press back again to exit'),
//       //     duration: Duration(seconds: 2),
//       //   ),
//       // );
//       return false;
//     }
//     return true; // exit app
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     final List<Widget> screenList = [
//       TikTokMainScreen(
//         onNotificationTap: () {
//           setState(() => screenIndex = 3);
//         },
//         onProfileTab: () {
//           setState(() => screenIndex = 4);
//         },
//       ),
//       const SearchScreen(),
//       const CameraScreen(),
//       NotificationsScreen(userId: userId),
//       ProfileScreen(userId: userId, isCurrentUser: true),
//     ];

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         body: screenList[screenIndex],
//         bottomNavigationBar: SizedBox(
//           height: 67,
//           child: BottomNavigationBar(
//             currentIndex: screenIndex,
//             type: BottomNavigationBarType.fixed,
//             backgroundColor: Colors.white,
//             selectedItemColor: Colors.black,
//             unselectedItemColor: Colors.grey.shade500,
//             showSelectedLabels: true,
//             showUnselectedLabels: true,
//             onTap: (index) => setState(() => screenIndex = index),
//             items: [
//               BottomNavigationBarItem(
//                 icon: _buildNavIcon(CupertinoIcons.house_fill, 0),
//                 label: "Home",
//               ),
//               BottomNavigationBarItem(
//                 icon: _buildNavIcon(CupertinoIcons.search, 1),
//                 label: "Search",
//               ),
//               // const BottomNavigationBarItem(
//               //   icon: UploadCustomIcon(),
//               //   label: "",
//               // ),
//               const BottomNavigationBarItem(
//                 icon: Padding(
//                   padding: EdgeInsets.only(
//                     bottom: 0,
//                   ), // raises it slightly above nav
//                   child: UploadCustomIcon(),
//                 ),
//                 label: "",
//               ),

//               BottomNavigationBarItem(
//                 icon: _buildNavIconWithBadge(
//                   CupertinoIcons.bubble_left_bubble_right_fill,
//                   3,
//                   _cachedUnreadCount,
//                 ),
//                 label: "Inbox",
//               ),
//               BottomNavigationBarItem(
//                 icon: _buildNavIcon(CupertinoIcons.person_crop_circle_fill, 4),
//                 label: "Me",
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavIcon(IconData icon, int index) {
//     final bool isSelected = screenIndex == index;
//     return AnimatedScale(
//       duration: const Duration(milliseconds: 200),
//       scale: isSelected ? 1.8 : 1.0,
//       child: Icon(
//         icon,
//         size: 17,
//         color: isSelected ? Colors.black : Colors.grey.shade500,
//       ),
//     );
//   }

//   Widget _buildNavIconWithBadge(IconData icon, int index, int unreadCount) {
//     final bool isSelected = screenIndex == index;
//     return Stack(
//       children: [
//         AnimatedScale(
//           duration: const Duration(milliseconds: 200),
//           scale: isSelected ? 1.8 : 1.0,
//           child: Icon(
//             icon,
//             size: 17,
//             color: isSelected ? Colors.black : Colors.grey.shade500,
//           ),
//         ),
//         // if (unreadCount > 0)
//         //   Positioned(
//         //     right: 0,
//         //     top: 0,
//         //     child: Container(
//         //       padding: const EdgeInsets.all(2),
//         //       decoration: BoxDecoration(
//         //         color: Colors.red,
//         //         borderRadius: BorderRadius.circular(10),
//         //       ),
//         //       constraints: const BoxConstraints(minWidth: 2, minHeight: 2),
//         //       child: Text(
//         //         unreadCount > 99 ? '99+' : unreadCount.toString(),
//         //         style: const TextStyle(
//         //           color: Colors.white,
//         //           fontSize: 8,
//         //           fontWeight: FontWeight.bold,
//         //         ),
//         //         textAlign: TextAlign.center,
//         //       ),
//         //     ),
//         //   ),
//       ],
//     );
//   }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/main_screens/tiktok_main_screen.dart';
import 'package:tiktok/notification/notification_screen.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/search/search_screen.dart';
import 'package:tiktok/upload_videos/upload_custom_icon.dart';
import 'package:tiktok/videos_upload/screens/camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int screenIndex = 0;
  int _cachedUnreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  DateTime? lastBackPressed;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    final currentUserId = AuthenticationController.instanceAuth.user.uid;
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _cachedUnreadCount = snapshot.docs.length;
            });
          }
        });
  }

  Future<bool> _onWillPop() async {
    if (screenIndex != 0) {
      setState(() {
        screenIndex = 0;
      });
      return false;
    }

    final now = DateTime.now();
    if (lastBackPressed == null ||
        now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
      lastBackPressed = now;
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final List<Widget> screenList = [
      TikTokMainScreen(
        onNotificationTap: () {
          setState(() => screenIndex = 3);
        },
        onProfileTab: () {
          setState(() => screenIndex = 4);
        },
      ),
      const SearchScreen(),
      const CameraScreen(),
      NotificationsScreen(userId: userId),
      ProfileScreen(userId: userId, isCurrentUser: true),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: screenList[screenIndex],
        bottomNavigationBar: _buildProfessionalBottomNav(),
      ),
    );
  }

  //   Widget _buildProfessionalBottomNav() {
  //     return Container(
  //       height: 61,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         border: Border(
  //           top: BorderSide(color: Colors.grey.shade300, width: 0.5),
  //         ),
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: [
  //           _buildNavItem(
  //             icon: Icons.home_outlined,
  //             activeIcon: Icons.home_rounded,
  //             index: 0,
  //             label: "Home",
  //           ),
  //           _buildNavItem(
  //             icon: Icons.explore_outlined,
  //             activeIcon: Icons.explore_rounded,
  //             index: 1,
  //             label: "Discover",
  //           ),
  //           _buildNavItem(
  //             icon: Icons.add_circle_outline_rounded,
  //             activeIcon: Icons.add_circle_rounded,
  //             index: 2,
  //             label: "",
  //             isCustom: true,
  //           ),
  //           _buildNavItemWithBadge(
  //             icon: Icons.mail_outline_rounded,
  //             activeIcon: Icons.mail_rounded,
  //             index: 3,
  //             label: "Inbox",
  //             badgeCount: _cachedUnreadCount,
  //           ),
  //           _buildNavItem(
  //             icon: Icons.account_circle_outlined,
  //             activeIcon: Icons.account_circle_rounded,
  //             index: 4,
  //             label: "Profile",
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   Widget _buildNavItem({
  //     required IconData icon,
  //     required IconData activeIcon,
  //     required int index,
  //     required String label,
  //     bool isCustom = false,
  //   }) {
  //     final isSelected = screenIndex == index;

  //     return GestureDetector(
  //       onTap: () => setState(() => screenIndex = index),
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             if (isCustom)
  //               const UploadCustomIcon() // Your custom upload icon
  //             else
  //               Icon(
  //                 isSelected ? activeIcon : icon,
  //                 size: 24,
  //                 color: isSelected ? Colors.black : Colors.grey.shade700,
  //               ),
  //             const SizedBox(height: 2),
  //             Text(
  //               label,
  //               style: TextStyle(
  //                 fontSize: 10,
  //                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
  //                 color: isSelected ? Colors.black : Colors.grey.shade600,
  //                 letterSpacing: -0.2,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   Widget _buildNavItemWithBadge({
  //     required IconData icon,
  //     required IconData activeIcon,
  //     required int index,
  //     required String label,
  //     required int badgeCount,
  //   }) {
  //     final isSelected = screenIndex == index;

  //     return GestureDetector(
  //       onTap: () => setState(() => screenIndex = index),
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //         child: Stack(
  //           clipBehavior: Clip.none,
  //           children: [
  //             Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(
  //                   isSelected ? activeIcon : icon,
  //                   size: 24,
  //                   color: isSelected ? Colors.black : Colors.grey.shade700,
  //                 ),
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   label,
  //                   style: TextStyle(
  //                     fontSize: 10,
  //                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
  //                     color: isSelected ? Colors.black : Colors.grey.shade600,
  //                     letterSpacing: -0.2,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             if (badgeCount > 0)
  //               Positioned(
  //                 right: -2,
  //                 top: -2,
  //                 child: Container(
  //                   padding: const EdgeInsets.all(1.5),
  //                   decoration: BoxDecoration(
  //                     color: Colors.red,
  //                     borderRadius: BorderRadius.circular(6),
  //                     border: Border.all(color: Colors.white, width: 1.5),
  //                   ),
  //                   constraints: const BoxConstraints(
  //                     minWidth: 12,
  //                     minHeight: 12,
  //                   ),
  //                   child: badgeCount > 9
  //                       ? const SizedBox() // Just show dot for high numbers
  //                       : Text(
  //                           badgeCount.toString(),
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 7,
  //                             fontWeight: FontWeight.bold,
  //                             height: 1,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }

  Widget _buildProfessionalBottomNav() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      top: false,
      child: Container(
        height: 60 + bottomPadding,
        width: screenWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: "Home",
            ),
            SizedBox(width: 17),
            _navItem(
              index: 1,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: "Discover",
            ),
            SizedBox(width: 27),
            _centerUploadButton(),

            SizedBox(width: 42),

            _navItemWithBadge(
              index: 3,
              icon: Icons.mail_outline_rounded,
              activeIcon: Icons.mail_rounded,
              label: "Inbox",
              badgeCount: _cachedUnreadCount,
            ),

            _navItem(
              index: 4,
              icon: Icons.account_circle_outlined,
              activeIcon: Icons.account_circle_rounded,
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool active = screenIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => screenIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 26,
              color: active ? Colors.black : Colors.grey.shade700,
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemWithBadge({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int badgeCount,
  }) {
    final bool active = screenIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => screenIndex = index),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 26,
                  color: active ? Colors.black : Colors.grey.shade700,
                ),
                SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            if (badgeCount > 0)
              Positioned(
                right: MediaQuery.of(context).size.width * 0.11,
                top: 6,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                  child: Text(
                    badgeCount > 9 ? "9+" : "$badgeCount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _centerUploadButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: () => setState(() => screenIndex = 2),
        child: const UploadCustomIcon(),
      ),
    );
  }
}
