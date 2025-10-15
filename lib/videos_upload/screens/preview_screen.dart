// ignore_for_file: dead_code

import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/videos_upload/model/audio_selection.dart';
import 'package:tiktok/videos_upload/service/ffmpeg_service.dart';
import 'package:tiktok/videos_upload/service/firebase_service.dart';
import 'package:video_player/video_player.dart';
import '../widgets/audio_trimmer.dart';

class PreviewScreen extends StatefulWidget {
  final File videoFile;
  const PreviewScreen({super.key, required this.videoFile});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late VideoPlayerController _controller;
  AudioSelection? _audioSelection;
  bool _processing = false;
  bool _uploading = false;
  String? _uploadedUrl;
  double _uploadProgress = 0.0;
  bool _isPlaying = true;
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  bool _showDescriptionField = false;
  int _descriptionLength = 0;
  final int _maxDescriptionLength = 2200;

  // Performance optimization: Debounce timer for description updates
  Timer? _descriptionDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    // Debounce to avoid frequent rebuilds
    _descriptionDebounceTimer?.cancel();
    _descriptionDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _descriptionLength = _descriptionController.text.length;
        });
      }
    });
  }

  Future<void> _initializeVideoController() async {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..addListener(_videoListener);

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      await _controller.play();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load video: ${e.toString()}');
      }
    }
  }

  void _videoListener() {
    if (mounted && _isPlaying != _controller.value.isPlaying) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _descriptionDebounceTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _isPlaying = !_controller.value.isPlaying;
    });

    try {
      if (_controller.value.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to control video playback');
      }
    }
  }

  void _toggleDescriptionField() {
    setState(() {
      _showDescriptionField = !_showDescriptionField;
    });

    if (_showDescriptionField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _descriptionFocusNode.requestFocus();
      });
    }
  }

  Future<void> _onMergePressed() async {
    if (_audioSelection == null) {
      _showErrorSnackBar('Please select audio first');
      return;
    }

    if (_processing || _uploading) return;

    setState(() => _processing = true);

    try {
      // Validate audio file exists
      final audioFile = File(_audioSelection!.path);
      if (!await audioFile.exists()) {
        _showErrorSnackBar('Selected audio file not found');
        return;
      }

      final trimmedAudio = await FFmpegService.trimAudio(
        _audioSelection!.path,
        _audioSelection!.start,
        _audioSelection!.duration,
      );

      if (trimmedAudio == null) {
        _showErrorSnackBar('Audio trimming failed');
        return;
      }

      final merged = await FFmpegService.mergeVideoWithAudio(
        widget.videoFile.path,
        trimmedAudio,
      );

      if (merged != null && await File(merged).exists()) {
        final mergedFile = File(merged);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => PreviewScreen(videoFile: mergedFile),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
        _showSuccessSnackBar('Video merged successfully!');
      } else {
        _showErrorSnackBar('Merging failed - output file not created');
      }
    } catch (e) {
      _showErrorSnackBar('Error during merging: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _onUploadPressed() async {
    if (_processing || _uploading) return;

    final file = widget.videoFile;

    // Validate file exists and is readable
    try {
      if (!await file.exists()) {
        _showErrorSnackBar('Video file not found');
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Cannot access video file');
      return;
    }

    final size = await file.length();
    const maxSize = 200 * 1024 * 1024;

    if (size > maxSize) {
      _showErrorSnackBar('File too large (max 200MB)');
      return;
    }

    if (!_controller.value.isInitialized) {
      _showErrorSnackBar('Video not ready');
      return;
    }

    // Upload confirmation dialog
    final shouldProceed = await _showUploadConfirmation();
    if (!shouldProceed) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final userId = await _getCurrentUserId();
      final songName = _audioSelection?.songName ?? "Original sound";

      debugPrint('🎵 Uploading with song name: $songName');

      final result = await FirebaseService.uploadVideoFile(
        file,
        userId: userId,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        songName: songName,
        onProgress: (pct) {
          if (mounted) setState(() => _uploadProgress = pct);
        },
        onPhaseChange: (phase) {
          if (mounted) _showProcessingSnackBar(phase);
        },
      );

      if (mounted) {
        setState(() {
          _uploading = false;
          if (result['success'] == true) {
            _uploadedUrl = result['video'].videoUrl;
            _navigateAfterUpload();
          }
        });
      }

      if (result['success'] == true) {
        _showSuccessSnackBar('Upload completed successfully!');
      } else {
        _showErrorSnackBar('Upload failed. Please try again.');
      }
    } catch (e) {
      debugPrint('⚠️ Upload error: $e');
      _showErrorSnackBar('Unexpected error during upload: ${e.toString()}');
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  Future<bool> _showUploadConfirmation() async {
    if (_descriptionController.text.trim().isEmpty) {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Upload Without Description?'),
              content: const Text(
                'You haven\'t added a description. Would you like to add one before uploading?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Add Description'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Upload Anyway'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  void _navigateAfterUpload() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProcessingSnackBar(String phase) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(phase),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller.value.isInitialized;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Preview Video',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _processing || _uploading
              ? null
              : () => Navigator.pop(context),
        ),
        actions: [
          if (!_uploading)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showVideoInfo(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Video Preview Section
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isInitialized)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    if (isInitialized)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    if (isInitialized)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black38,
                            child: Center(
                              child: FloatingActionButton(
                                onPressed: _togglePlayPause,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Description Input Section
          if (_showDescriptionField) _buildDescriptionField(theme, colorScheme),

          // Audio Trimmer Section
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Audio Selection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showDescriptionField
                              ? Icons.description
                              : Icons.description_outlined,
                          color: _showDescriptionField
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        onPressed: _toggleDescriptionField,
                        tooltip: 'Add Description',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AudioTrimmerWidget(
                      onChanged: (sel) => setState(() => _audioSelection = sel),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress Indicators
          if (_processing || _uploading) _buildProgressIndicators(),

          // Action Buttons
          _buildActionButtons(colorScheme),

          // Uploaded URL
          if (_uploadedUrl != null) _buildUploadSuccessWidget(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Video Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleDescriptionField,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            maxLines: 4,
            maxLength: _maxDescriptionLength,
            decoration: InputDecoration(
              hintText: 'Describe your video...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$_descriptionLength/$_maxDescriptionLength',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _descriptionLength > _maxDescriptionLength * 0.8
                      ? Colors.orange
                      : _descriptionLength > _maxDescriptionLength
                      ? Colors.red
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return const SizedBox(height: 16);
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (_processing) _buildProgressIndicator('Processing video...', null),
          if (_uploading)
            _buildProgressIndicator('Uploading video...', _uploadProgress),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Merge Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.merge_type_rounded,
              label: 'Merge Audio',
              onPressed: _processing || _uploading ? null : _onMergePressed,
              backgroundColor: colorScheme.primary,
              isLoading: _processing,
            ),
          ),
          const SizedBox(width: 12),
          // Upload Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _processing || _uploading ? null : _onUploadPressed,
              icon: _uploading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded, color: Colors.black),
              label: Text(
                _uploading
                    ? 'Uploading...'
                    : _descriptionController.text.isNotEmpty
                    ? 'Upload with Description'
                    : 'Upload',
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSuccessWidget() {
    return const SizedBox(height: 8);

    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Upload Successful!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_uploadedUrl != null)
              GestureDetector(
                onTap: () => _showUrlDialog(_uploadedUrl!),
                child: Text(
                  _uploadedUrl!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double? progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Stack(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            if (progress != null)
              Positioned(
                right: 0,
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required bool isLoading,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
      label: isLoading
          ? const Text('Processing...')
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uploaded Video URL'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Clipboard.setData(ClipboardData(text: url));
              _showSuccessSnackBar('URL copied to clipboard!');
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showVideoInfo() {
    final duration = _controller.value.duration;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
            Text(
              'Resolution: ${_controller.value.size.width.toInt()}x${_controller.value.size.height.toInt()}',
            ),
            Text(
              'Aspect Ratio: ${_controller.value.aspectRatio.toStringAsFixed(2)}',
            ),
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Description:'),
              Text(_descriptionController.text),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
