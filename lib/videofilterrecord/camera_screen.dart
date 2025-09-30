// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'editor_screen.dart';

// class CameraScreen extends StatefulWidget {
// const CameraScreen({super.key});

// @override
// State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
// CameraController? _controller;
// List<CameraDescription>? _cameras;
// bool _isRecording = false;

// @override
// void initState() {
// super.initState();
// WidgetsBinding.instance.addObserver(this);
// _initCameras();
// }

// Future<void> _initCameras() async {
// _cameras = await availableCameras();
// if (_cameras != null && _cameras!.isNotEmpty) {
// _controller = CameraController(_cameras!.first, ResolutionPreset.high, enableAudio: true);
// await _controller!.initialize();
// if (!mounted) return;
// setState(() {});
// }
// }@override
// _controller?.dispose();
// super.dispose();
// }

// Future<void> _startRecording() async {
// if (_controller == null || !_controller!.value.isInitialized) return;
// await _controller!.startVideoRecording();
// setState(() => _isRecording = true);
// }

// Future<void> _stopRecording() async {
// if (_controller == null || !_controller!.value.isRecordingVideo) return;
// final file = await _controller!.stopVideoRecording();
// setState(() => _isRecording = false);
// if (!mounted) return;

// // navigate to editor with recorded file
// Navigator.of(context).push(MaterialPageRoute(
// builder: (_) => EditorScreen(videoFile: File(file.path)),
// ));
// }

// @override
// Widget build(BuildContext context) {
// if (_controller == null || !_controller!.value.isInitialized) {
// return const Scaffold(body: Center(child: CircularProgressIndicator()));
// }

// return Scaffold(
// body: Stack(
// children: [
// CameraPreview(_controller!),
// Positioned(
// bottom: 40,
// left: 0,
// right: 0,
// child: Row(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// GestureDetector(
// onLongPress: _startRecording,
// onLongPressUp: _stopRecording,
// child: Container(
// width: 80,
// height: 80,
// decoration: BoxDecoration(
// color: _isRecording ? Colors.red : Colors.white54,
// shape: BoxShape.circle,
// ),
// ),
// ),
// ],
// ),
// ),
// ],
// ),
// );
// }

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'editor_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    final file = await _controller!.stopVideoRecording();
    setState(() => _isRecording = false);
    if (!mounted) return;

    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => EditorScreen(videoFile: File(file.path)),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
