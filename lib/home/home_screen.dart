import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/for_you/for_you_video_screen.dart';
import 'package:tiktok/notification/notification_screen.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/search/search_screen.dart';
import 'package:tiktok/upload_videos/upload_custom_icon.dart';
// ignore: unused_import
import 'package:tiktok/upload_videos/upload_videos_screen.dart';
import 'package:tiktok/videofilterrecord/camera_screen.dart';
import 'package:tiktok/videofilterrecord/merge.dart';
import 'package:tiktok/videofilterrecord/video_recorder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int screenIndex = 0;
  int _cachedUnreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  List<Widget> get screenList => [
    const ForYouVideoScreen(),
    const SearchScreen(),
    const UploadVideosScreen(),
    //const CameraScreen(),
    //VideoAudioMergeScreen(),
    NotificationsScreen(userId: FirebaseAuth.instance.currentUser!.uid),
    ProfileScreen(
      userId: FirebaseAuth.instance.currentUser!.uid,
      isCurrentUser: true,
    ),
  ];

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
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _cachedUnreadCount = snapshot.docs.length;
              });
            }
          },
          onError: (error) {
            print('Message stream error: $error');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            screenIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade500,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: screenIndex,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(CupertinoIcons.house_fill, 0),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(CupertinoIcons.search, 1),
            label: "Search",
          ),
          const BottomNavigationBarItem(icon: UploadCustomIcon(), label: ""),
          BottomNavigationBarItem(
            icon: _buildNavIconWithBadge(
              CupertinoIcons.bubble_left_bubble_right_fill,
              3,
              _cachedUnreadCount,
            ),
            label: "Inbox",
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(CupertinoIcons.person_crop_circle_fill, 4),
            label: "Me",
          ),
        ],
      ),
      body: screenList[screenIndex],
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final bool isSelected = screenIndex == index;
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.2 : 1.0,
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.black : Colors.grey.shade500,
      ),
    );
  }

  Widget _buildNavIconWithBadge(IconData icon, int index, int unreadCount) {
    final bool isSelected = screenIndex == index;
    return Stack(
      children: [
        AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isSelected ? 1.2 : 1.0,
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.black : Colors.grey.shade500,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }
}
