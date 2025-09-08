import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_screen.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
import 'package:tiktok/upload_videos/video_palyer_item.dart';
import 'package:tiktok/widgets/circle_animation_profile.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class ForYouVideoScreen extends StatelessWidget {
  // ignore: use_super_parameters
  ForYouVideoScreen({Key? key}) : super(key: key);

  final GetVideoUrlController getVideoUrlController = Get.put(
    GetVideoUrlController(),
  );

  String authUserId = AuthenticationController.instanceAuth.user.uid;

  Widget buildProfile(String profilePhoto, int index) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 5,
            child: Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 252, 252, 252),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image(
                  image: NetworkImage(profilePhoto),
                  key: Key('circle_animation_$index'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    color: Color.fromARGB(255, 191, 167, 167),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMusicAlbum(String? profilePhoto, int index) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.grey, Colors.white],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image(
                image: NetworkImage(
                  profilePhoto ?? 'https://via.placeholder.com/150',
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Obx(() {
        if (getVideoUrlController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (getVideoUrlController.errorMessage.isNotEmpty) {
          return Center(child: Text(getVideoUrlController.errorMessage));
        }

        if (getVideoUrlController.videoList.isEmpty) {
          return const Center(child: Text('No videos available'));
        }

        return PageView.builder(
          itemCount: getVideoUrlController.videoList.length,
          controller: PageController(initialPage: 0, viewportFraction: 1),
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            final data = getVideoUrlController.videoList[index];

            //print((data.likesList!).length.toString());

            // Add comprehensive null checks
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
                  key: Key(
                    'video_player_$index',
                  ), // Add unique key for each video player
                ),
                Column(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    data.userName ?? 'Unknown User',

                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    data.descriptionTags ?? 'No description',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.music_note,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        data.artistSongName ?? 'Unknown Song',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            margin: EdgeInsets.only(top: size.height / 2.5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildProfile("${data.userProfileImage}", index),
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // Add like functionality
                                        getVideoUrlController.likeVideos(
                                          "${data.videoId}",
                                        );
                                      },
                                      child: Icon(
                                        Icons.favorite,
                                        size: 40,
                                        color:
                                            data.likesList!.contains(
                                              AuthenticationController
                                                  .instanceAuth
                                                  .user
                                                  .uid,
                                            )
                                            ? Colors.red
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      _formatCount(data.likesList!.length),

                                      // style: TextStyle(color: Colors.white),
                                      //  data.likesList!.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // Add null checks for CommentsScreen parameters
                                        if (data.userId == null ||
                                            data.userId == null) {
                                          Get.snackbar(
                                            'Error',
                                            'Missing data for comments',
                                          );
                                          return;
                                        }

                                        Get.to(
                                          () => CommentsScreen(
                                            videoId: "${data.videoId}",
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.comment,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      _formatCount(data.totalComments!),

                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // Add share functionality
                                        showShareSheet(
                                          context,
                                          authUserId,
                                          "${data.videoUrl}",
                                          "${data.descriptionTags}",
                                          "${data.videoId}",
                                        );
                                      },
                                      child: const Icon(
                                        Icons.reply,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      _formatCount(data.totalShares!),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                CircleAnimationProfile(
                                  key: Key(
                                    'circle_animation_$index',
                                  ), // Add unique key
                                  child: buildMusicAlbum(
                                    data.userProfileImage,
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
                ),
              ],
            );
          },
        );
      }),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  void showShareSheet(
    BuildContext context,
    String authUserId,
    String videoUrl,
    String description,
    String videoId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.black,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Share to',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: Colors.grey[800]),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  children: [
                    _buildShareOption(Icons.chat_rounded, 'Whatsapp', () {
                      Navigator.pop(context);
                      Share.share(
                        // ignore: unnecessary_brace_in_string_interps
                        'Check this out: ${videoUrl}',
                        subject: description,
                      );
                      shareVideoAndTrack(videoId, authUserId);
                    }),
                    _buildShareOption(Icons.email, 'Email', () {
                      Navigator.pop(context);
                      Share.share(
                        'Check this out: $videoUrl',
                        subject: description,
                      );
                      shareVideoAndTrack(videoId, authUserId);
                    }),
                    _buildShareOption(Icons.facebook, 'Facebook', () {
                      Navigator.pop(context);
                      // You might use a dedicated package for Facebook sharing
                      Share.share(
                        'Check this out: $videoUrl',
                        subject: description,
                      );
                      shareVideoAndTrack(videoId, authUserId);
                    }),
                    _buildShareOption(Icons.link, 'Copy Link', () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: videoUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Link copied to clipboard')),
                      );
                    }),
                    // Add more platforms as needed
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
