// // import 'dart:io';

// // import 'package:flutter/material.dart';
// // import 'package:video_trimmer/video_trimmer.dart';

// // class VideoTrimmerScreen extends StatefulWidget {
// //   final String videoPath;
// //   const VideoTrimmerScreen({super.key, required this.videoPath});

// //   @override
// //   State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
// // }

// // class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
// //   final Trimmer _trimmer = Trimmer();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _trimmer.loadVideo(videoFile: File(widget.videoPath));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Trim Video")),
// //       body: Column(
// //         children: [
// //           Expanded(child: VideoViewer(trimmer: _trimmer)),
// //           TrimEditor(
// //             trimmer: _trimmer,
// //             viewerHeight: 50.0,
// //             viewerWidth: MediaQuery.of(context).size.width,
// //             maxVideoLength: const Duration(seconds: 30),
// //             onChangeStart: (start) {},
// //             onChangeEnd: (end) {},
// //           ),
// //           ElevatedButton(
// //             onPressed: () async {
// //               await _trimmer.saveTrimmedVideo(startValue: 0, endValue: 30).then((path) {

// //                 Navigator.pop(context, path);
// //               });
// //             },
// //             child: const Text("Save Trimmed Video"),
// //           )
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:video_trimmer/video_trimmer.dart';

// class VideoTrimmerScreen extends StatefulWidget {
//   final String videoPath;
//   const VideoTrimmerScreen({super.key, required this.videoPath});

//   @override
//   State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
// }

// class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
//   final Trimmer _trimmer = Trimmer();
//   double _startValue = 0.0;
//   double _endValue = 0.0;
//   bool _isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadVideo();
//   }

//   Future<void> _loadVideo() async {
//     await _trimmer.loadVideo(videoFile: File(widget.videoPath));
//     setState(() {});
//   }

//   Future<void> _saveTrimmedVideo() async {
//     setState(() => _isSaving = true);

//     await _trimmer
//         .saveTrimmedVideo(
//       startValue: _startValue,
//       endValue: _endValue,
//       applyVideoEncoding: true,
//     )
//         .then((outputPath) {
//       setState(() => _isSaving = false);

//       if (outputPath != null) {
//         Navigator.pop(context, outputPath);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to trim video")),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Trim Video")),
//       body: Column(
//         children: [
//           Expanded(child: VideoViewer(trimmer: _trimmer)),
//           TrimEditor(
//             trimmer: _trimmer,
//             viewerHeight: 50.0,
//             viewerWidth: MediaQuery.of(context).size.width,
//             maxVideoLength: const Duration(seconds: 30),
//             onChangeStart: (start) => _startValue = start,
//             onChangeEnd: (end) => _endValue = end,
//             onChangePlaybackState: (playing) {},
//           ),
//           const SizedBox(height: 20),
//           _isSaving
//               ? const CircularProgressIndicator()
//               : ElevatedButton(
//                   onPressed: _saveTrimmedVideo,
//                   child: const Text("Save Trimmed Video"),
//                 ),
//         ],
//       ),
//     );
//   }
// }
