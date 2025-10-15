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
