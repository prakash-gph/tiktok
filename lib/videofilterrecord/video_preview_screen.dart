// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';

// class VideoPreviewScreen extends StatefulWidget {
//   final XFile videoFile;
//   final Filter filter;

//   const VideoPreviewScreen({
//     Key? key,
//     required this.videoFile,
//     required this.filter,
//   }) : super(key: key);

//   @override
//   _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
// }

// class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
//   late VideoPlayerController _videoController;
//   late Future<void> _initializeVideoPlayerFuture;

//   @override
//   void initState() {
//     super.initState();
//     _videoController = VideoPlayerController.file(File(widget.videoFile.path));
//     _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
//       setState(() {});
//       _videoController.setLooping(true);
//       _videoController.play();
//     });
//   }

//   @override
//   void dispose() {
//     _videoController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           FutureBuilder(
//             future: _initializeVideoPlayerFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return Center(
//                   child: AspectRatio(
//                     aspectRatio: _videoController.value.aspectRatio,
//                     child: ColorFiltered(
//                       colorFilter: widget.filter.colorFilter ??
//                           const ColorFilter.mode(Colors.transparent, BlendMode.src),
//                       child: VideoPlayer(_videoController),
//                     ),
//                   ),
//                 );
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           ),
//           Positioned(
//             top: 40,
//             left: 16,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           Positioned(
//             bottom: 40,
//             right: 16,
//             child: FloatingActionButton(
//               onPressed: () {
//                 // Save or share the video
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Video saved to gallery!')),
//                 );
//               },
//               child: const Icon(Icons.check),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/utils/filters.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final XFile videoFile;
  final VideoFilter videoFilter; // Changed from Filter to VideoFilter

  const VideoPreviewScreen({
    Key? key,
    required this.videoFile,
    required this.videoFilter, // Changed parameter name
  }) : super(key: key);

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoFile.path));
    _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
      setState(() {});
      _videoController.setLooping(true);
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: ColorFiltered(
                      colorFilter:
                          widget.videoFilter.colorFilter ?? // Updated reference
                          const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.src,
                          ),
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          // ... rest of the code remains the same
        ],
      ),
    );
  }
}
