import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/for_you/custom_scroll_physics.dart';
import 'package:tiktok/for_you/internal_share_sheet.dart';
import 'package:tiktok/for_you/like_animation.dart';
import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/widgets/circle_animation_profile.dart';

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
  // -- Controller management changed to map keyed by displayed index
  final Map<int, VideoPlayerController> _controllers = {};
  // per-controller initialized flags
  final Map<int, bool> _controllerInitialized = {};

  final ValueNotifier<bool> showTopBarNotifier = ValueNotifier(true);

  final GetVideoUrlController videoController = Get.put(
    GetVideoUrlController(),
  );

  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );

  // Used to reduce setState calls for current page
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  int _currentPage = 0;
  bool _isVideoPaused = false;
  late AnimationController _animationController;
  OverlayEntry? _likeAnimationOverlay;
  final Random _random = Random();
  final List<int> _displayedVideoIndices = [];
  bool _isInitialLoad = true;
  final String authUserId = AuthenticationController.instanceAuth.user.uid;
  final FollowService _followService = FollowService();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  final Set<String> _viewedVideos = {};
  bool _isDisposed = false;

  // configuration: how many controllers to keep (current +/- keepRange)
  final int _keepRange =
      1; // keeps current, prev and next => up to 3 controllers

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // listen to page changes via notifier for finer control
    _pageController.addListener(_pageListener);
  }

  void _pageListener() {
    // only update when page settles to near integer
    final page = _pageController.page;
    if (page == null) return;
    final int pageIndex = page.round();
    if (pageIndex != _currentPageNotifier.value && !_isDisposed) {
      _currentPageNotifier.value = pageIndex;
    }
  }

  void setPaused(bool value) {
    if (!_isDisposed && mounted) {
      setState(() {
        _isVideoPaused = value;
      });
      _applyPlayPauseToControllers();
    }
  }

  Future<void> _ensureControllerForIndex(int index) async {
    if (_controllers.containsKey(index)) return; // already exists

    if (index < 0 || index >= _displayedVideoIndices.length) return;
    final videoIndex = _displayedVideoIndices[index];
    final data = videoController.videoList[videoIndex];
    final url = data.videoUrl;
    if (url == null || url.isEmpty) return;

    try {
      final controller = VideoPlayerController.network(url);
      _controllers[index] = controller;
      _controllerInitialized[index] = false;

      await controller.initialize();
      if (_isDisposed) {
        // if disposed while initializing, immediately dispose controller
        await controller.pause();
        await controller.dispose();
        _controllers.remove(index);
        _controllerInitialized.remove(index);
        return;
      }
      // keep controller muted initially to avoid sudden audio
      controller.setLooping(true);
      controller.setVolume(0.0);

      _controllerInitialized[index] = true;
      // If this controller corresponds to current page and not paused, play it
      if (index == _currentPage && !_isVideoPaused) {
        controller.play();
        controller.setVolume(1.0);
      } else {
        controller.pause();
      }

      // Precache thumbnail image (if any) for smoother transition
      if (data.thumbnailUrl != null && data.thumbnailUrl!.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(data.thumbnailUrl!), context);
        } catch (_) {
          // ignore thumbnail precache errors
        }
      }

      // After adding, ensure we free distant controllers
      _disposeDistantControllers();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      debugPrint('Controller init error for index $index: $e');
      // clean up partial controller if present
      final c = _controllers.remove(index);
      try {
        await c?.dispose();
      } catch (_) {}
      _controllerInitialized.remove(index);
    }
  }

  // Keeps controllers only within [_keepRange] of current page, dispose others
  void _disposeDistantControllers() {
    final keys = _controllers.keys.toList();
    for (final k in keys) {
      if ((k - _currentPage).abs() > _keepRange) {
        final controller = _controllers.remove(k);
        _controllerInitialized.remove(k);
        try {
          controller?.pause();
          controller?.dispose();
        } catch (e) {
          debugPrint('Error disposing controller at $k: $e');
        }
      }
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

  void _loadInitialVideos() {
    if (videoController.videoList.isNotEmpty) {
      _loadMoreVideos(count: min(3, videoController.videoList.length));
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

    // Pre-init controllers for first few items (current, next)
    for (
      int i = max(0, _currentPage - _keepRange);
      i <=
          min(_displayedVideoIndices.length - 1, _currentPage + _keepRange + 1);
      i++
    ) {
      _ensureControllerForIndex(i);
    }

    if (mounted && !_isDisposed) setState(() {});
  }

  // Called from PageView onPageChanged to perform required updates
  void _onPageChanged(int page) async {
    if (_isDisposed) return;

    // update the current page value
    _currentPage = page;
    _currentPageNotifier.value = page;

    // ensure controller for current and neighbors
    await _ensureControllerForIndex(page);
    if (page - 1 >= 0) _ensureControllerForIndex(page - 1);
    if (page + 1 < _displayedVideoIndices.length) {
      _ensureControllerForIndex(page + 1);
    }

    // Play/pause in controllers map
    _applyPlayPauseToControllers();

    if (_displayedVideoIndices.isEmpty) return;

    final videoIndex = _displayedVideoIndices[page];
    final data = videoController.videoList[videoIndex];
    if (data.videoId != null) {
      _incrementVideoViews(data.videoId!);
    }

    // load more when approaching the end
    if (page >= _displayedVideoIndices.length - 2) {
      _loadMoreVideos(count: 3);
    }
  }

  // Play/pause logic applied on controllers map with mounted/_isDisposed checks
  void _applyPlayPauseToControllers() {
    if (_isDisposed) return;
    for (final entry in _controllers.entries) {
      final idx = entry.key;
      final c = entry.value;
      final initialized = _controllerInitialized[idx] ?? false;
      if (!initialized) continue;

      if (idx == _currentPage && !_isVideoPaused) {
        if (!c.value.isPlaying) {
          try {
            c.setVolume(1.0);
            c.play();
          } catch (e) {
            debugPrint('Play error: $e');
          }
        }
      } else {
        if (c.value.isPlaying) {
          try {
            c.pause();
            c.setVolume(0.0);
          } catch (e) {
            debugPrint('Pause error: $e');
          }
        }
      }
    }
  }

  void _togglePlayPause() {
    if (!_isDisposed && mounted) {
      setState(() => _isVideoPaused = !_isVideoPaused);
      _applyPlayPauseToControllers();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    try {
      _notificationSubscription?.cancel();
    } catch (_) {}

    try {
      _pageController.removeListener(_pageListener);
      _pageController.dispose();
    } catch (_) {}

    try {
      _animationController.dispose();
    } catch (_) {}

    _removeLikeAnimation();

    // Dispose all controllers
    final controllersCopy = Map<int, VideoPlayerController>.from(_controllers);
    for (final c in controllersCopy.values) {
      try {
        c.pause();
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    _controllerInitialized.clear();

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
    try {
      _likeAnimationOverlay?.remove();
    } catch (_) {}
    _likeAnimationOverlay = null;
    try {
      _animationController.reset();
    } catch (_) {}
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
              _applyPlayPauseToControllers();
            }
            if (userId == authUserId) {
              widget.onProfileTab?.call();
            } else {
              Get.to(
                () => ProfileScreen(userId: userId, isCurrentUser: false),
              )?.then((_) {
                if (mounted) {
                  setState(() => _isVideoPaused = false);
                  _applyPlayPauseToControllers();
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
      width: 38,
      height: 38,
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
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 1.2,
                ),
              )
            : const Icon(Icons.music_note, color: Colors.white),
      ),
    );
  }

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
              boxShadow: [],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 24, color: color),
          ),
          //  const SizedBox(height: 1),
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

  // void _shareVideo(
  //   String videoUrl,
  //   String description,
  //   String videoId,
  //   String ownerId,
  // ) async {
  //   try {
  //     await Share.share(
  //       'Check out this video: $videoUrl\n$description',
  //       subject: 'TikTok Video',
  //     );
  //     shareVideoAndTrack(videoId, ownerId);
  //   } catch (e) {
  //     debugPrint('Share error: $e');
  //   }
  // }

  void _showInternalShareSheet(
    String videoUrl,
    String description,
    String videoId,
    String thumbnailUrl,
    String ownerId,
    String ownerName,
  ) async {
    final currentUser = AuthenticationController.instanceAuth.user;
    final currentUserId = currentUser.uid;
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InternalShareSheet(
            videoId: videoId,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            description: description,
            senderId: currentUserId,
            senderName: currentUserData['name'] ?? 'User',
            senderImage: currentUserData['image'] ?? '',
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(String userId) {
    if (userId == authUserId) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _followService.isFollowing(userId),
      builder: (context, snapshot) {
        bool isFollowing = snapshot.data ?? false;
        bool isInitialLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            bool isLoading = false;

            Future<void> handleFollowAction() async {
              setInnerState(() => isFollowing = !isFollowing);

              try {
                if (isFollowing) {
                  await _followService.followUser(userId);
                } else {
                  await _followService.unfollowUser(userId);
                }
              } catch (e) {
                // revert UI if failure
                setInnerState(() => isFollowing = !isFollowing);
              }
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: InkWell(
                key: ValueKey(isFollowing),
                borderRadius: BorderRadius.circular(55),
                onTap: (isInitialLoading || isLoading)
                    ? null
                    : handleFollowAction,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                            colors: [Color(0xFFFF0069), Color(0xFFFFF600)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isFollowing ? Colors.white.withOpacity(0.12) : null,
                  ),
                  child: Text(
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
                  padding: const EdgeInsets.only(left: 10, bottom: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfile(data.userId!, index),
                          const SizedBox(width: 5),
                          Flexible(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                if (!_isVideoPaused) {
                                  setState(() => _isVideoPaused = true);
                                  _applyPlayPauseToControllers();
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
                                      _applyPlayPauseToControllers();
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
                          Flexible(
                            flex: 0,
                            fit: FlexFit.loose,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 50,
                                  maxWidth: 180,
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
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              data.artistSongName ?? 'Original sound',
                              style: const TextStyle(
                                fontSize: 11,
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

              //Right side action button
              Container(
                width: 55,
                margin: EdgeInsets.only(bottom: size.height / 26, right: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 5),
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
                          _applyPlayPauseToControllers();
                        }
                        Get.to(
                          () => CommentsScreen(
                            videoId: "${data.videoId}",
                            videoOwnerId: "${data.userId}",
                          ),
                        )?.then((_) {
                          if (mounted) {
                            setState(() => _isVideoPaused = false);
                            _applyPlayPauseToControllers();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 5),

                    _buildActionButton(
                      icon: Ionicons.paper_plane_outline,
                      count: _formatCount(data.totalShares!),
                      color: Colors.white,

                      // onTap: () => _shareVideo(
                      //   data.videoUrl!,
                      //   data.descriptionTags ?? '',
                      //   data.videoId!,
                      //   data.userId!,
                      // ),
                      // onTap: () {
                      //   // Pause video when opening share sheet
                      //   // if (!_isVideoPaused) {
                      //   //   setState(() => _isVideoPaused = true);
                      //   //   _applyPlayPauseToControllers();
                      //   // }

                      //   _showInternalShareSheet(
                      //     data.videoUrl!,
                      //     data.descriptionTags ?? '',
                      //     data.videoId!,
                      //     data.thumbnailUrl ?? '',
                      //     data.userId!,
                      //     data.userName ?? 'User',
                      //   );
                      // },
                      onTap: () async {
                        // Step 1: Pause the video immediately when share is tapped
                        final bool wasPlaying =
                            !_isVideoPaused; // Remember if it was playing
                        if (wasPlaying) {
                          setState(() => _isVideoPaused = true);
                          _applyPlayPauseToControllers();
                          debugPrint(
                            "$_isVideoPaused videos pause--------------------------------------",
                          );
                        }

                        final currentUser =
                            AuthenticationController.instanceAuth.user;
                        final currentUserId = currentUser.uid;
                        final currentUserDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .get();
                        final currentUserData =
                            currentUserDoc.data() as Map<String, dynamic>;

                        // Step 2: Show the share sheet and wait for it to close
                        final bool? shareCompleted =
                            await showModalBottomSheet<bool>(
                              // ignore: use_build_context_synchronously
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => InternalShareSheet(
                                videoId: data.videoId!,
                                videoUrl: data.videoUrl!,
                                thumbnailUrl: data.thumbnailUrl ?? '',
                                description: data.descriptionTags ?? '',
                                senderId: currentUserId,
                                senderName: currentUserData['name'] ?? 'User',
                                senderImage: currentUserData['image'] ?? '',
                              ),
                            );

                        // Step 3: When share sheet is closed, resume video if it was playing before
                        if (wasPlaying && mounted) {
                          setState(() => _isVideoPaused = false);
                          _applyPlayPauseToControllers();
                          debugPrint(
                            "$_isVideoPaused videos resume--------------------------------------",
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 5),
                    _buildActionButton(
                      icon: Ionicons.eye_outline,
                      count: _formatCount(data.views ?? 0),
                      color: Colors.white,
                      onTap: () {},
                    ),
                    const SizedBox(height: 5),
                    StreamBuilder<bool>(
                      stream: SavedVideoService().isVideoSaved(data.videoId!),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                            size: 25,
                          ),
                          onPressed: () async {
                            final service = SavedVideoService();
                            if (isSaved) {
                              await service.unsaveVideo(data.videoId!);
                            } else {
                              await service.saveVideo(data.videoId!);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 5),
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

  Widget _buildVideoPage(BuildContext context, int pageIndex) {
    // defensive: handle empty or out-of-range
    if (pageIndex < 0 || pageIndex >= _displayedVideoIndices.length) {
      return Container(color: Colors.black);
    }

    final videoIndex = _displayedVideoIndices[pageIndex];
    final data = videoController.videoList[videoIndex];

    // start initializing the controller for this page (no await here)
    _ensureControllerForIndex(pageIndex);

    final controller = _controllers[pageIndex];
    final isInitialized = _controllerInitialized[pageIndex] ?? false;

    return Stack(
      children: [
        // Video area
        Positioned.fill(
          child: Container(
            color: Colors.black,

            child:
                isInitialized &&
                    controller != null &&
                    controller.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  )
                : data.thumbnailUrl != null && data.thumbnailUrl!.isNotEmpty
                ? Center(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.network(
                        data.thumbnailUrl!,
                        fit: BoxFit.contain, // ensures full video frame visible
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, st) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
          ),
        ),

        // overlay UI
        _buildVideoOverlay(data, MediaQuery.of(context).size, pageIndex),
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
          onTap: _togglePlayPause,
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
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is UserScrollNotification) {
                    if (scrollNotification.direction ==
                        ScrollDirection.reverse) {
                      showTopBarNotifier.value = false;
                    } else if (scrollNotification.direction ==
                        ScrollDirection.forward) {
                      showTopBarNotifier.value = true;
                    }
                  }
                  return true;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _displayedVideoIndices.length,
                  scrollDirection: Axis.vertical,
                  physics: const CustomScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return _buildVideoPage(context, index);
                  },
                ),
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

// class InternalShareSheet extends StatefulWidget {
//   final String videoId;
//   final String videoUrl;
//   final String thumbnailUrl;
//   final String description;
//   final String senderId;
//   final String senderName;
//   final String senderImage;

//   InternalShareSheet({
//     required this.videoId,
//     required this.videoUrl,
//     required this.thumbnailUrl,
//     required this.description,
//     required this.senderId,
//     required this.senderName,
//     required this.senderImage,
//   });

//   @override
//   _InternalShareSheetState createState() => _InternalShareSheetState();
// }

// class _InternalShareSheetState extends State<InternalShareSheet> {
//   final TextEditingController _searchController = TextEditingController();
//   List<String> selectedUserIds = [];
//   List<DocumentSnapshot> allFollowers = [];
//   List<DocumentSnapshot> filteredUsers = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadFollowers();
//     _searchController.addListener(() {
//       filterUsers();
//     });
//   }

//   Future<void> _loadFollowers() async {
//     final followersSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.senderId)
//         .collection('followers')
//         .get();

//     List<String> followerIds = followersSnapshot.docs.map((e) => e.id).toList();

//     if (followerIds.isEmpty) {
//       setState(() => isLoading = false);
//       return;
//     }

//     final usersSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .where(FieldPath.documentId, whereIn: followerIds)
//         .get();

//     setState(() {
//       allFollowers = usersSnapshot.docs;
//       filteredUsers = usersSnapshot.docs;
//       isLoading = false;
//     });
//   }

//   void filterUsers() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       filteredUsers = allFollowers.where((userDoc) {
//         final data = userDoc.data() as Map<String, dynamic>;
//         final name = (data['name'] ?? '').toLowerCase();
//         final username = (data['username'] ?? '').toLowerCase();
//         return name.contains(query) || username.contains(query);
//       }).toList();
//     });
//   }

//   Future<void> _shareToSocial(String type) async {
//     String textToShare = "${widget.description}\n${widget.videoUrl}";

//     if (type == "whatsapp") {
//       Share.share(textToShare);
//     } else if (type == "instagram") {
//       Share.share(textToShare);
//     } else if (type == "facebook") {
//       Share.share(textToShare);
//     } else if (type == "telegram") {
//       Share.share(textToShare);
//     } else {
//       Share.share(textToShare);
//     }

//     await shareVideoAndTrack(widget.videoId, widget.senderId);
//     Get.snackbar(
//       "Shared",
//       "Shared to $type",
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//     );
//   }

//   Widget _socialIcon({
//     required IconData icon,
//     required String label,
//     required Function onTap,
//   }) {
//     return InkWell(
//       onTap: () => onTap(),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 22,
//             backgroundColor: Colors.grey[800],
//             child: Icon(icon, color: Colors.white),
//           ),
//           SizedBox(height: 5),
//           Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Social Media Share Row
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _socialIcon(
//                 icon: Icons.share,
//                 label: "Share",
//                 onTap: () => _shareToSocial("whatsapp"),
//               ),
//             ],
//           ),
//         ),

//         // Header
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Row(
//             children: [
//               IconButton(
//                 icon: Icon(Icons.close, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     "Share Video",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: selectedUserIds.isEmpty
//                     ? null
//                     : () async {
//                         await ShareService().shareVideoToUsers(
//                           videoId: widget.videoId,
//                           videoUrl: widget.videoUrl,
//                           thumbnailUrl: widget.thumbnailUrl,
//                           description: widget.description,
//                           senderId: widget.senderId,
//                           senderName: widget.senderName,
//                           senderImage: widget.senderImage,
//                           receiverIds: selectedUserIds,
//                         );

//                         await shareVideoAndTrack(
//                           widget.videoId,
//                           widget.senderId,
//                         );

//                         if (!mounted) return;

//                         Get.snackbar(
//                           "Sent",
//                           "Video shared successfully!",
//                           backgroundColor: Colors.green,
//                           colorText: Colors.white,
//                         );
//                       },
//                 child: Text(
//                   "Send",
//                   style: TextStyle(
//                     color: selectedUserIds.isEmpty ? Colors.grey : Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Search Bar
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: TextField(
//             controller: _searchController,
//             style: TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               hintText: "Search followers...",
//               hintStyle: TextStyle(color: Colors.grey),
//               prefixIcon: Icon(Icons.search, color: Colors.grey),
//               filled: true,
//               fillColor: Colors.grey[850],
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//         ),
//         // Selected count
//         if (selectedUserIds.isNotEmpty)
//           Container(
//             padding: EdgeInsets.all(12),
//             color: Colors.blue.withOpacity(0.2),
//             child: Center(
//               child: Text(
//                 "Selected: ${selectedUserIds.length} user${selectedUserIds.length > 1 ? 's' : ''}",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         // Users List
//         Expanded(
//           child: isLoading
//               ? Center(child: CircularProgressIndicator())
//               : filteredUsers.isEmpty
//               ? Center(
//                   child: Text(
//                     "No followers yet",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 )
//               : ListView.builder(
//                   itemCount: filteredUsers.length,
//                   itemBuilder: (context, index) {
//                     final userDoc = filteredUsers[index];
//                     final data = userDoc.data() as Map<String, dynamic>;
//                     final userId = userDoc.id;
//                     final name = data['name'] ?? 'User';
//                     final image = data['image'] ?? '';
//                     final isSelected = selectedUserIds.contains(userId);

//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: image.isNotEmpty
//                             ? NetworkImage(image)
//                             : null,
//                         child: image.isEmpty ? Icon(Icons.person) : null,
//                       ),
//                       title: Text(name, style: TextStyle(color: Colors.white)),
//                       trailing: Checkbox(
//                         value: isSelected,
//                         activeColor: Colors.blue,
//                         onChanged: (val) {
//                           setState(() {
//                             if (val == true) {
//                               selectedUserIds.add(userId);
//                             } else {
//                               selectedUserIds.remove(userId);
//                             }
//                           });
//                         },
//                       ),
//                       onTap: () {
//                         setState(() {
//                           if (isSelected) {
//                             selectedUserIds.remove(userId);
//                           } else {
//                             selectedUserIds.add(userId);
//                           }
//                         });
//                       },
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }
// }

//Grok---------------------------------------------------------------------------------

// class InternalShareSheet extends StatefulWidget {
//   final String videoId;
//   final String videoUrl;
//   final String thumbnailUrl;
//   final String description;
//   final String senderId;
//   final String senderName;
//   final String senderImage;

//   const InternalShareSheet({
//     super.key,
//     required this.videoId,
//     required this.videoUrl,
//     required this.thumbnailUrl,
//     required this.description,
//     required this.senderId,
//     required this.senderName,
//     required this.senderImage,
//   });

//   @override
//   State<InternalShareSheet> createState() => _InternalShareSheetState();
// }

// class _InternalShareSheetState extends State<InternalShareSheet> {
//   final TextEditingController _searchController = TextEditingController();
//   final Set<String> _selectedUserIds =
//       <String>{}; // Use Set for O(1) operations
//   List<DocumentSnapshot> _allFollowers = [];
//   List<DocumentSnapshot> _filteredUsers = [];
//   bool _isLoading = true;
//   Timer? _debounceTimer;

//   @override
//   void initState() {
//     super.initState();
//     _loadFollowers();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _debounceTimer?.cancel();
//     super.dispose();
//   }

//   // Debounced search to improve performance
//   void _onSearchChanged() {
//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(const Duration(milliseconds: 300), () {
//       _filterUsers();
//     });
//   }

//   Future<void> _loadFollowers() async {
//     try {
//       setState(() => _isLoading = true);

//       final followersSnap = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.senderId)
//           .collection('followers')
//           .get();

//       final followerIds = followersSnap.docs.map((e) => e.id).toList();
//       if (followerIds.isEmpty) {
//         if (mounted) {
//           setState(() {
//             _allFollowers = [];
//             _filteredUsers = [];
//             _isLoading = false;
//           });
//         }
//         return;
//       }

//       // Batch queries if >10 IDs (Firestore whereIn limit)
//       final List<DocumentSnapshot> users = [];
//       for (int i = 0; i < followerIds.length; i += 10) {
//         final batch = followerIds.sublist(
//           i,
//           i + 10 > followerIds.length ? followerIds.length : i + 10,
//         );
//         final batchSnap = await FirebaseFirestore.instance
//             .collection('users')
//             .where(FieldPath.documentId, whereIn: batch)
//             .get();
//         users.addAll(batchSnap.docs);
//       }

//       if (mounted) {
//         setState(() {
//           _allFollowers = users;
//           _filteredUsers = users;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         Get.snackbar(
//           "Error",
//           "Failed to load followers",
//           backgroundColor: Colors.red,
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _filterUsers() {
//     final query = _searchController.text.toLowerCase().trim();
//     if (query.isEmpty) {
//       setState(() => _filteredUsers = _allFollowers);
//       return;
//     }

//     setState(() {
//       _filteredUsers = _allFollowers.where((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         final name = (data['name'] as String?)?.toLowerCase() ?? '';
//         final username = (data['username'] as String?)?.toLowerCase() ?? '';
//         return name.contains(query) || username.contains(query);
//       }).toList();
//     });
//   }

//   Future<void> _shareToSocial(String platform) async {
//     final text = "${widget.description}\n${widget.videoUrl}";
//     await Share.share(text, subject: 'Check out this video!');

//     await shareVideoAndTrack(widget.videoId, widget.senderId);
//     Get.snackbar(
//       "Shared",
//       "Shared to $platform",
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }

//   Future<void> _sendToSelected() async {
//     if (_selectedUserIds.isEmpty) return;

//     Navigator.pop(context);

//     await ShareService().shareVideoToUsers(
//       videoId: widget.videoId,
//       videoUrl: widget.videoUrl,
//       thumbnailUrl: widget.thumbnailUrl,
//       description: widget.description,
//       senderId: widget.senderId,
//       senderName: widget.senderName,
//       senderImage: widget.senderImage,
//       receiverIds: _selectedUserIds.toList(),
//     );

//     await shareVideoAndTrack(widget.videoId, widget.senderId);

//     if (!mounted) return;

//     // Navigator.pop(context);

//     Get.snackbar(
//       "Success",
//       "Video sent to ${_selectedUserIds.length} user${_selectedUserIds.length > 1 ? 's' : ''}!",
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF121212),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           // Drag handle + Header
//           Column(
//             children: [
//               const SizedBox(height: 8),
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[600],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const Expanded(
//                       child: Center(
//                         child: Text(
//                           "Share Video",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: _selectedUserIds.isEmpty
//                           ? null
//                           : _sendToSelected,
//                       child: Text(
//                         "Send",
//                         style: TextStyle(
//                           color: _selectedUserIds.isEmpty
//                               ? Colors.grey
//                               : Colors.blueAccent,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // Social Share Buttons
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 _SocialButton(
//                   icon: Icons.more_horiz,
//                   label: "More",
//                   onTap: () => _shareToSocial("Other"),
//                 ),
//               ],
//             ),
//           ),

//           const Divider(height: 1, color: Colors.grey),

//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: "Search followers...",
//                 hintStyle: const TextStyle(color: Colors.grey),
//                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                 filled: true,
//                 fillColor: Colors.grey[850],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//             ),
//           ),

//           // Selected Count Chip
//           if (_selectedUserIds.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Chip(
//                   backgroundColor: Colors.blueAccent.withOpacity(0.2),
//                   label: Text(
//                     "${_selectedUserIds.length} selected",
//                     style: const TextStyle(color: Colors.blueAccent),
//                   ),
//                 ),
//               ),
//             ),

//           // Users List
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredUsers.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.people_outline,
//                           size: 64,
//                           color: Colors.grey[600],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           _searchController.text.isEmpty
//                               ? "No followers yet"
//                               : "No users found",
//                           style: TextStyle(
//                             color: Colors.grey[400],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     itemCount: _filteredUsers.length,
//                     itemBuilder: (context, index) {
//                       final doc = _filteredUsers[index];
//                       final data = doc.data() as Map<String, dynamic>;
//                       final userId = doc.id;
//                       final name = data['name'] ?? 'Unknown User';
//                       final username = data['username'] ?? '';
//                       final imageUrl = data['image'] as String?;

//                       final isSelected = _selectedUserIds.contains(userId);

//                       return UserTile(
//                         userId: userId,
//                         name: name,
//                         username: username,
//                         imageUrl: imageUrl,
//                         isSelected: isSelected,
//                         onToggle: () {
//                           setState(() {
//                             if (isSelected) {
//                               _selectedUserIds.remove(userId);
//                             } else {
//                               _selectedUserIds.add(userId);
//                             }
//                           });
//                         },
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Extracted reusable widgets
// class _SocialButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _SocialButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(30),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircleAvatar(
//             radius: 26,
//             backgroundColor: Colors.grey[800],
//             child: Icon(icon, color: Colors.white, size: 28),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white, fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class UserTile extends StatelessWidget {
//   final String userId;
//   final String name;
//   final String? username;
//   final String? imageUrl;
//   final bool isSelected;
//   final VoidCallback onToggle;

//   const UserTile({
//     Key? key,
//     required this.userId,
//     required this.name,
//     this.username,
//     this.imageUrl,
//     required this.isSelected,
//     required this.onToggle,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       leading: CircleAvatar(
//         radius: 24,
//         backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
//             ? NetworkImage(imageUrl!)
//             : null,
//         child: imageUrl == null || imageUrl!.isEmpty
//             ? const Icon(Icons.person, color: Colors.grey)
//             : null,
//       ),
//       title: Text(
//         name,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: username != null && username!.isNotEmpty
//           ? Text('@$username', style: TextStyle(color: Colors.grey[400]))
//           : null,
//       trailing: Checkbox(
//         value: isSelected,
//         activeColor: Colors.blueAccent,
//         side: const BorderSide(color: Colors.grey),
//         onChanged: (_) => onToggle(),
//       ),
//       selected: isSelected,
//       selectedTileColor: Colors.blueAccent.withOpacity(0.1),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       onTap: onToggle,
//     );
//   }
// }
