// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class VideoPalyerItem extends StatefulWidget {
//   final String videoUrl;
//   final bool isPlaying;
//   final Function(VideoPlayerController) onControllerReady;
//   final Function(VideoPlayerController) onControllerDispose;

//   const VideoPalyerItem({
//     super.key,
//     required this.videoUrl,
//     required this.isPlaying,
//     required this.onControllerReady,
//     required this.onControllerDispose,
//   });

//   @override
//   State<VideoPalyerItem> createState() => _VideoPalyerItemState();
// }

// class _VideoPalyerItemState extends State<VideoPalyerItem> {
//   late VideoPlayerController _videoPlayerController;
//   bool _isInitialized = false;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideoPlayer();
//   }

//   @override
//   void didUpdateWidget(covariant VideoPalyerItem oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.isPlaying != widget.isPlaying) {
//       if (widget.isPlaying && _isInitialized) {
//         _videoPlayerController.play();
//       } else if (_isInitialized) {
//         _videoPlayerController.pause();
//       }
//     }
//   }

//   Future<void> _initializeVideoPlayer() async {
//     try {
//       if (widget.videoUrl.isEmpty) {
//         setState(() {
//           _hasError = true;
//         });
//         return;
//       }

//       // ignore: deprecated_member_use
//       _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

//       await _videoPlayerController.initialize();

//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });

//         if (widget.isPlaying) {
//           _videoPlayerController.play();
//         }

//         _videoPlayerController.setVolume(1);
//         _videoPlayerController.setLooping(true);
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     if (_hasError) {
//       return Container(
//         width: size.width,
//         height: size.height,
//         decoration: const BoxDecoration(color: Colors.black),
//         child: const Center(
//           child: Icon(Icons.error_outline, color: Colors.white, size: 50),
//         ),
//       );
//     }

//     if (!_isInitialized) {
//       return Container(
//         width: size.width,
//         height: size.height,
//         decoration: const BoxDecoration(color: Colors.black),
//         child: const Center(
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       );
//     }

//     return SizedBox(
//       width: size.width,
//       height: size.height,
//       child: FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: _videoPlayerController.value.size.width,
//           height: _videoPlayerController.value.size.height,
//           child: VideoPlayer(_videoPlayerController),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;
  final Function(VideoPlayerController) onControllerReady;
  final Function(VideoPlayerController) onControllerDispose;

  const VideoPlayerItem({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
    required this.onControllerReady,
    required this.onControllerDispose,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if video URL changes, reinitialize
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
      return;
    }

    // play / pause toggle
    if (oldWidget.isPlaying != widget.isPlaying && _isInitialized) {
      widget.isPlaying ? _controller?.play() : _controller?.pause();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.isEmpty) {
        setState(() => _hasError = true);
        return;
      }

      // Try getting cached file
      File? file;
      try {
        final fileInfo = await DefaultCacheManager().getFileFromCache(
          widget.videoUrl,
        );
        file = fileInfo?.file;
      } catch (_) {}

      // If not found or corrupted, download new one
      if (file == null || !await file.exists()) {
        debugPrint(" Downloading video fresh: ${widget.videoUrl}");
        file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      } else {
        debugPrint("✅ Using cached video: ${file.path}");
      }

      // Fallback: if file is still invalid, play from network directly
      _controller = (await file.exists())
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _controller!.initialize();
      _controller!
        ..setLooping(true)
        ..setVolume(1.0);

      widget.onControllerReady(_controller!);

      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isPlaying) _controller!.play();
      }
    } catch (e) {
      debugPrint("❌ Video initialization failed: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _disposeController() {
    if (_controller != null) {
      widget.onControllerDispose(_controller!);
      _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_hasError) {
      return Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 50),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
