// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:get/get.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/comments/comments_screen.dart';
// import 'package:tiktok/follow_service/follow_service.dart';
// import 'package:tiktok/for_you/custom_scroll_physics.dart';
// import 'package:tiktok/for_you/like_animation.dart';
// import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
// import 'package:tiktok/profile/profile_screen.dart';
// import 'package:tiktok/share_vieos/share_videos.models.dart';
// import 'package:tiktok/upload_videos/get_video_url_controller.dart';
// import 'package:tiktok/upload_videos/video_palyer_item.dart';
// import 'package:tiktok/widgets/circle_animation_profile.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:math';
// import 'package:video_player/video_player.dart';

// class ForYouVideoScreen extends StatefulWidget {
//   final VoidCallback? onProfileTab;
//   const ForYouVideoScreen({super.key, this.onProfileTab});

//   @override
//   State<ForYouVideoScreen> createState() => VideoScreenState();
// }

// class VideoScreenState extends State<ForYouVideoScreen>
//     with SingleTickerProviderStateMixin {
//   final List<VideoPlayerController> _videoControllers = [];

//   final ValueNotifier<bool> showTopBarNotifier = ValueNotifier(true);

//   // Add this below your existing methods inside VideoScreenState
//   void setPaused(bool value) {
//     if (!_isDisposed) {
//       setState(() {
//         _isVideoPaused = value;
//       });
//     }
//   }

//   final GetVideoUrlController videoController = Get.put(
//     GetVideoUrlController(),
//   );
//   final PageController _pageController = PageController(
//     viewportFraction: 1.0,
//     keepPage: true,
//   );

//   int _currentPage = 0;
//   bool _isVideoPaused = false;
//   // bool _isLongPressing = false;
//   late AnimationController _animationController;
//   OverlayEntry? _likeAnimationOverlay;
//   final Random _random = Random();
//   final List<int> _displayedVideoIndices = [];
//   bool _isInitialLoad = true;
//   final String authUserId = AuthenticationController.instanceAuth.user.uid;
//   final FollowService _followService = FollowService();
//   // Cache for notification count
//   StreamSubscription<QuerySnapshot>? _notificationSubscription;
//   final Set<String> _viewedVideos = {};
//   bool _isDisposed = false;
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//   }

//   void _loadInitialVideos() {
//     if (videoController.videoList.isNotEmpty) {
//       _loadMoreVideos(count: min(3, videoController.videoList.length));
//     }
//   }

//   Future<void> _incrementVideoViews(String videoId) async {
//     if (_viewedVideos.contains(videoId)) return;

//     try {
//       final videoRef = FirebaseFirestore.instance
//           .collection('videos')
//           .doc(videoId);
//       await videoRef.update({'views': FieldValue.increment(1)});
//       _viewedVideos.add(videoId);
//     } catch (e) {
//       debugPrint('Failed to increment views for $videoId: $e');
//     }
//   }

//   void _loadMoreVideos({int count = 3}) {
//     if (videoController.videoList.isEmpty) return;

//     final List<int> availableIndices = List.generate(
//       videoController.videoList.length,
//       (index) => index,
//     );
//     availableIndices.removeWhere(
//       (index) => _displayedVideoIndices.contains(index),
//     );

//     if (availableIndices.length < count) {
//       _displayedVideoIndices.clear();
//       availableIndices.addAll(
//         List.generate(videoController.videoList.length, (index) => index),
//       );
//       availableIndices.shuffle(_random);
//     } else {
//       availableIndices.shuffle(_random);
//     }

//     final newIndices = availableIndices.take(count).toList();
//     _displayedVideoIndices.addAll(newIndices);

//     if (mounted) setState(() {});
//   }

//   void _onPageChanged(int page) async {
//     if (_isDisposed) return;
//     setState(() {
//       _currentPage = page;
//       _isVideoPaused = false; // Auto-play when changing videos
//     });

