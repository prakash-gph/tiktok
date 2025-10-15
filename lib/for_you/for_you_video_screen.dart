import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/for_you/custom_scroll_physics.dart';
import 'package:tiktok/for_you/like_animation.dart';
import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
import 'package:tiktok/for_you/save_videos/saved_video_model.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/upload_videos/video_palyer_item.dart';
import 'package:tiktok/widgets/circle_animation_profile.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';

class ForYouVideoScreen extends StatefulWidget {
  final VoidCallback? onProfileTab;
  const ForYouVideoScreen({super.key, this.onProfileTab});

  @override
  State<ForYouVideoScreen> createState() => VideoScreenState();
}

class VideoScreenState extends State<ForYouVideoScreen>
    with SingleTickerProviderStateMixin {
  final List<VideoPlayerController> _videoControllers = [];

  void pauseAllVideos() {
    for (var c in _videoControllers) {
      if (c.value.isPlaying) c.pause();
    }
  }

  void resumeVideos() {
    for (var c in _videoControllers) {
      if (!c.value.isPlaying) c.play();
    }
  }

  final GetVideoUrlController videoController = Get.put(
    GetVideoUrlController(),
  );
  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );

  int _currentPage = 0;
  bool _isVideoPaused = false;
  bool _isLongPressing = false;
  late AnimationController _animationController;
  OverlayEntry? _likeAnimationOverlay;
  final Random _random = Random();
  final List<int> _displayedVideoIndices = [];
  bool _isInitialLoad = true;
  final String authUserId = AuthenticationController.instanceAuth.user.uid;
  final FollowService _followService = FollowService();
  // Cache for notification count
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  final Set<String> _viewedVideos = {};
  bool _isDisposed = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _loadInitialVideos() {
    if (videoController.videoList.isNotEmpty) {
      _loadMoreVideos(count: min(3, videoController.videoList.length));
    }
  }

  Future<void> _incrementVideoViews(String videoId) async {
    if (_viewedVideos.contains(videoId)) return;

    try {
      final videoRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId);
      await videoRef.update({'views': FieldValue.increment(1)});
      _viewedVideos.add(videoId);
    } catch (e) {
      debugPrint('Failed to increment views for $videoId: $e');
    }
  }

  void _loadMoreVideos({int count = 3}) {
    if (videoController.videoList.isEmpty) return;

    final List<int> availableIndices = List.generate(
      videoController.videoList.length,
      (index) => index,
    );
    availableIndices.removeWhere(
      (index) => _displayedVideoIndices.contains(index),
    );

    if (availableIndices.length < count) {
      _displayedVideoIndices.clear();
      availableIndices.addAll(
        List.generate(videoController.videoList.length, (index) => index),
      );
      availableIndices.shuffle(_random);
    } else {
      availableIndices.shuffle(_random);
    }

    final newIndices = availableIndices.take(count).toList();
    _displayedVideoIndices.addAll(newIndices);

    if (mounted) setState(() {});
  }

  void _onPageChanged(int page) {
    if (_isDisposed) return;
    setState(() {
      _currentPage = page;
      _isVideoPaused = false; // Auto-play when changing videos
    });

    if (_displayedVideoIndices.isEmpty) return;

    final videoIndex = _displayedVideoIndices[page];
    final data = videoController.videoList[videoIndex];

    if (data.videoId != null) {
      _incrementVideoViews(data.videoId!);
    }

    if (page >= _displayedVideoIndices.length - 2) {
      _loadMoreVideos(count: 3);
    }
  }

  void _togglePlayPause() {
    if (!_isDisposed) {
      setState(() => _isVideoPaused = !_isVideoPaused);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _isDisposed = true;
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

  Widget _buildProfile(String userId, int index) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String profilePhoto = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          profilePhoto = userData['image'] ?? '';
        }

        return GestureDetector(
          onTap: () {
            if (!_isVideoPaused) {
              setState(() => _isVideoPaused = true);
            }
            if (userId == authUserId) {
              widget.onProfileTab?.call();
            } else {
              Get.to(
                () => ProfileScreen(userId: userId, isCurrentUser: false),
              )?.then((_) {
                if (mounted) {
                  setState(() => _isVideoPaused = false);
                }
              });
            }
          },

          child: Container(
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Icon(Icons.person, color: Colors.white);
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.white),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),
        );
      },
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

  // 🎯 TikTok-style Action Buttons with Ionicons
  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _shareVideo(
    String videoUrl,
    String description,
    String videoId,
    String ownerId,
  ) async {
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

  // 🎯 Top Bar with Center Tabs and Right Notification

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

  Widget _buildVideoOverlay(data, Size size, int index) {
    final isLiked = data.likesList!.contains(authUserId);

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
                          //  Profile picture
                          _buildProfile(data.userId!, index),
                          const SizedBox(width: 5),

                          //  Username expands flexibly but doesn't push the button off-screen
                          Flexible(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                if (!_isVideoPaused) {
                                  setState(() => _isVideoPaused = true);
                                }
                                if (data.userId == authUserId) {
                                  widget.onProfileTab?.call();
                                } else {
                                  Get.to(
                                    () => ProfileScreen(
                                      userId: data.userId,
                                      isCurrentUser: false,
                                    ),
                                  )?.then((_) {
                                    if (mounted) {
                                      setState(() => _isVideoPaused = false);
                                    }
                                  });
                                }
                              },
                              child:
                                  StreamBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(data.userId)
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
                                child: _buildFollowButton(data.userId!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      _ExpandableDescription(text: data.descriptionTags ?? ""),

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
                              data.artistSongName ?? 'Original sound',
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
                    // Like Button with Ionicons
                    _buildActionButton(
                      icon: isLiked ? Ionicons.heart : Ionicons.heart_outline,
                      count: _formatCount(data.likesList!.length),
                      color: isLiked ? Colors.red : Colors.white,
                      onTap: () => videoController.likeVideo(
                        data.videoId,
                        data.userId,
                        data.userName,
                        data.thumbnailUrl,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Comment Button with Ionicons
                    _buildActionButton(
                      icon: Ionicons.chatbubble_ellipses_outline,
                      count: _formatCount(data.totalComments!),
                      color: Colors.white,

                      onTap: () {
                        if (data.userId == null) {
                          Get.snackbar('Error', 'Missing data for comments');
                          return;
                        }

                        if (!_isVideoPaused) {
                          setState(() => _isVideoPaused = true);
                        }

                        Get.to(
                          () => CommentsScreen(
                            videoId: "${data.videoId}",
                            videoOwnerId: "${data.userId}",
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
                      count: _formatCount(data.totalShares!),
                      color: Colors.white,
                      onTap: () => _shareVideo(
                        data.videoUrl!,
                        data.descriptionTags ?? '',
                        data.videoId!,
                        data.userId!,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Views Counter with Ionicons
                    _buildActionButton(
                      icon: Ionicons.eye_outline,
                      count: _formatCount(data.views ?? 0),
                      color: Colors.white,
                      onTap: () {},
                    ),

                    const SizedBox(height: 16),

                    StreamBuilder<bool>(
                      stream: SavedVideoService().isVideoSaved(data.videoId!),
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
                              await service.unsaveVideo(data.videoId!);
                            } else {
                              // 👇 add (save)
                              await service.saveVideo(data.videoId!);
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

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
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => videoController.isLoading,
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

        if (_displayedVideoIndices.isEmpty && _isInitialLoad) {
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
          onTap: _togglePlayPause, // Single tap to play/pause
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
                        isPlaying:
                            index == _currentPage &&
                            !_isLongPressing &&
                            !_isVideoPaused,
                        key: Key('video_player_${data.videoId}_$index'),
                        onControllerReady: (controller) {},
                        onControllerDispose: (controller) {},
                      ),

                      // Play/Pause overlay when video is paused
                      // if (_isVideoPaused && index == _currentPage)
                      //   Container(
                      //     color: Colors.black54,
                      //     child: const Center(
                      //       child: Icon(
                      //         Icons.play_arrow_rounded,
                      //         color: Colors.white,
                      //         size: 80,
                      //       ),
                      //     ),
                      //   ),
                      // if (_isLongPressing)
                      //   Container(
                      //     color: Colors.black54,
                      //     child: const Center(
                      //       child: Icon(
                      //         Icons.pause_circle_filled,
                      //         color: Colors.white,
                      //         size: 80,
                      //       ),
                      //     ),
                      //   ),
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
    const textStyle = TextStyle(fontSize: 14, color: Colors.white);

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: textStyle);
        final tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Text(
                widget.text,
                style: textStyle,
                maxLines: _isExpanded ? null : 3,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'Show less' : 'More',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
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
