import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPalyerItem extends StatefulWidget {
  final String videoUrl;
  // ignore: use_super_parameters
  const VideoPalyerItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPalyerItem> createState() => _VideoPalyerItemState();
}

class _VideoPalyerItemState extends State<VideoPalyerItem> {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Check if videoUrl is not null or empty
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
        });
        return;
      }

      // ignore: deprecated_member_use
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

      await _videoPlayerController.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoPlayerController.play();
        _videoPlayerController.setVolume(1);
        _videoPlayerController.setLooping(true);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_hasError) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(color: Colors.black),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 50),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(color: Colors.black),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(color: Colors.black),
      child: VideoPlayer(_videoPlayerController),
    );
  }
}
