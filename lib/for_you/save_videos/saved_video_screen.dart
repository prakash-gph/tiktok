// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/for_you/save_videos/saved_video_controller.dart';
// import 'package:tiktok/for_you/save_videos/saved_video_tile.dart';

// class SavedVideoScreen extends StatelessWidget {
//   const SavedVideoScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final SavedVideoController controller = Get.put(SavedVideoController());

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text(
//           'Saved Videos',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder(
//         stream: controller.getSavedVideosStream(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.white),
//             );
//           }

//           final videos = snapshot.data!;
//           if (videos.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No saved videos yet',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             );
//           }

//           return GridView.builder(
//             padding: const EdgeInsets.all(8),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.75,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: videos.length,
//             itemBuilder: (context, index) {
//               final video = videos[index];
//               return SavedVideoTile(video: video);
//             },
//           );
//         },
//       ),
//     );
//   }
// }
