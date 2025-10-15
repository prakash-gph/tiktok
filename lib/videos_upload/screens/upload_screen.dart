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

  Future<void> _pickVideo() async {
    if (_isUploading) return;

    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.video);
      if (res == null || res.files.isEmpty) return;

      final file = File(res.files.first.path!);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final duration = controller.value.duration;

      if (duration.inSeconds > 30) {
        _showSnack(
          '❌ Video too long! Please select a video shorter than 30 seconds.',
        );
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

  Future<void> _uploadVideo() async {
    if (_pickedVideo == null) {
      _showSnack('Please select a video first.');
      return;
    }

    final desc = _descriptionController.text.trim();

    if (desc.length > _maxDescriptionLength) {
      _showSnack(
        '⚠️ Description cannot exceed $_maxDescriptionLength characters.',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await FirebaseService.uploadVideoFile(
        _pickedVideo!,
        userId: FirebaseAuth.instance.currentUser!.uid,
        description: desc.isEmpty ? "" : desc,
        onProgress: (p) => setState(() => _progress = p),
        onPhaseChange: (phase) => debugPrint("Upload Phase: $phase"),
      );

      setState(() => _isUploading = false);

      if (result['success'] == true) {
        _showSnack('✅ Video uploaded successfully!');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideoReady = _controller?.value.isInitialized ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                child: _pickedVideo == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.video_library, size: 50),
                            SizedBox(height: 8),
                            Text('Tap to select a video (max 30 sec)'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            ),
                            if (!isVideoReady)
                              const Center(child: CircularProgressIndicator()),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _isUploading ? null : _pickVideo,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 Caption
            TextField(
              controller: _descriptionController,
              maxLength: _maxDescriptionLength,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Add a caption (max 200 chars)',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_descriptionController.text.length}/$_maxDescriptionLength',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress / 100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 8),
                  Text('${_progress.toStringAsFixed(1)}%'),
                ],
              ),
            const SizedBox(height: 20),

            // ☁️ Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadVideo,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
