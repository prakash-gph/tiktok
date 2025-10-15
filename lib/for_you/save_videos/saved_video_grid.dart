// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:tiktok/profile/profile_videos_grid_items.dart';
import 'package:tiktok/profile/profile_video_playscreen.dart';

class SavedVideoGrid extends StatelessWidget {
  SavedVideoGrid({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _unsaveVideo(String videoId, BuildContext context) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('savedVideos')
          .doc(videoId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video removed from saved"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to remove video: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_uid)
          .collection('savedVideos')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        final savedDocs = snapshot.data!.docs;

        if (savedDocs.isEmpty) {
          return Center(
            child: Text(
              "No saved videos",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          );
        }

        final savedIds = savedDocs.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('videos')
              .where(
                FieldPath.documentId,
                whereIn: savedIds.isEmpty ? [''] : savedIds,
              )
              .snapshots(),
          builder: (context, videoSnap) {
            if (!videoSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            final videoDocs = videoSnap.data!.docs;

            if (videoDocs.isEmpty) {
              return Center(
                child: Text(
                  "No videos available",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            }

            final videos = videoDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Video(
                videoId: doc.id,
                videoUrl: data['videoUrl'] ?? '',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                totalComments: data['totalComments'],
                likesList: data['likesList'],
                totalShares: data['totalShares'],
                userId: data['userId'],
                userName: data['userName'] ?? '',
                userProfileImage: data['userProfileImage'] ?? '',
                descriptionTags: data['descriptionTags'],
                artistSongName: data['artistSongName'],
                views: data['views'],
              );
            }).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];

                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => ProfileVideoFeedScreen(
                            videos: videos,
                            initialIndex: index,
                          ),
                        );
                      },
                      child: VideoGridItem(
                        videoId: video.videoId!,
                        thumbnailUrl: video.thumbnailUrl!,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _unsaveVideo(video.videoId!, context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_remove,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
