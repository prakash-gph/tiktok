import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/for_you/custom_scroll_physics.dart';
import 'package:tiktok/for_you/following_screen.dart';
import 'package:tiktok/for_you/like_animation.dart';
import 'package:tiktok/notification/notification_screen.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/upload_videos/video_palyer_item.dart';
import 'package:tiktok/widgets/circle_animation_profile.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

class ForYouVideoScreen extends StatefulWidget {
  const ForYouVideoScreen({super.key});

  @override
  State<ForYouVideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<ForYouVideoScreen>
    with SingleTickerProviderStateMixin {
  final GetVideoUrlController videoController = Get.put(
    GetVideoUrlController(),
  );

  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );
  int _currentPage = 0;
  int _selectedTab = 0;
  bool _isLongPressing = false;
  late AnimationController _animationController;
  OverlayEntry? _likeAnimationOverlay;
  final Random _random = Random();
  final List<int> _displayedVideoIndices = [];
  bool _isInitialLoad = true;

  final String authUserId = AuthenticationController.instanceAuth.user.uid;

  // Cache for notification count to avoid repeated queries
  int _cachedUnreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Setup notification listener
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: authUserId)
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
            // Handle error if needed
            print('Notification stream error: $error');
          },
        );
  }

  void _loadInitialVideos() {
    if (videoController.videoList.isNotEmpty) {
      // Start with 3 random videos
      _loadMoreVideos(count: min(3, videoController.videoList.length));
    }
  }

  void _loadMoreVideos({int count = 3}) {
    if (videoController.videoList.isEmpty) return;

    final List<int> availableIndices = List.generate(
      videoController.videoList.length,
      (index) => index,
    );

    // Remove already displayed indices
    availableIndices.removeWhere(
      (index) => _displayedVideoIndices.contains(index),
    );

    // If not enough videos, recycle some
    if (availableIndices.length < count) {
      // Reset and shuffle all indices
      _displayedVideoIndices.clear();
      availableIndices.addAll(
        List.generate(videoController.videoList.length, (index) => index),
      );
      availableIndices.shuffle(_random);
    } else {
      // Shuffle available indices
      availableIndices.shuffle(_random);
    }

    // Add new indices to displayed list
    final newIndices = availableIndices.take(count).toList();
    _displayedVideoIndices.addAll(newIndices);

    // Update the UI
    if (mounted) {
      setState(() {});
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Load more videos when we're 2 away from the end
    if (page >= _displayedVideoIndices.length - 2) {
      _loadMoreVideos(count: 3);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _removeLikeAnimation();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _showLikeAnimation() {
    _removeLikeAnimation();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _likeAnimationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy - 50,
        left: position.dx - 50,
        child: LikeAnimation(
          controller: _animationController,
          onComplete: _removeLikeAnimation,
        ),
      ),
    );

    Overlay.of(context).insert(_likeAnimationOverlay!);
    _animationController.forward();
  }

  void _removeLikeAnimation() {
    _likeAnimationOverlay?.remove();
    _likeAnimationOverlay = null;
    _animationController.reset();
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildProfile(String profilePhoto, int index) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          profilePhoto,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Icon(Icons.person, color: Colors.white);
          },
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMusicAlbum(String? profilePhoto, int index) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: profilePhoto != null && profilePhoto.startsWith('http')
            ? Image.network(
                profilePhoto,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Icon(Icons.music_note, color: Colors.white);
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note, color: Colors.white),
              )
            : const Icon(Icons.music_note, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String count,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, size: 45), color: color, onPressed: onTap),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
            ),
          ),
        ),
      ),
    );
  }

  void _showShareSheet(
    BuildContext context,
    String authUserId,
    String videoUrl,
    String description,
    String videoId,
  ) {
    final currentIndex = _displayedVideoIndices[_currentPage];
    final data = videoController.videoList[currentIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share to',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,

                children: [
                  _buildShareOption(Icons.chat, 'Messages', () {
                    Navigator.pop(context);
                    Share.share(
                      'Check this out: $videoUrl',
                      subject: description,
                    );
                    shareVideoAndTrack(videoId, "${data.userId}");
                  }),
                  _buildShareOption(Icons.email, 'Email', () {
                    Navigator.pop(context);
                    Share.share(
                      'Check this out: $videoUrl',
                      subject: description,
                    );
                    shareVideoAndTrack(videoId, "${data.userId}");
                  }),
                  _buildShareOption(Icons.facebook, 'Facebook', () {
                    Navigator.pop(context);
                    Share.share(
                      'Check this out: $videoUrl',
                      subject: description,
                    );
                    shareVideoAndTrack(videoId, "${data.userId}");
                  }),
                  _buildShareOption(Icons.link, 'Copy Link', () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: videoUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                    shareVideoAndTrack(videoId, "${data.userId}");
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            radius: 28,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Create a widget for the notification icon with badge
  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => Get.to(
            () => NotificationsScreen(
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
          ),
        ),
        if (_cachedUnreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _cachedUnreadCount > 99 ? '99+' : _cachedUnreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoOverlay(data, Size size, int index) {
    return Column(
      children: [
        // Top Tab Bar
        Container(
          padding: const EdgeInsets.only(top: 48, right: 50, left: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab(
                'For You',
                _selectedTab == 0,
                () => setState(() => _selectedTab = 0),
              ),
              _buildTab(
                'Following',
                _selectedTab == 1,
                () => setState(() => _selectedTab = 1),
              ),
              const Spacer(),
              _buildNotificationIcon(),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 16, bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.userName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.descriptionTags ?? 'No description',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data.artistSongName ?? 'Unknown Song',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 80,
                margin: EdgeInsets.only(bottom: size.height / 19),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildProfile("${data.userProfileImage}", index),
                    const SizedBox(height: 20),
                    _buildActionButton(
                      (Icons.favorite_rounded),
                      _formatCount(data.likesList!.length),
                      data.likesList!.contains(authUserId)
                          ? Colors.red
                          : Colors.white,
                      () => videoController.likeVideo(
                        data.videoId,
                        data.userId,
                        data.userName,
                        data.thumbnailUrl,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      Icons.comment,
                      _formatCount(data.totalComments!),
                      Colors.white,
                      () {
                        if (data.userId == null) {
                          Get.snackbar('Error', 'Missing data for comments');
                          return;
                        }
                        Get.to(
                          () => CommentsScreen(
                            videoId: "${data.videoId}",
                            videoOwnerId: "${data.userId}",
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      Icons.reply,
                      _formatCount(data.totalShares!),
                      Colors.white,
                      () => _showShareSheet(
                        context,
                        authUserId,
                        "${data.videoUrl}",
                        "${data.descriptionTags}",
                        "${data.videoId}",
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAnimationProfile(
                      key: Key('circle_animation_$index'),
                      child: _buildMusicAlbum(
                        "${Icon(Icons.music_note)}",
                        index,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_selectedTab == 1) {
      return FollowingScreen(userId: FirebaseAuth.instance.currentUser!.uid);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (videoController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (videoController.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                Text(
                  videoController.errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    videoController.isLoading; // Assuming this method exists
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (videoController.videoList.isEmpty) {
          return const Center(
            child: Text(
              'No videos available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        // Automatically load videos when they become available
        if (_displayedVideoIndices.isEmpty && _isInitialLoad) {
          // Use a post-frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _loadInitialVideos();
                _isInitialLoad = false;
              });
            }
          });

          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        return GestureDetector(
          onDoubleTap: () {
            if (_displayedVideoIndices.isNotEmpty) {
              final currentIndex = _displayedVideoIndices[_currentPage];
              final data = videoController.videoList[currentIndex];
              videoController.likeVideo(
                data.videoId!,
                data.userId!,
                data.userName!,
                data.thumbnailUrl!,
              );
              _showLikeAnimation();
            }
          },
          onLongPressStart: (_) => setState(() => _isLongPressing = true),
          onLongPressEnd: (_) => setState(() => _isLongPressing = false),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _displayedVideoIndices.length,
                scrollDirection: Axis.vertical,
                physics: const CustomScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  if (index >= _displayedVideoIndices.length) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    );
                  }

                  final videoIndex = _displayedVideoIndices[index];
                  final data = videoController.videoList[videoIndex];

                  if (data.videoUrl == null || data.videoUrl!.isEmpty) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'Video not available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      VideoPalyerItem(
                        videoUrl: "${data.videoUrl}",
                        isPlaying: index == _currentPage && !_isLongPressing,
                        key: Key('video_player_${data.videoId}_$index'),
                      ),
                      if (_isLongPressing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Icon(
                              Icons.pause_circle_filled,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        ),
                      _buildVideoOverlay(data, size, index),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
