import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/chats/screens/chat_list_screen.dart';
import 'package:tiktok/main_screens/tiktok_main_screen.dart';
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
    //_setupMessageListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
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
      ChatListScreen(),
      //  NotificationsScreen(userId: userId),
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
                  // child: Text(
                  //   badgeCount > 9 ? "9+" : "$badgeCount",
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 7,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
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
