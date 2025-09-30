// // lib/screens/video_player_screen.dart
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoId;
//   final int likes;
//   final bool autoPlay;

//   const VideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoId,
//     required this.likes,
//     this.autoPlay = true,
//   }) : super(key: key);

//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _videoPlayerController;
//   ChewieController? _chewieController;
//   bool _isLoading = true;
//   bool _isLiked = false;
//   int _likeCount = 0;

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideoPlayer();
//     _loadLikeStatus();
//     _incrementViewCount();
//   }

//   Future<void> _initializeVideoPlayer() async {
//     // ignore: deprecated_member_use
//     _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

//     await _videoPlayerController.initialize();

//     setState(() {
//       _chewieController = ChewieController(
//         videoPlayerController: _videoPlayerController,
//         autoPlay: widget.autoPlay,
//         looping: true,
//         showControls: true,
//         materialProgressColors: ChewieProgressColors(
//           playedColor: Colors.red,
//           handleColor: Colors.red,
//           backgroundColor: Colors.grey,
//           // ignore: deprecated_member_use
//           bufferedColor: Colors.grey.withOpacity(0.5),
//         ),
//         placeholder: Container(color: Colors.black),
//         autoInitialize: true,
//       );
//       _isLoading = false;
//     });
//   }

//   Future<void> _loadLikeStatus() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     final likeDoc = await _firestore
//         .collection('videos')
//         .doc(widget.videoId)
//         .collection('likes')
//         .doc(currentUserId)
//         .get();

//     setState(() {
//       _isLiked = likeDoc.exists;
//       _likeCount = widget.likes;
//     });
//   }

//   Future<void> _toggleLike() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     setState(() {
//       _isLiked = !_isLiked;
//       _likeCount += _isLiked ? 1 : -1;
//     });

//     try {
//       if (_isLiked) {
//         await _firestore
//             .collection('videos')
//             .doc(widget.videoId)
//             .collection('likes')
//             .doc(currentUserId)
//             .set({'timestamp': FieldValue.serverTimestamp()});

//         await _firestore.collection('videos').doc(widget.videoId).update({
//           'likes': FieldValue.increment(1),
//         });
//       } else {
//         await _firestore
//             .collection('videos')
//             .doc(widget.videoId)
//             .collection('likes')
//             .doc(currentUserId)
//             .delete();

//         await _firestore.collection('videos').doc(widget.videoId).update({
//           'likes': FieldValue.increment(-1),
//         });
//       }
//     } catch (e) {
//       // Revert UI changes if there's an error
//       setState(() {
//         _isLiked = !_isLiked;
//         _likeCount += _isLiked ? 1 : -1;
//       });
//     }
//   }

//   Future<void> _incrementViewCount() async {
//     try {
//       await _firestore.collection('videos').doc(widget.videoId).update({
//         'views': FieldValue.increment(1),
//       });
//     } catch (e) {
//       print('Error updating view count: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Video player
//           if (_chewieController != null && !_isLoading)
//             Center(child: Chewie(controller: _chewieController!))
//           else
//             Center(child: CircularProgressIndicator(color: Colors.red)),

//           // Back button
//           Positioned(
//             top: 40,
//             left: 20,
//             child: IconButton(
//               icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ),

//           // Like button and count
//           Positioned(
//             right: 20,
//             bottom: 100,
//             child: Column(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     _isLiked ? Icons.favorite : Icons.favorite_border,
//                     color: _isLiked ? Colors.red : Colors.white,
//                     size: 35,
//                   ),
//                   onPressed: _toggleLike,
//                 ),
//                 Text(
//                   _likeCount.toString(),
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//                 SizedBox(height: 20),
//                 IconButton(
//                   icon: Icon(Icons.comment, color: Colors.white, size: 35),
//                   onPressed: () {
//                     // TODO: Implement comments functionality
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 IconButton(
//                   icon: Icon(Icons.share, color: Colors.white, size: 35),
//                   onPressed: () {
//                     // TODO: Implement share functionality
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
