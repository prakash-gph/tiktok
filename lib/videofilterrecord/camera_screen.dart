import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/utils/filters.dart';
import 'package:tiktok/videofilterrecord/camera_controls.dart';
import 'package:tiktok/videofilterrecord/filter_selector.dart';
import 'package:tiktok/videofilterrecord/recording_timer.dart';
import 'package:tiktok/videofilterrecord/video_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRecording = false;
  int _selectedFilterIndex = 0;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;
  XFile? _recordedVideo;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;

  // Define the filters list
  final List<VideoFilter> _filters = videoFilters;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      _initializeControllerFuture = _controller!.initialize();

      _initializeControllerFuture!
          .then((_) {
            if (mounted) {
              setState(() {
                _isCameraInitialized = true;
              });
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _hasCameraError = true;
              });
            }
            print("Camera initialization failed: $e");
          });
    } catch (e) {
      setState(() {
        _hasCameraError = true;
      });
      print("Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    if (_controller == null || !_isCameraInitialized) return;

    try {
      await _initializeControllerFuture;

      setState(() {
        _isRecording = true;
        _recordingProgress = 0.0;
      });

      await _controller!.startVideoRecording();

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (
        timer,
      ) {
        if (mounted) {
          setState(() {
            _recordingProgress += 0.1 / 15.0;
            if (_recordingProgress >= 1.0) {
              _stopRecording();
            }
          });
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();

    try {
      if (_controller != null && _controller!.value.isRecordingVideo) {
        XFile videoFile = await _controller!.stopVideoRecording();

        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordedVideo = videoFile;
          });
        }

        // Navigate to preview screen
        if (_recordedVideo != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(
                videoFile: _recordedVideo!,
                videoFilter: _filters[_selectedFilterIndex],
              ),
            ),
          ).then((_) {
            // Reset after returning from preview
            if (mounted) {
              setState(() {
                _recordedVideo = null;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _toggleCamera() async {
    if (_controller?.value.isRecordingVideo == true) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return; // Need at least 2 cameras to toggle

      final newCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection != _controller!.description.lensDirection,
        orElse: () => cameras.first,
      );

      await _controller?.dispose();

      setState(() {
        _isCameraInitialized = false;
        _controller = CameraController(
          newCamera,
          ResolutionPreset.high,
          enableAudio: true,
        );
        _initializeControllerFuture = _controller!.initialize();

        _initializeControllerFuture!.then((_) {
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        });
      });
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  void _onFilterSelected(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hasCameraError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Could not initialize camera'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeCamera,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (!_isCameraInitialized || _controller == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    children: [
                      // Camera preview with filter
                      ColorFiltered(
                        colorFilter:
                            _filters[_selectedFilterIndex].colorFilter ??
                            const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.src,
                            ),
                        child: CameraPreview(_controller!),
                      ),

                      // Top controls
                      const Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(
                                Icons.close,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Icon(
                                Icons.flash_on,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recording progress indicator
                      if (_isRecording)
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: RecordingTimer(progress: _recordingProgress),
                        ),

                      // Bottom controls
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Filter selector
                              FilterSelector(
                                videoFilters: _filters,
                                selectedIndex: _selectedFilterIndex,
                                onFilterSelected: _onFilterSelected,
                              ),
                              const SizedBox(height: 10),
                              // Camera controls
                              CameraControls(
                                isRecording: _isRecording,
                                hasRecordedVideo: _recordedVideo != null,
                                onRecordPressed: _isRecording
                                    ? _stopRecording
                                    : _startRecording,
                                onCameraTogglePressed: _toggleCamera,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
