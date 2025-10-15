import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/for_you/save_videos/saved_video_model.dart';
import 'package:tiktok/upload_videos/video_palyer_item.dart';
import 'package:video_player/video_player.dart';

class SavedVideoTile extends StatelessWidget {
  final SavedVideoModel video;
  const SavedVideoTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: VideoPalyerItem(
                videoUrl: video.videoUrl,
                isPlaying: true,
                onControllerReady: (VideoPlayerController p1) {},
                onControllerDispose: (VideoPlayerController p1) {},
              ),
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(video.thumbnailUrl, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              video.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
