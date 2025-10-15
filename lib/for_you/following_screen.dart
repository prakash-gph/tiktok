import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/for_you/custom_scroll_physics.dart';
import 'package:tiktok/for_you/like_animation.dart';
import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:tiktok/upload_videos/video_palyer_item.dart';
import 'package:tiktok/widgets/circle_animation_profile.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => FollowingScreenState();
}

class FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetVideoUrlController videoController = Get.put(
    GetVideoUrlController(),
  );
  final FollowService _followService = FollowService();
  final String authUserId = AuthenticationController.instanceAuth.user.uid;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isVideoPaused = false;

  OverlayEntry? _likeAnimationOverlay;
  late AnimationController _animationController;
  final Set<String> _viewedVideos = {};

  List<VideoItem> followingVideos = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadFollowingVideos();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _removeLikeAnimation();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingVideos() async {
    try {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) {
        if (!_isDisposed) {
          setState(() => _isLoading = false);
        }
        return;
      }

      List<String> followingIds = followingSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      List<VideoItem> loadedVideos = [];

      for (int i = 0; i < followingIds.length; i += 10) {
        final batch = followingIds.skip(i).take(10).toList();
        final videosSnapshot = await _firestore
            .collection('videos')
            .where('userId', whereIn: batch)
            .orderBy('publishedDateTime', descending: true)
            .get();

        for (var doc in videosSnapshot.docs) {
          final videoData = Video.fromDocumentSnapshot(doc);
          final userDoc = await _firestore
              .collection('users')
              .doc(videoData.userId)
              .get();

          if (userDoc.exists) {
            final user = AppUser.fromSnap(userDoc);
            loadedVideos.add(VideoItem(video: videoData, user: user));
          }
        }
      }

      if (!_isDisposed) {
        setState(() {
          followingVideos = loadedVideos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading following videos: $e');
      if (!_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePlayPause() {
    if (!_isDisposed) {
      setState(() => _isVideoPaused = !_isVideoPaused);
    }
  }

  Future<void> _incrementVideoViews(String videoId) async {
    if (_viewedVideos.contains(videoId) || _isDisposed) return;

    try {
      await _firestore.collection('videos').doc(videoId).update({
        'views': FieldValue.increment(1),
      });
      _viewedVideos.add(videoId);
    } catch (e) {
      debugPrint('Failed to increment views: $e');
    }
  }

  void _onPageChanged(int index) {
    if (_isDisposed) return;

    setState(() {
      _currentPage = index;
      _isVideoPaused = false;
    });

    if (index < followingVideos.length) {
      _incrementVideoViews(followingVideos[index].video.videoId!);
    }
  }

  void _showLikeAnimation() {
    if (_isDisposed) return;
    _removeLikeAnimation();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _likeAnimationOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: position.dy - 50,
        left: position.dx - 50,
        child: LikeAnimation(
          controller: _animationController,
          onComplete: _removeLikeAnimation,
        ),
      ),
    );

    Overlay.of(context).insert(_likeAnimationOverlay!);
    _animationController
      ..reset()
      ..forward();
  }

  void _removeLikeAnimation() {
    if (_isDisposed) return;

    _likeAnimationOverlay?.remove();
    _likeAnimationOverlay = null;

    // Only reset if controller is still valid
    if (!_animationController.isDismissed && _animationController.isCompleted) {
      _animationController.reset();
    }
  }

  void _shareVideo(
    String videoUrl,
    String description,
    String videoId,
    String ownerId,
  ) async {
    if (_isDisposed) return;

    try {
      await Share.share(
        'Check out this video: $videoUrl\n$description',
        subject: 'TikTok Video',
      );
      shareVideoAndTrack(videoId, ownerId);
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildProfile(String userId, String userName) {
    return GestureDetector(
      onTap: () {
        if (!_isVideoPaused) {
          setState(() => _isVideoPaused = true);
        }

        Get.to(() => ProfileScreen(userId: userId, isCurrentUser: false))?.then(
          (_) {
            if (mounted) {
              setState(() => _isVideoPaused = false);
            }
          },
        );
      },

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(userId).snapshots(),
            builder: (context, snapshot) {
              String profilePhoto = '';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                profilePhoto = data['image'] ?? '';
              }

              return Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: profilePhoto.isNotEmpty
                      ? Image.network(
                          profilePhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: Colors.white),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 5),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
    double size = 28,
  }) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: size, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(String userId) {
    // Hide the button if it's the current user's own profile
    if (userId == authUserId) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _followService.isFollowing(userId),
      builder: (context, snapshot) {
        final bool isFollowing = snapshot.data ?? false;
        final bool isInitialLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            bool isLoading = false;

            Future<void> handleFollowAction() async {
              setInnerState(() => isLoading = true);
              try {
                if (isFollowing) {
                  await _followService.unfollowUser(userId);
                } else {
                  await _followService.followUser(userId);
                }
              } finally {
                setInnerState(() => isLoading = false);
                if (mounted) setState(() {});
              }
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: InkWell(
                key: ValueKey(isFollowing),
                borderRadius: BorderRadius.circular(55),
                onTap: (isInitialLoading || isLoading)
                    ? null
                    : handleFollowAction,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFollowing
                          ? Colors.white.withOpacity(0.7)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                    gradient: isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFFF0069), // Instagram pink/red
                              Color(0xFFFFF600), // Instagram yellow
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isFollowing ? Colors.white.withOpacity(0.12) : null,
                    boxShadow: [
                      if (!isFollowing)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                    ],
                  ),
                  child: isInitialLoading || isLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          // child: CircularProgressIndicator(
                          //   strokeWidth: 2,
                          //   valueColor: AlwaysStoppedAnimation<Color>(
                          //     Colors.white,
                          //   ),
                          // ),
                        )
                      : Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: isFollowing ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoOverlay(VideoItem item, Size size) {
    final video = item.video;
    final isLiked = video.safeLikesList.contains(authUserId);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 10, bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 👤 Profile picture
                          _buildProfile(video.userId!, video.userName ?? ''),
                          const SizedBox(width: 5),

                          // 👇 Username expands flexibly but doesn't push the button off-screen
                          Flexible(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                if (!_isVideoPaused) {
                                  setState(() => _isVideoPaused = true);
                                }
                                Get.to(
                                  () => ProfileScreen(
                                    userId: video.userId!,
                                    isCurrentUser: false,
                                  ),
                                )?.then((_) {
                                  if (mounted) {
                                    setState(() => _isVideoPaused = false);
                                  }
                                });
                              },
                              child:
                                  StreamBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(video.userId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData ||
                                          snapshot.data == null ||
                                          !snapshot.data!.exists) {
                                        return const Text(
                                          '@UnknownUser',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        );
                                      }

                                      final userData = snapshot.data!.data()!;
                                      final userName =
                                          userData['name'] ?? 'Unknown User';

                                      return Text(
                                        '@$userName',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      );
                                    },
                                  ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // 👇 Follow button adjusts flexibly and shrinks if space is tight
                          Flexible(
                            flex: 0,
                            fit: FlexFit.loose,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 50,
                                  maxWidth:
                                      100, // keeps it responsive on smaller screens
                                ),
                                child: _buildFollowButton(video.userId!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      _ExpandableDescription(text: video.descriptionTags ?? ""),

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
                              video.artistSongName ?? 'Original sound',
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

              // 🎯 Right Action Buttons Column with Ionicons
              Container(
                width: 70,
                margin: EdgeInsets.only(bottom: size.height / 15, right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    //const SizedBox(height: 20),
                    _buildActionButton(
                      icon: isLiked ? Ionicons.heart : Ionicons.heart_outline,
                      count: _formatCount(video.likesList!.length),
                      color: isLiked ? Colors.red : Colors.white,
                      onTap: () {
                        // Fast UI update
                        setState(() {
                          if (isLiked) {
                            video.likesList!.remove(authUserId);
                          } else {
                            video.likesList!.add(authUserId);
                          }
                        });

                        // Background update to Firestore
                        videoController.likeVideo(
                          video.videoId!,
                          video.userId!,
                          video.userName!,
                          video.thumbnailUrl!,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Comment Button with Ionicons
                    _buildActionButton(
                      icon: Ionicons.chatbubble_ellipses_outline,
                      count: _formatCount(video.totalComments!),
                      color: Colors.white,
                      onTap: () {
                        if (video.userId == null) {
                          Get.snackbar('Error', 'Missing data for comments');
                          return;
                        }

                        if (!_isVideoPaused) {
                          setState(() => _isVideoPaused = true);
                        }

                        Get.to(
                          () => CommentsScreen(
                            videoId: "${video.videoId}",
                            videoOwnerId: "${video.userId}",
                          ),
                        )?.then((_) {
                          if (mounted) {
                            setState(() => _isVideoPaused = false);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Share Button with Ionicons
                    _buildActionButton(
                      icon: Ionicons.paper_plane_outline,
                      count: _formatCount(video.totalShares!),
                      color: Colors.white,
                      onTap: () => _shareVideo(
                        video.videoUrl!,
                        video.descriptionTags ?? '',
                        video.videoId!,
                        video.userId!,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Views Counter with Ionicons
                    _buildActionButton(
                      icon: Ionicons.eye_outline,
                      count: _formatCount(video.views ?? 0),
                      color: Colors.white,
                      onTap: () {},
                    ),

                    const SizedBox(height: 16),

                    StreamBuilder<bool>(
                      stream: SavedVideoService().isVideoSaved(video.videoId!),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;

                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved
                                ? const Color.fromARGB(255, 255, 255, 255)
                                : Colors.white,
                            size: 28,
                          ),
                          onPressed: () async {
                            final service = SavedVideoService();
                            if (isSaved) {
                              // 👇 remove (unsave)
                              await service.unsaveVideo(video.videoId!);
                            } else {
                              // 👇 add (save)
                              await service.saveVideo(video.videoId!);
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    CircleAnimationProfile(
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.pink],
                          ),
                          borderRadius: BorderRadius.circular(22.5),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 20,
                        ),
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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (followingVideos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: Colors.white54,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Videos from Following',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Videos from people you follow will appear here',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: followingVideos.length,
            scrollDirection: Axis.vertical,
            physics: const CustomScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = followingVideos[index];
              final isCurrent = index == _currentPage;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 🎥 Video layer handles only tap & double-tap
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlayPause,
                    onDoubleTap: () {
                      if (followingVideos.isEmpty || _isDisposed) return;

                      final video = item.video;
                      final alreadyLiked = video.safeLikesList.contains(
                        authUserId,
                      );

                      _showLikeAnimation();

                      setState(() {
                        if (!alreadyLiked) {
                          video.safeLikesList.add(authUserId);
                        }
                      });

                      if (!alreadyLiked) {
                        unawaited(
                          videoController.likeVideo(
                            video.videoId!,
                            video.userId!,
                            video.userName!,
                            video.thumbnailUrl!,
                          ),
                        );
                      }
                    },
                    child: VideoPalyerItem(
                      videoUrl: item.video.videoUrl!,
                      isPlaying: isCurrent && !_isVideoPaused,
                      onControllerReady: (_) {},
                      onControllerDispose: (_) {},
                    ),
                  ),

                  // 🧩 Overlay with profile, follow, like, etc.
                  IgnorePointer(
                    ignoring:
                        false, // important: allows taps on overlay buttons
                    child: _buildVideoOverlay(item, size),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;
  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            height: 1.3,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final needsExpansion = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: _isExpanded ? null : 2,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ),
            if (needsExpansion)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class VideoItem {
  final Video video;
  final AppUser user;
  VideoItem({required this.video, required this.user});
}
