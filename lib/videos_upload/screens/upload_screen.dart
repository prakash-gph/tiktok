import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktok/videos_upload/service/firebase_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _pickedVideo;
  VideoPlayerController? _controller;
  bool _isUploading = false;
  double _progress = 0;

  final TextEditingController _descriptionController = TextEditingController();
  static const int _maxDescriptionLength = 200;

  // ------------------ PICK VIDEO ------------------
  Future<void> _pickVideo() async {
    if (_isUploading) return;

    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.video);
      if (res == null || res.files.isEmpty) return;

      final file = File(res.files.first.path!);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      if (controller.value.duration.inSeconds > 30) {
        _showSnack('❌ Video too long! Please select under 30 seconds.');
        await controller.dispose();
        return;
      }

      setState(() {
        _pickedVideo = file;
        _controller?.dispose();
        _controller = controller;
        controller.setLooping(true);
        controller.play();
      });
    } catch (e) {
      _showSnack('⚠️ Error picking video: $e');
    }
  }

  // ------------------ UPLOAD VIDEO ------------------
  Future<void> _uploadVideo() async {
    if (_pickedVideo == null) {
      _showSnack('Please select a video.');
      return;
    }

    final desc = _descriptionController.text.trim();

    if (desc.length > _maxDescriptionLength) {
      _showSnack('⚠️ Maximum $_maxDescriptionLength characters.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await FirebaseService.uploadVideoFile(
        _pickedVideo!,
        userId: FirebaseAuth.instance.currentUser!.uid,
        description: desc,
        onProgress: (p) => setState(() => _progress = p),
      );

      setState(() => _isUploading = false);

      if (result['success'] == true) {
        _showSnack('Uploaded Successfully!');
        _resetUI();
      } else {
        _showSnack('❌ Upload failed: ${result['error']}');
      }
    } catch (e) {
      _showSnack('⚠️ Upload error: $e');
      setState(() => _isUploading = false);
    }
  }

  void _resetUI() {
    setState(() {
      _pickedVideo = null;
      _controller?.dispose();
      _controller = null;
      _progress = 0;
      _descriptionController.clear();
    });
  }

  void _showSnack(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? Colors.grey[850] : Colors.black87,
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white : Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Responsive helpers
  double w(BuildContext context, double value) =>
      MediaQuery.of(context).size.width * (value / 390);
  double h(BuildContext context, double value) =>
      MediaQuery.of(context).size.height * (value / 844);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? Colors.black : Colors.white;
    final box = isDark ? Colors.grey[900] : Colors.grey[200];
    final border = isDark ? Colors.white12 : Colors.black12;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text("Post", style: TextStyle(color: textColor)),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w(context, 14),
            vertical: h(context, 12),
          ),

          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------ VIDEO PREVIEW ------------------
                  GestureDetector(
                    onTap: _isUploading ? null : _pickVideo,
                    child: Container(
                      width: w(context, 130),
                      height: h(context, 210),
                      decoration: BoxDecoration(
                        color: box,
                        borderRadius: BorderRadius.circular(w(context, 12)),
                        border: Border.all(color: border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(w(context, 12)),
                        child: _pickedVideo == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    size: w(context, 42),
                                    color: textColor,
                                  ),
                                  SizedBox(height: h(context, 8)),
                                  Text(
                                    "Select Cover",
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              )
                            : VideoPlayer(_controller!),
                      ),
                    ),
                  ),

                  SizedBox(width: w(context, 12)),

                  // ------------------ CAPTION BOX ------------------
                  Expanded(
                    child: Container(
                      height: h(context, 210),
                      padding: EdgeInsets.all(w(context, 12)),
                      decoration: BoxDecoration(
                        color: box,
                        borderRadius: BorderRadius.circular(w(context, 12)),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _descriptionController,
                              maxLength: _maxDescriptionLength,
                              maxLines: null,
                              expands: true,
                              style: TextStyle(
                                fontSize: w(context, 15),
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    "Write @ to tag friends and # for hashtags",
                                hintStyle: TextStyle(
                                  color: hintColor,
                                  fontSize: w(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ------------------ UPLOADING PROGRESS ------------------
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress / 100,
                      minHeight: h(context, 6),
                      backgroundColor: border,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: h(context, 6)),
                    Text(
                      "${_progress.toStringAsFixed(1)}%",
                      style: TextStyle(color: hintColor),
                    ),
                    SizedBox(height: h(context, 8)),
                  ],
                ),

              // ------------------ BOTTOM BUTTONS ------------------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: hintColor),
                        padding: EdgeInsets.symmetric(vertical: h(context, 14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w(context, 10)),
                        ),
                      ),
                      onPressed: () => _showSnack("Saved to drafts."),
                      child: Text("Drafts", style: TextStyle(color: textColor)),
                    ),
                  ),
                  SizedBox(width: w(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: h(context, 14)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w(context, 10)),
                        ),
                      ),
                      child: Text(
                        _isUploading ? "Uploading..." : "Post",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
