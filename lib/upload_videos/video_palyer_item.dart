import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPalyerItem extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;
  final Function(VideoPlayerController) onControllerReady;
  final Function(VideoPlayerController) onControllerDispose;

  const VideoPalyerItem({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
    required this.onControllerReady,
    required this.onControllerDispose,
  });

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

  @override
  void didUpdateWidget(covariant VideoPalyerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying && _isInitialized) {
        _videoPlayerController.play();
      } else if (_isInitialized) {
        _videoPlayerController.pause();
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
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

        if (widget.isPlaying) {
          _videoPlayerController.play();
        }

        _videoPlayerController.setVolume(1);
        _videoPlayerController.setLooping(true);
      }
    } catch (e) {
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

    return SizedBox(
      width: size.width,
      height: size.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoPlayerController.value.size.width,
          height: _videoPlayerController.value.size.height,
          child: VideoPlayer(_videoPlayerController),
        ),
      ),
    );
  }
}