//     for (int i = 0; i < _videoControllers.length; i++) {
//       if (i == page) {
//         _videoControllers[i].play();
//       } else {
//         _videoControllers[i].pause();
//       }
//     }
//     if (_displayedVideoIndices.isEmpty) return;

//     final videoIndex = _displayedVideoIndices[page];
//     final data = videoController.videoList[videoIndex];

//     if (data.videoId != null) {
//       _incrementVideoViews(data.videoId!);
//     }

//     if (page >= _displayedVideoIndices.length - 2) {
//       _loadMoreVideos(count: 3);
//     }
//   }

//   void _togglePlayPause() {
//     if (!_isDisposed) {
//       setState(() => _isVideoPaused = !_isVideoPaused);
//     }
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _animationController.dispose();
//     _isDisposed = true;
//     _removeLikeAnimation();
//     _notificationSubscription?.cancel();
//     _videoControllers.clear();
//     super.dispose();
//   }

//   void _showLikeAnimation() {
//     _removeLikeAnimation();

//     final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
//     if (renderBox == null) return;

//     final position = renderBox.localToGlobal(
//       Offset(renderBox.size.width / 2, renderBox.size.height / 2),
//     );

//     _likeAnimationOverlay = OverlayEntry(
//       builder: (context) => Positioned(
//         top: position.dy - 50,
//         left: position.dx - 50,
//         child: LikeAnimation(
//           controller: _animationController,
//           onComplete: _removeLikeAnimation,
//         ),
//       ),
//     );

//     Overlay.of(context).insert(_likeAnimationOverlay!);
//     _animationController.forward();
//   }

//   void _removeLikeAnimation() {
//     _likeAnimationOverlay?.remove();
//     _likeAnimationOverlay = null;
//     _animationController.reset();
//   }

//   String _formatCount(int count) {
//     if (count < 1000) return count.toString();
//     if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
//     return '${(count / 1000000).toStringAsFixed(1)}M';
//   }

//   Widget _buildProfile(String userId, int index) {
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         String profilePhoto = '';
//         if (snapshot.hasData && snapshot.data!.exists) {
//           final userData = snapshot.data!.data() as Map<String, dynamic>;
//           profilePhoto = userData['image'] ?? '';
//         }

//         return GestureDetector(
//           onTap: () {
//             if (!_isVideoPaused) {
//               setState(() => _isVideoPaused = true);
//             }
//             if (userId == authUserId) {
//               widget.onProfileTab?.call();
//             } else {
//               Get.to(
//                 () => ProfileScreen(userId: userId, isCurrentUser: false),
//               )?.then((_) {
//                 if (mounted) {
//                   setState(() => _isVideoPaused = false);
//                 }
//               });
//             }
//           },

//           child: Container(
//             width: 33,
//             height: 33,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.white, width: 2),
//               shape: BoxShape.circle,
//             ),
//             child: ClipOval(
//               child: profilePhoto.isNotEmpty
//                   ? Image.network(
//                       profilePhoto,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Icon(Icons.person, color: Colors.white);
//                       },
//                       errorBuilder: (context, error, stackTrace) =>
//                           const Icon(Icons.person, color: Colors.white),
//                     )
//                   : const Icon(Icons.person, color: Colors.white),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMusicAlbum(String? profilePhoto, int index) {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
//         borderRadius: BorderRadius.circular(25),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(25),
//         child: profilePhoto != null && profilePhoto.startsWith('http')
//             ? Image.network(
//                 profilePhoto,
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return const Icon(Icons.music_note, color: Colors.white);
//                 },
//                 errorBuilder: (context, error, stackTrace) =>
//                     const Icon(Icons.music_note, color: Colors.white),
//               )
//             : const Icon(Icons.music_note, color: Colors.white),
//       ),
//     );
//   }

