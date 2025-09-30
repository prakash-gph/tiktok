// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:tiktok/upload_videos/upload_from.dart';
// import 'package:tiktok/videofilterrecord/camera_screen.dart';
// import 'package:tiktok/videofilterrecord/video_recorder.dart';

// class UploadVideosScreen extends StatefulWidget {
//   const UploadVideosScreen({super.key});

//   @override
//   State<UploadVideosScreen> createState() => _UploadVideosScreenState();
// }

// class _UploadVideosScreenState extends State<UploadVideosScreen> {
//   getVideoFile(ImageSource sourceImg) async {
//     final videoFile = await ImagePicker().pickVideo(source: sourceImg);

//     if (videoFile != null) {
//       //video upload from

//       Get.to(
//         UploadFrom(videoFile: File(videoFile.path), videoPath: videoFile.path),
//       );
//     }
//   }

//   List<CameraDescription> cameras = [];

//   // availableCameras();
//   //CameraException;

//   displayDialogBox() {
//     return showDialog(
//       context: context,
//       builder: (context) => SimpleDialog(
//         children: [
//           SimpleDialogOption(
//             onPressed: () {
//               getVideoFile(ImageSource.gallery);
//             },
//             child: Row(
//               children: [
//                 const Icon(Icons.image),
//                 Expanded(
//                   child: const Padding(
//                     padding: EdgeInsets.all(8),
//                     child: Text(
//                       "Get video from Gallery",
//                       maxLines: 3,
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SimpleDialogOption(
//             onPressed: () {
//               // getVideoFile(ImageSource.camera);
//               // Get.to(CameraScreen());
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ReelsCreatorScreen(cameras: cameras),
//                 ),
//               );
//             },
//             child: Row(
//               children: const [
//                 Icon(Icons.camera),
//                 Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.all(8),
//                     child: Text(
//                       "Make video with Camera",
//                       maxLines: 3,
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SimpleDialogOption(
//             onPressed: () {
//               Get.back();
//             },
//             child: Row(
//               children: const [
//                 Icon(Icons.cancel),
//                 Padding(
//                   padding: EdgeInsets.all(8),
//                   child: Text("Cancel", style: TextStyle(fontSize: 14)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,

//           children: [
//             GestureDetector(
//               onTap: () {
//                 displayDialogBox();
//               },
//               child: const CircleAvatar(
//                 radius: 100,
//                 backgroundImage: AssetImage("images/uploadIcons.png"),
//                 backgroundColor: Colors.black,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok/upload_videos/upload_from.dart';
import 'package:tiktok/videofilterrecord/camera_screen.dart';
import 'package:tiktok/videofilterrecord/video_recorder.dart';

// Import your ReelsCreatorScreen
//import 'package:tiktok/reels_creator_screen.dart';

class UploadVideosScreen extends StatefulWidget {
  const UploadVideosScreen({super.key});

  @override
  State<UploadVideosScreen> createState() => _UploadVideosScreenState();
}

class _UploadVideosScreenState extends State<UploadVideosScreen> {
  List<CameraDescription> cameras = [];
  bool _isLoadingCameras = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    setState(() {
      _isLoadingCameras = true;
    });

    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Camera error: $e');
      // Show error message to user if needed
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize camera')),
      );
    } finally {
      setState(() {
        _isLoadingCameras = false;
      });
    }
  }

  getVideoFile(ImageSource sourceImg) async {
    final videoFile = await ImagePicker().pickVideo(source: sourceImg);

    if (videoFile != null) {
      // video upload from
      Get.to(
        UploadFrom(videoFile: File(videoFile.path), videoPath: videoFile.path),
      );
    }
  }

  displayDialogBox() {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () {
              getVideoFile(ImageSource.gallery);
            },
            child: Row(
              children: [
                const Icon(Icons.image),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Get video from Gallery",
                      maxLines: 3,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SimpleDialogOption(
            onPressed: () {
              if (cameras.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReelsCreatorScreen(cameras: cameras),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No cameras available')),
                );
              }
            },
            child: Row(
              children: [
                const Icon(Icons.camera),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _isLoadingCameras
                          ? "Loading cameras..."
                          : "Make video with Camera",
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SimpleDialogOption(
            onPressed: () {
              Get.back();
            },
            child: Row(
              children: const [
                Icon(Icons.cancel),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("Cancel", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: displayDialogBox,
              child: const CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage("images/uploadIcons.png"),
                backgroundColor: Colors.black,
              ),
            ),
            if (_isLoadingCameras)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
