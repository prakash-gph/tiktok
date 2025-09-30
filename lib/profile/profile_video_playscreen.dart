import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

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

class _ProfileVideoFeedScreenState extends State<ProfileVideoFeedScreen> {
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
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final data = widget.videos[index];
          return _VideoPlayerItem(video: data);
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

final NotificationController notificationController =
    Get.find<NotificationController>();

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network("${widget.video.videoUrl}")
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // void _toggleLike() {
  //   setState(() => isLiked = !isLiked);
  //   // You can also update Firestore here for likes
  // }

  void _toggleLike() async {
    final videoRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.video.videoId);

    final userId = AuthenticationController.instanceAuth.user.uid;
    final videoOwnerId = widget.video.userId;

    setState(() => isLiked = !isLiked);

    if (isLiked) {
      await videoRef.update({
        'likesList': FieldValue.arrayUnion([userId]),
      });

      // ✅ Fetch sender details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final senderData = userDoc.data() ?? {};

      // ✅ Create notification
      if (videoOwnerId != userId) {
        await notificationController.createNotification(
          userId: "$videoOwnerId", // video owner
          senderId: userId, // liker
          senderName: senderData['name'] ?? 'Unknown User',
          senderProfileImage: senderData['image'] ?? '',
          videoId: widget.video.videoId,
          videoThumbnail: widget.video.thumbnailUrl ?? '',
          type: 'like',
        );
      }
    } else {
      await videoRef.update({
        'likesList': FieldValue.arrayRemove([userId]),
      });
      try {
        final notifQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: widget.video.userId)
            .where('senderId', isEqualTo: userId)
            .where('videoId', isEqualTo: widget.video.videoId)
            .where('type', isEqualTo: 'like')
            .get();

        for (var doc in notifQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error removing like notification: $e");
      }
    }
  }

  void _shareVideo() async {
    final videoRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.video.videoId);

    await videoRef.update({'totalShares': FieldValue.increment(1)});
    Share.share("Check out this video: ${widget.video.videoUrl}");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video Player
        _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.red)),

        // Overlay: Right-side buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 25,

                // ignore: unnecessary_string_interpolations
                backgroundImage: NetworkImage(
                  widget.video.userProfileImage ?? " ",
                ),
              ),
              const SizedBox(height: 20),

              // Like Button
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(widget.video.likesList!.length),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Comment Button
              GestureDetector(
                onTap: () {
                  Get.to(
                    () => CommentsScreen(
                      videoId: "${widget.video.videoId}",
                      videoOwnerId: "${widget.video.userId}",
                    ),
                  );
                },

                child: Column(
                  children: [
                    const Icon(Icons.comment, color: Colors.white, size: 40),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(widget.video.totalComments!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Share Button
              GestureDetector(
                onTap: _shareVideo,
                child: Column(
                  children: [
                    const Icon(Icons.share, color: Colors.white, size: 40),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(widget.video.totalShares!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Overlay: Bottom video info
        Positioned(
          left: 16,
          bottom: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.video.userName ?? "Unknown name",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.descriptionTags ?? "",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