//   // 🎯 TikTok-style Action Buttons with Ionicons
//   Widget _buildActionButton({
//     required IconData icon,
//     required String count,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(25),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.4),
//                   blurRadius: 5,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.all(8),
//             child: Icon(icon, size: 28, color: color),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             count,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _shareVideo(
//     String videoUrl,
//     String description,
//     String videoId,
//     String ownerId,
//   ) async {
//     try {
//       await Share.share(
//         'Check out this video: $videoUrl\n$description',
//         subject: 'TikTok Video',
//       );
//       shareVideoAndTrack(videoId, ownerId);
//     } catch (e) {
//       debugPrint('Share error: $e');
//     }
//   }

//   // 🎯 Top Bar with Center Tabs and Right Notification

//   // Widget _buildFollowButton(String userId) {
//   //   // Hide the button if it's the current user's own profile
//   //   if (userId == authUserId) return const SizedBox.shrink();

//   //   return FutureBuilder<bool>(
//   //     future: _followService.isFollowing(userId),
//   //     builder: (context, snapshot) {
//   //       final bool isFollowing = snapshot.data ?? false;
//   //       final bool isInitialLoading =
//   //           snapshot.connectionState == ConnectionState.waiting;

//   //       return StatefulBuilder(
//   //         builder: (context, setInnerState) {
//   //           bool isLoading = false;

//   //           Future<void> handleFollowAction() async {
//   //             setInnerState(() => isLoading = true);
//   //             try {
//   //               if (isFollowing) {
//   //                 await _followService.unfollowUser(userId);
//   //               } else {
//   //                 await _followService.followUser(userId);
//   //               }
//   //             } finally {
//   //               setInnerState(() => isLoading = false);
//   //               if (mounted) setState(() {});
//   //             }
//   //           }

//   //           return AnimatedSwitcher(
//   //             duration: const Duration(milliseconds: 250),
//   //             transitionBuilder: (child, anim) =>
//   //                 ScaleTransition(scale: anim, child: child),
//   //             child: InkWell(
//   //               key: ValueKey(isFollowing),
//   //               borderRadius: BorderRadius.circular(55),
//   //               onTap: (isInitialLoading || isLoading)
//   //                   ? null
//   //                   : handleFollowAction,
//   //               child: AnimatedContainer(
//   //                 duration: const Duration(milliseconds: 250),
//   //                 curve: Curves.easeInOut,
//   //                 padding: const EdgeInsets.symmetric(
//   //                   horizontal: 14,
//   //                   vertical: 6,
//   //                 ),
//   //                 decoration: BoxDecoration(
//   //                   borderRadius: BorderRadius.circular(8),
//   //                   border: Border.all(
//   //                     color: isFollowing
//   //                         ? Colors.white.withOpacity(0.7)
//   //                         : Colors.transparent,
//   //                     width: 1.2,
//   //                   ),
//   //                   gradient: isFollowing
//   //                       ? null
//   //                       : const LinearGradient(
//   //                           colors: [
//   //                             Color(0xFFFF0069), // Instagram pink/red
//   //                             Color(0xFFFFF600), // Instagram yellow
//   //                           ],
//   //                           begin: Alignment.topLeft,
//   //                           end: Alignment.bottomRight,
//   //                         ),
//   //                   color: isFollowing ? Colors.white.withOpacity(0.12) : null,
//   //                   boxShadow: [
//   //                     if (!isFollowing)
//   //                       BoxShadow(
//   //                         color: Colors.black.withOpacity(0.3),
//   //                         offset: const Offset(0, 2),
//   //                         blurRadius: 4,
//   //                       ),
//   //                   ],
//   //                 ),
//   //                 child: isInitialLoading || isLoading
//   //                     ? const SizedBox(
//   //                         width: 12,
//   //                         height: 12,
//   //                         // child: CircularProgressIndicator(
//   //                         //   strokeWidth: 2,
//   //                         //   valueColor: AlwaysStoppedAnimation<Color>(
//   //                         //     Colors.white,
//   //                         //   ),
//   //                         // ),
//   //                       )
//   //                     : Text(
//   //                         isFollowing ? 'Following' : 'Follow',
//   //                         style: TextStyle(
//   //                           color: isFollowing ? Colors.white : Colors.black,
//   //                           fontWeight: FontWeight.bold,
//   //                           fontSize: 14,
//   //                         ),
//   //                       ),
//   //               ),
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }

