// import 'package:flutter/material.dart';
// import 'package:easy_video_editor/easy_video_editor.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

// // void main() {
// //   runApp(MaterialApp(home: VideoAudioMergeScreen()));
// // }

// class VideoAudioMergeScreen extends StatefulWidget {
//   @override
//   _VideoAudioMergeScreenState createState() => _VideoAudioMergeScreenState();
// }

// class _VideoAudioMergeScreenState extends State<VideoAudioMergeScreen> {
//   String? _videoPath;
//   String? _audioPath;
//   String? _outputPath;
//   bool _isMerging = false;

//   // Pick video file
//   Future<void> pickVideo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.video);
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _videoPath = result.files.single.path!;
//       });
//     }
//   }

//   // Pick audio file
//   Future<void> pickAudio() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _audioPath = result.files.single.path!;
//       });
//     }
//   }

//   // Merge video and audio
//   Future<void> mergeVideoAudio() async {
//     if (_videoPath == null || _audioPath == null) return;

//     setState(() {
//       _isMerging = true;
//     });

//     final dir = await getTemporaryDirectory();
//     final outputPath = '${dir.path}/merged_output.mp4';

//     final editor = VideoEditorBuilder(
//       videoPath: _videoPath!,
//     ).merge(otherVideoPaths: [_audioPath!]);

//     await editor.export(outputPath: outputPath);

//     setState(() {
//       _outputPath = outputPath;
//       _isMerging = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Merge Video and Audio")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ElevatedButton(onPressed: pickVideo, child: Text("Pick Video")),
//             ElevatedButton(onPressed: pickAudio, child: Text("Pick Audio")),
//             ElevatedButton(
//               onPressed: _isMerging ? null : mergeVideoAudio,
//               child: Text(_isMerging ? "Merging..." : "Merge Video + Audio"),
//             ),
//             if (_outputPath != null) Text("Output saved at: $_outputPath"),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoAudioMergeScreen extends StatefulWidget {
  @override
  _VideoAudioMergeScreenState createState() => _VideoAudioMergeScreenState();
}

class _VideoAudioMergeScreenState extends State<VideoAudioMergeScreen> {
  String? _videoPath;
  String? _audioPath;
  String? _outputPath;
  bool _isMerging = false;

  // Video player controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;

  // Pick video file
  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoPath = result.files.single.path!;
      });
      _disposeVideoPlayer(); // Dispose previous player when new video is selected
    }
  }

  // Pick audio file
  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPath = result.files.single.path!;
      });
    }
  }

  // Merge video and audio
  Future<void> mergeVideoAudio() async {
    if (_videoPath == null || _audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both video and audio files')),
      );
      return;
    }

    setState(() {
      _isMerging = true;
    });

    try {
      final dir = await getTemporaryDirectory();
      final outputPath =
          '${dir.path}/merged_output_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final editor = VideoEditorBuilder(
        videoPath: _videoPath!,
      ).merge(otherVideoPaths: [_audioPath!]);

      await editor.export(outputPath: outputPath);

      setState(() {
        _outputPath = outputPath;
        _isMerging = false;
      });

      // Auto-play the merged video
      _playOutputVideo(outputPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video merged successfully!')));
    } catch (e) {
      setState(() {
        _isMerging = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error merging video: $e')));
    }
  }

  // Play the output video
  Future<void> _playOutputVideo(String videoPath) async {
    _disposeVideoPlayer(); // Dispose any existing player

    setState(() {
      _isPlaying = true;
    });

    try {
      _videoController = VideoPlayerController.file(File(videoPath));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing video: $e')));
    }
  }

  // Dispose video controllers
  void _disposeVideoPlayer() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
    _isPlaying = false;
  }

  // Stop video playback
  void _stopVideo() {
    _videoController?.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Merge Video and Audio"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Selection Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: pickVideo,
                            icon: Icon(Icons.video_library),
                            label: Text("Pick Video"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: pickAudio,
                            icon: Icon(Icons.audio_file),
                            label: Text("Pick Audio"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_videoPath != null)
                      Text(
                        "Video: ${_videoPath!.split('/').last}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    if (_audioPath != null)
                      Text(
                        "Audio: ${_audioPath!.split('/').last}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Merge Button
            ElevatedButton(
              onPressed: _isMerging ? null : mergeVideoAudio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[400],
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isMerging
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 10),
                        Text("Merging...", style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : Text("Merge Video + Audio", style: TextStyle(fontSize: 16)),
            ),

            SizedBox(height: 20),

            // Output Path Display
            if (_outputPath != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Output saved at:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _outputPath!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Video Player Section
            if (_chewieController != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              "Merged Video Preview",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: _stopVideo,
                              icon: Icon(Icons.stop, color: Colors.red),
                              tooltip: "Stop Video",
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: Chewie(controller: _chewieController!)),
                    ],
                  ),
                ),
              )
            else if (_isPlaying)
              Card(
                child: Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Loading video..."),
                      ],
                    ),
                  ),
                ),
              ),

            // Empty space when no video is playing
            if (_chewieController == null && !_isPlaying)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Merged video will appear here",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Don't forget to add these dependencies to your pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  easy_video_editor: ^1.0.0  # Check for latest version
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  video_player: ^2.8.2
  chewie: ^1.7.2
*/
