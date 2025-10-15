import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:video_player/video_player.dart';

class ProfileVideoFeedScreen extends StatefulWidget {
  final List<Video> videos;
  final int initialIndex;

  const ProfileVideoFeedScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<ProfileVideoFeedScreen> createState() => _ProfileVideoFeedScreenState();
}

class _ProfileVideoFeedScreenState extends State<ProfileVideoFeedScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final video = widget.videos[index];
          return _VideoPlayerItem(video: video);
        },
      ),
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final Video video;

  const _VideoPlayerItem({required this.video});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isVideoPaused = false;

  // Animation controllers for double-tap like
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  final userId = AuthenticationController.instanceAuth.user.uid;
  final GetVideoUrlController videoController = Get.put(
    GetVideoUrlController(),
  );
  final NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.videoUrl!)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

    // Initialize heart animation controller
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Create scale animation: 0 → 1.2 → 1.0 → 0
    _heartScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.2),
            weight: 40.0, // 40% of the animation
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 1.0),
            weight: 20.0, // 20% of the animation
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            weight: 40.0, // 40% of the animation
          ),
        ]).animate(
          CurvedAnimation(
            parent: _heartAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Create opacity animation: 0 → 1 → 0
    _heartOpacityAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 50.0, // 50% of the animation
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            weight: 50.0, // 50% of the animation
          ),
        ]).animate(
          CurvedAnimation(
            parent: _heartAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _isVideoPaused = true);
    } else {
      _controller.play();
      setState(() => _isVideoPaused = false);
    }
  }

  void _handleDoubleTapLike(TapDownDetails details) {
    final alreadyLiked = widget.video.safeLikesList.contains(userId);

    // Start the heart animation
    _heartAnimationController.forward(from: 0.0);

    // Update like status immediately
    if (!alreadyLiked) {
      setState(() {
        widget.video.safeLikesList.add(userId);
      });

      // Call the like function
      videoController.likeVideo(
        widget.video.videoId!,
        widget.video.userId!,
        widget.video.userName!,
        widget.video.thumbnailUrl!,
      );
    }
  }

  void _shareVideo() async {
    final ref = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.video.videoId);
    await ref.update({'totalShares': FieldValue.increment(1)});
    Share.share("Check out this video: ${widget.video.videoUrl}");
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.video.safeLikesList.contains(userId);

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTapDown: _handleDoubleTapLike,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _controller.value.isInitialized
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final videoAspect = _controller.value.aspectRatio;
                    final _ = constraints.maxWidth / constraints.maxHeight;

                    return Center(
                      child: AspectRatio(
                        aspectRatio: videoAspect,
                        child: VideoPlayer(_controller),
                      ),
                    );
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),

          // Smooth heart animation for double-tap
          AnimatedBuilder(
            animation: _heartAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _heartOpacityAnimation.value,
                child: Transform.scale(
                  scale: _heartScaleAnimation.value,
                  child: const Icon(
                    Icons.favorite,
                    color: Color.fromARGB(255, 255, 18, 1),
                    size: 120,
                  ),
                ),
              );
            },
          ),

          // Pause overlay icon
          if (_isVideoPaused)
            const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white70,
            ),

          // Right side buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  icon: isLiked ? Ionicons.heart : Ionicons.heart_outline,
                  count: _formatCount(widget.video.likesList!.length),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      if (isLiked) {
                        widget.video.likesList!.remove(userId);
                      } else {
                        widget.video.likesList!.add(userId);
                      }
                    });
                    videoController.likeVideo(
                      widget.video.videoId!,
                      widget.video.userId!,
                      widget.video.userName!,
                      widget.video.thumbnailUrl!,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Ionicons.chatbubble_ellipses_outline,
                  count: _formatCount(widget.video.totalComments ?? 0),
                  color: Colors.white,
                  onTap: () {
                    _controller.pause();
                    Get.to(
                      () => CommentsScreen(
                        videoId: widget.video.videoId!,
                        videoOwnerId: widget.video.userId!,
                      ),
                    )?.then((_) {
                      if (mounted) _controller.play();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Ionicons.paper_plane_outline,
                  count: _formatCount(widget.video.totalShares ?? 0),
                  color: Colors.white,
                  onTap: _shareVideo,
                ),
                const SizedBox(height: 16),

                _buildActionButton(
                  icon: Ionicons.eye_outline,
                  count: _formatCount(widget.video.views ?? 0),
                  color: Colors.white,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom description
          Positioned(
            left: 16,
            right: 80,
            bottom: 94,
            child: _ExpandableDescription(
              userName: widget.video.userName ?? "Unknown",
              description: widget.video.descriptionTags ?? "",
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String userName;
  final String description;

  const _ExpandableDescription({
    required this.userName,
    required this.description,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final text = TextSpan(text: widget.description, style: style);
            final tp = TextPainter(
              text: text,
              maxLines: 3,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final overflow = tp.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: style,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (overflow)
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
        ),
      ],
    );
  }
}