//   Widget _buildFollowButton(String userId) {
//     if (userId == authUserId) return const SizedBox.shrink();

//     return FutureBuilder<bool>(
//       future: _followService.isFollowing(userId),
//       builder: (context, snapshot) {
//         bool isFollowing = snapshot.data ?? false;
//         bool isInitialLoading =
//             snapshot.connectionState == ConnectionState.waiting;

//         return StatefulBuilder(
//           builder: (context, setInnerState) {
//             bool isLoading = false;

//             Future<void> handleFollowAction() async {
//               //  Instant UI update first
//               setInnerState(() {
//                 isFollowing = !isFollowing;
//               });

//               try {
//                 if (isFollowing) {
//                   await _followService.followUser(userId);
//                 } else {
//                   await _followService.unfollowUser(userId);
//                 }
//               } catch (e) {
//                 //  Revert if Firestore fails
//                 setInnerState(() {
//                   isFollowing = !isFollowing;
//                 });
//               }
//             }

//             return AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               transitionBuilder: (child, anim) =>
//                   ScaleTransition(scale: anim, child: child),
//               child: InkWell(
//                 key: ValueKey(isFollowing),
//                 borderRadius: BorderRadius.circular(55),
//                 onTap: (isInitialLoading || isLoading)
//                     ? null
//                     : handleFollowAction,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   curve: Curves.easeInOut,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: isFollowing
//                           ? Colors.white.withOpacity(0.7)
//                           : Colors.transparent,
//                       width: 1.2,
//                     ),
//                     gradient: isFollowing
//                         ? null
//                         : const LinearGradient(
//                             colors: [Color(0xFFFF0069), Color(0xFFFFF600)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                     color: isFollowing ? Colors.white.withOpacity(0.12) : null,
//                   ),
//                   child: Text(
//                     isFollowing ? 'Following' : 'Follow',
//                     style: TextStyle(
//                       color: isFollowing ? Colors.white : Colors.black,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildVideoOverlay(data, Size size, int index) {
//     final isLiked = data.likesList!.contains(authUserId);

//     return Column(
//       children: [
//         Expanded(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: Container(
//                   padding: const EdgeInsets.only(left: 10, bottom: 30),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,

//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           //  Profile picture
//                           _buildProfile(data.userId!, index),
//                           const SizedBox(width: 5),

//                           //  Username expands flexibly but doesn't push the button off-screen
//                           Flexible(
//                             flex: 3,
//                             child: GestureDetector(
//                               onTap: () {
//                                 if (!_isVideoPaused) {
//                                   setState(() => _isVideoPaused = true);
//                                 }
//                                 if (data.userId == authUserId) {
//                                   widget.onProfileTab?.call();
//                                 } else {
//                                   Get.to(
//                                     () => ProfileScreen(
//                                       userId: data.userId,
//                                       isCurrentUser: false,
//                                     ),
//                                   )?.then((_) {
//                                     if (mounted) {
//                                       setState(() => _isVideoPaused = false);
//                                     }
//                                   });
//                                 }
//                               },
//                               child:
//                                   StreamBuilder<
//                                     DocumentSnapshot<Map<String, dynamic>>
//                                   >(
//                                     stream: FirebaseFirestore.instance
//                                         .collection('users')
//                                         .doc(data.userId)
//                                         .snapshots(),
//                                     builder: (context, snapshot) {
//                                       if (!snapshot.hasData ||
//                                           snapshot.data == null ||
//                                           !snapshot.data!.exists) {
//                                         return const Text(
//                                           '@UnknownUser',
//                                           style: TextStyle(
//                                             fontSize: 15,
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                           maxLines: 1,
//                                         );
//                                       }

//                                       final userData = snapshot.data!.data()!;
//                                       final userName =
//                                           userData['name'] ?? 'Unknown User';

