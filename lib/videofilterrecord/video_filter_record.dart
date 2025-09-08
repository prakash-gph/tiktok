import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:gallery_saver/gallery_saver.dart';
import 'package:video_player/video_player.dart';

class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({Key? key}) : super(key: key);

  @override
  _VideoRecorderScreenState createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isCameraInitialized = false;
  String? _videoPath;
  double _zoomLevel = 1.0;
  FlashMode _flashMode = FlashMode.off;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  FilterType _selectedFilter = FilterType.none;

  // Filter shaders
  final Map<FilterType, ui.FragmentShader> _shaders = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadShaders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initCamera();
      }
    }
  }

  Future<void> _loadShaders() async {
    // Load shaders for filters
    final program = await ui.FragmentProgram.fromAsset('shaders/filters.frag');

    _shaders[FilterType.sepia] = program.fragmentShader()
      ..setFloat(0, 1.0); // Intensity
    _shaders[FilterType.grayscale] = program.fragmentShader()..setFloat(0, 1.0);
    _shaders[FilterType.invert] = program.fragmentShader()..setFloat(0, 1.0);
    _shaders[FilterType.pixelate] = program.fragmentShader()
      ..setFloat(0, 10.0); // Pixel size
  }

  Future<void> _initCamera() async {
    // Request camera permissions
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return;
    }

    // Request microphone permissions
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return;
      }

      // Initialize the camera controller
      _controller = CameraController(
        _cameras!.firstWhere(
          (camera) => camera.lensDirection == _lensDirection,
          orElse: () => _cameras!.first,
        ),
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error initializing camera: $e");
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording) {
      return;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = join(
        appDir.path,
        '${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _videoPath = videoPath;
        _recordingDuration = Duration.zero;
      });

      _startRecordingTimer();
    } catch (e) {
      // ignore: avoid_print
      print("Error starting recording: $e");
    }
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      _recordingTimer?.cancel();
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      // Save to gallery
      // await GallerySaver.saveVideo(videoFile.path);

      // Show preview dialog
      _showVideoPreview(videoFile.path);
    } catch (e) {
      // ignore: avoid_print
      print("Error stopping recording: $e");
    }
  }

  void _showVideoPreview(String videoPath) {
    // showDialog(
    //  context: Context,
    //   builder: (context) => VideoPreviewDialog(videoPath: videoPath),
    // );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newFlashMode;
      switch (_flashMode) {
        case FlashMode.off:
          newFlashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newFlashMode = FlashMode.always;
          break;
        case FlashMode.always:
          newFlashMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          newFlashMode = FlashMode.off;
          break;
      }

      await _controller!.setFlashMode(newFlashMode);
      setState(() {
        _flashMode = newFlashMode;
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error toggling flash: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _cameras == null) {
      return;
    }

    try {
      _lensDirection = _lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == _lensDirection,
      );

      await _controller!.dispose();
      setState(() {
        _isCameraInitialized = false;
      });

      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error switching camera: $e");
    }
  }

  void _zoomIn() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _zoomLevel = _zoomLevel < 5.0 ? _zoomLevel + 0.5 : 5.0;
    });
    _controller!.setZoomLevel(_zoomLevel);
  }

  void _zoomOut() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _zoomLevel = _zoomLevel > 1.0 ? _zoomLevel - 0.5 : 1.0;
    });
    _controller!.setZoomLevel(_zoomLevel);
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _changeFilter(FilterType filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with filter
          _buildFilteredPreview(),

          // Top controls
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(_getFlashIcon(), color: Colors.white, size: 30),
              onPressed: _toggleFlash,
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.switch_camera,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _switchCamera,
            ),
          ),

          // Recording timer
          if (_isRecording)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Filter selector
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildFilterSelector(),
          ),

          // Bottom controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.zoom_out,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _zoomOut,
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onLongPress: _startRecording,
                      onLongPressUp: _stopRecording,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.fiber_manual_record,
                          color: _isRecording ? Colors.white : Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _zoomIn,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isRecording ? 'Recording...' : 'Hold to record',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredPreview() {
    if (_selectedFilter == FilterType.none) {
      return CameraPreview(_controller!);
    }

    // For a real implementation, you would use a shader with the camera preview
    // This is a simplified version using a color filter
    return ColorFiltered(
      colorFilter: _getColorFilter(),
      child: CameraPreview(_controller!),
    );
  }

  ColorFilter _getColorFilter() {
    switch (_selectedFilter) {
      case FilterType.sepia:
        return const ColorFilter.matrix([
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.grayscale:
        return const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.invert:
        return const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.pixelate:
        // Pixelation is more complex and would require a custom shader
        return const ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  Widget _buildFilterSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildFilterButton('Normal', FilterType.none),
          _buildFilterButton('Sepia', FilterType.sepia),
          _buildFilterButton('Grayscale', FilterType.grayscale),
          _buildFilterButton('Invert', FilterType.invert),
          _buildFilterButton('Pixelate', FilterType.pixelate),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, FilterType filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _selectedFilter == filter ? Colors.blue : Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

enum FilterType { none, sepia, grayscale, invert, pixelate }

class VideoPreviewDialog extends StatefulWidget {
  final String videoPath;

  const VideoPreviewDialog({Key? key, required this.videoPath})
    : super(key: key);

  @override
  _VideoPreviewDialogState createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
