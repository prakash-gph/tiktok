// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:tiktok/videofilterrecord/audio_pic_screen.dart';
// import 'package:tiktok/videofilterrecord/audio_tracker.dart';
// import 'package:tiktok/videofilterrecord/media_service.dart';
// import 'package:video_player/video_player.dart';

// class EditorScreen extends StatefulWidget {
//   final File videoFile;
//   const EditorScreen({required this.videoFile, super.key});

//   @override
//   State<EditorScreen> createState() => _EditorScreenState();
// }

// class _EditorScreenState extends State<EditorScreen> {
//   VideoPlayerController? _videoController;
//   AudioTrack? _selectedTrack;
//   bool _processing = false;
//   String? _outputPath;

//   @override
//   void initState() {
//     super.initState();
//     _videoController = VideoPlayerController.file(widget.videoFile)
//       ..initialize().then((_) => setState(() {}))
//       ..setLooping(true)
//       ..play();
//   }

//   @override
//   void dispose() {
//     _videoController?.dispose();
//     super.dispose();
//   }

//   Future<void> _openPicker() async {
//     final track = await Navigator.of(context).push<AudioTrack>(
//       MaterialPageRoute(
//         builder: (_) => AudioPickerScreen(onSelected: (AudioTrack) {}),
//       ),
//     );
//     if (track != null) {
//       setState(() => _selectedTrack = track);
//     }
//   }

//   Future<void> _merge() async {
//     if (_selectedTrack == null) return;
//     setState(() => _processing = true);
//     final out = await MediaService.mergeVideoAudio(
//       widget.videoFile.path,
//       _selectedTrack!.url,
//       videoPath: widget.videoFile.path,
//       audioPath: _selectedTrack!.url,
//       outputPath: _outputPath!,
//     );
//     setState(() {
//       _processing = false;
//       _outputPath = out;
//     });
//     if (out != null) {
//       // ignore: use_build_context_synchronously
//       Navigator.of(
//         context,
//       ).push(MaterialPageRoute(builder: (_) => ResultScreen(File(out))));
//     } else {
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Merge failed')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Editor')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Video Preview
//             if (_videoController != null &&
//                 _videoController!.value.isInitialized)
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: AspectRatio(
//                   aspectRatio: _videoController!.value.aspectRatio,
//                   child: VideoPlayer(_videoController!),
//                 ),
//               )
//             else
//               Container(
//                 height: 300,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Center(child: CircularProgressIndicator()),
//               ),

//             const SizedBox(height: 20),

//             // Audio Selection Card
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Selected Audio',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _selectedTrack?.title ?? 'No audio selected',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: _selectedTrack != null
//                             ? Colors.black
//                             : Colors.grey,
//                       ),
//                     ),
//                     if (_selectedTrack?.url != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Text(
//                           _selectedTrack!.url,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _openPicker,
//                         icon: const Icon(Icons.audiotrack),
//                         label: const Text('Choose Audio'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Merge Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _processing || _selectedTrack == null
//                     ? null
//                     : _merge,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: _selectedTrack != null
//                       ? Colors.blue
//                       : Colors.grey,
//                 ),
//                 child: _processing
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation(Colors.white),
//                         ),
//                       )
//                     : const Text(
//                         'Merge & Save Video',
//                         style: TextStyle(fontSize: 16),
//                       ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Output Path
//             if (_outputPath != null)
//               Card(
//                 color: Colors.green[50],
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.check_circle, color: Colors.green),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Video Saved Successfully!',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             Text(
//                               _outputPath!,
//                               style: const TextStyle(fontSize: 12),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ResultScreen extends StatefulWidget {
//   final File file;
//   const ResultScreen(this.file, {super.key});

//   @override
//   State<ResultScreen> createState() => _ResultScreenState();
// }

// class _ResultScreenState extends State<ResultScreen> {
//   VideoPlayerController? _controller;
//   bool _isPlaying = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(widget.file)
//       ..initialize().then((_) => setState(() {}))
//       ..play();
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   void _togglePlayPause() {
//     setState(() {
//       if (_controller!.value.isPlaying) {
//         _controller!.pause();
//         _isPlaying = false;
//       } else {
//         _controller!.play();
//         _isPlaying = true;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Final Result'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share),
//             onPressed: () {
//               // Add share functionality here
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: _controller != null && _controller!.value.isInitialized
//                   ? AspectRatio(
//                       aspectRatio: _controller!.value.aspectRatio,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           VideoPlayer(_controller!),
//                           Positioned(
//                             bottom: 20,
//                             child: FloatingActionButton(
//                               onPressed: _togglePlayPause,
//                               child: Icon(
//                                 _isPlaying ? Icons.pause : Icons.play_arrow,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : const CircularProgressIndicator(),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).popUntil((route) => route.isFirst);
//                 },
//                 child: const Text('Create Another Video'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