//                                       return Text(
//                                         '@$userName',
//                                         style: const TextStyle(
//                                           fontSize: 15,
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                         maxLines: 1,
//                                         softWrap: false,
//                                       );
//                                     },
//                                   ),
//                             ),
//                           ),

//                           const SizedBox(width: 15),

//                           // 👇 Follow button adjusts flexibly and shrinks if space is tight
//                           Flexible(
//                             flex: 0,
//                             fit: FlexFit.loose,
//                             child: Align(
//                               alignment: Alignment.centerRight,
//                               child: ConstrainedBox(
//                                 constraints: const BoxConstraints(
//                                   minWidth: 50,
//                                   maxWidth:
//                                       100, // keeps it responsive on smaller screens
//                                 ),
//                                 child: _buildFollowButton(data.userId!),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 8),

//                       _ExpandableDescription(text: data.descriptionTags ?? ""),

//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.music_note,
//                             size: 16,
//                             color: Colors.white,
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: Text(
//                               data.artistSongName ?? 'Original sound',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // 🎯 Right Action Buttons Column with Ionicons
//               Container(
//                 width: 70,
//                 margin: EdgeInsets.only(bottom: size.height / 15, right: 8),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     // Like Button with Ionicons
//                     _buildActionButton(
//                       icon: isLiked ? Ionicons.heart : Ionicons.heart_outline,
//                       count: _formatCount(data.likesList!.length),
//                       color: isLiked ? Colors.red : Colors.white,
//                       onTap: () => videoController.likeVideo(
//                         data.videoId,
//                         data.userId,
//                         data.userName,
//                         data.thumbnailUrl,
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Comment Button with Ionicons
//                     _buildActionButton(
//                       icon: Ionicons.chatbubble_ellipses_outline,
//                       count: _formatCount(data.totalComments!),
//                       color: Colors.white,

//                       onTap: () {
//                         if (data.userId == null) {
//                           Get.snackbar('Error', 'Missing data for comments');
//                           return;
//                         }

//                         if (!_isVideoPaused) {
//                           setState(() => _isVideoPaused = true);
//                         }

//                         Get.to(
//                           () => CommentsScreen(
//                             videoId: "${data.videoId}",
//                             videoOwnerId: "${data.userId}",
//                           ),
//                         )?.then((_) {
//                           if (mounted) {
//                             setState(() => _isVideoPaused = false);
//                           }
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Share Button with Ionicons
//                     _buildActionButton(
//                       icon: Ionicons.paper_plane_outline,
//                       count: _formatCount(data.totalShares!),
//                       color: Colors.white,
//                       onTap: () => _shareVideo(
//                         data.videoUrl!,
//                         data.descriptionTags ?? '',
//                         data.videoId!,
//                         data.userId!,
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Views Counter with Ionicons
//                     _buildActionButton(
//                       icon: Ionicons.eye_outline,
//                       count: _formatCount(data.views ?? 0),
//                       color: Colors.white,
//                       onTap: () {},
//                     ),

//                     const SizedBox(height: 16),

//                     StreamBuilder<bool>(
//                       stream: SavedVideoService().isVideoSaved(data.videoId!),
//                       builder: (context, snapshot) {
//                         final isSaved = snapshot.data ?? false;

//                         return IconButton(
//                           icon: Icon(
//                             isSaved ? Icons.bookmark : Icons.bookmark_border,
//                             color: isSaved
//                                 ? const Color.fromARGB(255, 255, 255, 255)
//                                 : Colors.white,
//                             size: 28,
//                           ),
//                           onPressed: () async {
//                             final service = SavedVideoService();
//                             if (isSaved) {
//                               // 👇 remove (unsave)
//                               await service.unsaveVideo(data.videoId!);
//                             } else {
//                               // 👇 add (save)
//                               await service.saveVideo(data.videoId!);
//                             }
//                           },
//                         );
//                       },
//                     ),

//                     const SizedBox(height: 16),

//                     CircleAnimationProfile(
//                       key: Key('circle_animation_$index'),
//                       child: _buildMusicAlbum(
//                         "${Icon(Icons.music_note)}",
//                         index,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Obx(() {
//         if (videoController.isLoading) {
//           return const Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           );
//         }

//         if (videoController.errorMessage.isNotEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white, size: 50),
//                 const SizedBox(height: 16),
//                 Text(
//                   videoController.errorMessage,
//                   style: const TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => videoController.isLoading,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: Colors.black,
//                   ),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (videoController.videoList.isEmpty) {
//           return const Center(
//             child: Text(
//               'No videos available',
//               style: TextStyle(color: Colors.white, fontSize: 18),
//             ),
//           );
//         }

//         if (_displayedVideoIndices.isEmpty && _isInitialLoad) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted) {
//               setState(() {
//                 _loadInitialVideos();
//                 _isInitialLoad = false;
//               });
//             }
//           });

//           return const Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           );
//         }

//         return GestureDetector(
//           onTap: _togglePlayPause, // Single tap to play/pause
//           onDoubleTap: () {
//             if (_displayedVideoIndices.isNotEmpty) {
//               final currentIndex = _displayedVideoIndices[_currentPage];
//               final data = videoController.videoList[currentIndex];
//               videoController.likeVideo(
//                 data.videoId!,
//                 data.userId!,
//                 data.userName!,
//                 data.thumbnailUrl!,
//               );
//               _showLikeAnimation();
//             }
//           },

//           // onLongPressStart: (_) => setState(() => _isLongPressing = true),
//           // onLongPressEnd: (_) => setState(() => _isLongPressing = false),
//           child: Stack(
//             children: [
//               // PageView.builder(
//               //   controller: _pageController,
//               //   itemCount: _displayedVideoIndices.length,
//               //   scrollDirection: Axis.vertical,
//               //   physics: const CustomScrollPhysics(),
//               //   onPageChanged: _onPageChanged,
//               //   itemBuilder: (context, index) {
//               //     if (index >= _displayedVideoIndices.length) {
//               //       return Container(
//               //         color: Colors.black,
//               //         child: const Center(
//               //           child: CircularProgressIndicator(
//               //             valueColor: AlwaysStoppedAnimation<Color>(
//               //               Colors.white,
//               //             ),
//               //           ),
//               //         ),
//               //       );
//               //     }

//               //     final videoIndex = _displayedVideoIndices[index];
//               //     final data = videoController.videoList[videoIndex];

//               //     if (data.videoUrl == null || data.videoUrl!.isEmpty) {
//               //       return Container(
//               //         color: Colors.black,
//               //         child: const Center(
//               //           child: Text(
//               //             'Video not available',
//               //             style: TextStyle(color: Colors.white),
//               //           ),
//               //         ),
//               //       );
//               //     }

//               //     return Stack(
//               //       children: [
//               //         // VideoPalyerItem(
//               //         //   videoUrl: "${data.videoUrl}",
//               //         //   isPlaying:
//               //         //       index == _currentPage &&
//               //         //       !_isLongPressing &&
//               //         //       !_isVideoPaused,
//               //         //   key: Key('video_player_${data.videoId}_$index'),
//               //         //   onControllerReady: (controller) {},
//               //         //   onControllerDispose: (controller) {},
//               //         // ),
//               //         VideoPlayerItem(
//               //           videoUrl: data.videoUrl!,
//               //           isPlaying: index == _currentPage && !_isVideoPaused,
//               //           key: Key('video_player_${data.videoId}_$index'),
//               //           onControllerReady: (controller) {
//               //             if (!_videoControllers.contains(controller)) {
//               //               _videoControllers.add(controller);
//               //             }
//               //           },
//               //           onControllerDispose: (controller) {
//               //             _videoControllers.remove(controller);
//               //           },
//               //         ),

//               //         _buildVideoOverlay(data, size, index),
//               //       ],
//               //     );
//               //   },
//               // ),
//               NotificationListener<ScrollNotification>(
//                 onNotification: (scrollNotification) {
//                   if (scrollNotification is UserScrollNotification) {
//                     if (scrollNotification.direction ==
//                         ScrollDirection.reverse) {
//                       // Scrolling up — hide
//                       showTopBarNotifier.value = false;
//                     } else if (scrollNotification.direction ==
//                         ScrollDirection.forward) {
//                       // Scrolling down — show
//                       showTopBarNotifier.value = true;
//                     }
//                   }
//                   return true;
//                 },
//                 child: PageView.builder(
//                   controller: _pageController,
//                   itemCount: _displayedVideoIndices.length,
//                   scrollDirection: Axis.vertical,
//                   physics: const CustomScrollPhysics(),

//                   onPageChanged: _onPageChanged,
//                   itemBuilder: (context, index) {
//                     final videoIndex = _displayedVideoIndices[index];
//                     final data = videoController.videoList[videoIndex];

//                     return Stack(
//                       children: [
//                         VideoPlayerItem(
//                           videoUrl: data.videoUrl!,
//                           isPlaying: index == _currentPage && !_isVideoPaused,
//                           key: Key('video_player_${data.videoId}_$index'),
//                           onControllerReady: (controller) {
//                             if (!_videoControllers.contains(controller)) {
//                               _videoControllers.add(controller);
//                             }
//                           },
//                           onControllerDispose: (controller) {
//                             _videoControllers.remove(controller);
//                           },
//                         ),

//                         _buildVideoOverlay(data, size, index),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }

// class _ExpandableDescription extends StatefulWidget {
//   final String text;
//   const _ExpandableDescription({required this.text});
//   @override
//   State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
// }

// class _ExpandableDescriptionState extends State<_ExpandableDescription> {
//   bool _isExpanded = false;

//   @override
//   Widget build(BuildContext context) {
//     const textStyle = TextStyle(fontSize: 14, color: Colors.white);

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final span = TextSpan(text: widget.text, style: textStyle);
//         final tp = TextPainter(
//           text: span,
//           maxLines: 3,
//           textDirection: TextDirection.ltr,
//         )..layout(maxWidth: constraints.maxWidth);
//         final isOverflowing = tp.didExceedMaxLines;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AnimatedSize(
//               duration: const Duration(milliseconds: 200),
//               curve: Curves.easeInOut,
//               child: Text(
//                 widget.text,
//                 style: textStyle,
//                 maxLines: _isExpanded ? null : 3,
//                 overflow: _isExpanded
//                     ? TextOverflow.visible
//                     : TextOverflow.ellipsis,
//                 softWrap: true,
//               ),
//             ),
//             if (isOverflowing)
//               GestureDetector(
//                 onTap: () => setState(() => _isExpanded = !_isExpanded),
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Text(
//                     _isExpanded ? 'Show less' : 'More',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }

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
import 'package:tiktok/for_you/like_animation.dart';
import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';
import 'package:tiktok/upload_videos/get_video_url_controller.dart';
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

    Overlay.of(context)?.insert(_likeAnimationOverlay!);
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
              boxShadow: [
                // BoxShadow(
                //   color: Colors.black.withOpacity(0.4),
                //   blurRadius: 5,
                //   offset: const Offset(0, 2),
                // ),
              ],
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
                      onTap: () => _shareVideo(
                        data.videoUrl!,
                        data.descriptionTags ?? '',
                        data.videoId!,
                        data.userId!,
                      ),
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

        // small play/pause indicator in center when paused
        // ValueListenableBuilder<int>(
        //   valueListenable: _currentPageNotifier,
        //   builder: (context, current, _) {
        //     final show =
        //         current == pageIndex &&
        //         (_isVideoPaused ||
        //             !(isInitialized && controller?.value.isPlaying == true));
        //     if (!show) return const SizedBox.shrink();
        //     return const Center(
        //       child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
        //     );
        //   },
        // ),
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
