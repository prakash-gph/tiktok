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
  bool _showDescriptionField = true;
  int _descriptionLength = 0;
  final int _maxDescriptionLength = 200;
  bool _isExpanded = false;
  bool _showDuration = true;
  Size? _videoSize;
  double? _aspectRatio;

  Timer? _descriptionDebounceTimer;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
    _descriptionController.addListener(_onDescriptionChanged);

    _durationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showDuration = false);
      }
    });
  }

  void _onDescriptionChanged() {
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

      // Get video dimensions for proper layout
      if (_controller.value.isInitialized) {
        _videoSize = _controller.value.size;
        _aspectRatio = _controller.value.aspectRatio;
        if (_aspectRatio == null ||
            _aspectRatio!.isNaN ||
            _aspectRatio!.isInfinite) {
          _aspectRatio = 9 / 16; // Fallback to 9:16 for vertical videos
        }
      }

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
    _durationTimer?.cancel();
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

  void _toggleDescriptionExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showVideoInfo() {
    final duration = _controller.value.duration;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final infoTextColor = isDark ? Colors.grey[300] : Colors.grey[800];

        return Container(
          padding: const EdgeInsets.all(24),
          color: isDark ? const Color(0xFF0B0B0B) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Video Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Duration',
                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                textColor: infoTextColor,
              ),
              if (_videoSize != null)
                _buildInfoRow(
                  'Resolution',
                  '${_videoSize!.width.toInt()}x${_videoSize!.height.toInt()}',
                  textColor: infoTextColor,
                ),
              if (_aspectRatio != null)
                _buildInfoRow(
                  'Aspect Ratio',
                  _aspectRatio!.toStringAsFixed(2),
                  textColor: infoTextColor,
                ),
              if (_audioSelection != null) ...[
                // _buildInfoRow(
                //   'Selected Audio',
                //   _audioSelection?.songName ?? "",
                //   textColor: infoTextColor,
                // ),
                _buildInfoRow(
                  'Audio Duration',
                  '${_audioSelection!.duration.toStringAsFixed(1)}s',
                  textColor: infoTextColor,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // backgroundColor: theme.colorScheme.surface,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _onMergePressed() async {
    if (_audioSelection == null) {
      _showErrorSnackBar('Please select audio first');
      return;
    }

    if (_processing || _uploading) return;

    setState(() => _processing = true);

    try {
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

    final shouldProceed = await _showUploadConfirmation();
    if (!shouldProceed) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final userId = await _getCurrentUserId();
      final songName = _audioSelection?.songName ?? "";

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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF121212) : null,
              title: const Text('Upload Without Description?'),
              content: const Text(
                'You haven\'t added a description. Would you like to add one before uploading?',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Add Description'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text(
                    'Upload Anyway',
                    style: TextStyle(color: Colors.white),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isDark ? Colors.red.shade400 : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isDark ? Colors.green.shade600 : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showProcessingSnackBar(String phase) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(phase),
          ],
        ),
        backgroundColor: isDark ? Colors.blueGrey.shade700 : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller.value.isInitialized;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Colors based on brightness
    final surfaceColor = isDark ? const Color(0xFF121212) : colorScheme.surface;
    final cardShadowColor = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.12);
    final hintTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final mutedTextColor = isDark ? Colors.grey[300] : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Preview & Upload',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: _processing || _uploading
              ? null
              : () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: _showVideoInfo,
            tooltip: 'Video Details',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF0B0B0B) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with video and description
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 100),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Video Preview - Left Side
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: cardShadowColor,
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  color: Colors.black,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    alignment: Alignment.center,
                                    children: [
                                      if (!isInitialized)
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      if (isInitialized && _aspectRatio != null)
                                        _buildVideoPlayer(),
                                      if (isInitialized)
                                        _buildVideoOverlay(isDark: isDark),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Description Box - Right Side
                          Expanded(
                            flex: 3,
                            child: _buildDescriptionBox(
                              theme,
                              colorScheme,
                              surfaceColor,
                              hintTextColor,
                              mutedTextColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Audio Trimmer Section
                  _buildAudioTrimmerSection(
                    theme,
                    colorScheme,
                    surfaceColor,
                    mutedTextColor,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtonsSection(theme, colorScheme, isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Upload Success Overlay
          if (_uploadedUrl != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cardShadowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade400,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload Successful!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your video has been uploaded successfully.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedTextColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _navigateAfterUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _aspectRatio ?? 9 / 16,
      child: VideoPlayer(_controller),
    );
  }

  Widget _buildVideoOverlay({required bool isDark}) {
    return Positioned.fill(
      child: Column(
        children: [
          // Top overlay
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(isDark ? 0.8 : 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showDuration = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        if (_showDuration)
                          Text(
                            '${_controller.value.duration.inMinutes}:${(_controller.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center play button
          Expanded(
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: _togglePlayPause,
                    backgroundColor: Colors.black54,
                    elevation: 4,
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom overlay
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(isDark ? 0.8 : 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(
    ThemeData theme,
    ColorScheme colorScheme,
    Color surfaceColor,
    Color? hintTextColor,
    Color? mutedTextColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.transparent),
      ),
      child: Column(
        children: [
          // Description Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(isDark ? 0.06 : 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                // IconButton(
                //   icon: Icon(
                //     _isExpanded ? Icons.expand_less : Icons.expand_more,
                //     size: 20,
                //     color: isDark ? Colors.white70 : Colors.black54,
                //   ),
                //   onPressed: _toggleDescriptionExpansion,
                //   tooltip: _isExpanded ? 'Collapse' : 'Expand',
                // ),
              ],
            ),
          ),

          // Description Field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      maxLines: _isExpanded ? null : 4,
                      maxLength: _maxDescriptionLength,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Add a description...\n\nUse hashtags: #funny #dance #trending',
                        hintStyle: TextStyle(
                          color: hintTextColor,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_descriptionController.text.length}/$_maxDescriptionLength',
                        style: TextStyle(
                          color:
                              _descriptionController.text.length >
                                  _maxDescriptionLength
                              ? Colors.red
                              : _descriptionController.text.length >
                                    _maxDescriptionLength * 0.8
                              ? Colors.orange
                              : mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      if (_audioSelection != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            _audioSelection!.songName ?? "",

                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTrimmerSection(
    ThemeData theme,
    ColorScheme colorScheme,
    Color surfaceColor,
    Color? mutedTextColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio Selection',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // Text(
          //   'Trim and adjust audio for your video',
          //   style: TextStyle(color: mutedTextColor, fontSize: 12),
          // ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: AudioTrimmerWidget(
              onChanged: (sel) => setState(() => _audioSelection = sel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      children: [
        // Progress Indicators
        if (_processing || _uploading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                if (_processing)
                  _buildProgressIndicator('Processing audio...', null),
                if (_uploading)
                  _buildProgressIndicator('Posting video...', _uploadProgress),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processing || _uploading ? null : _onMergePressed,
                icon: _processing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.merge_type_rounded),
                label: Text(
                  _processing ? 'Processing...' : 'Merge Audio',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processing || _uploading ? null : _onUploadPressed,
                icon: _uploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _uploading ? 'Posting...' : 'Post Video',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(String label, double? progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (progress != null)
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
