// // ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore, use_build_context_synchronously

// import 'dart:async';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:tiktok/utils/permissions.dart';
// import 'package:tiktok/videos_upload/screens/preview_screen.dart';
// import '../widgets/filter_selector.dart';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen>
//     with WidgetsBindingObserver {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isRecording = false;
//   int _selectedFilter = 0;
//   FlashMode _flashMode = FlashMode.off;
//   int _durationLimit = 15; // default seconds: 15 or 30
//   Timer? _recordTimer;
//   int _remainingSeconds = 0;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initialize();
//   }

//   @override
//   void dispose() {
//     _recordTimer?.cancel();
//     _controller?.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> _initialize() async {
//     await Permissions.requestCameraAndMic();
//     _cameras = await availableCameras();
//     if (_cameras != null && _cameras!.isNotEmpty) {
//       _controller = CameraController(
//         _cameras!.first,
//         ResolutionPreset.high,
//         enableAudio: true,
//       );
//       await _controller!.initialize();
//       await _controller!.setFlashMode(_flashMode);
//       if (mounted) setState(() {});
//     }
//   }

//   Future<void> _toggleCamera() async {
//     if (_cameras == null || _cameras!.length < 2) return;
//     final current = _controller!.description;
//     final newCamera = _cameras!.firstWhere(
//       (c) => c.lensDirection != current.lensDirection,
//     );
//     await _controller!.dispose();
//     _controller = CameraController(
//       newCamera,
//       ResolutionPreset.high,
//       enableAudio: true,
//     );
//     await _controller!.initialize();
//     await _controller!.setFlashMode(_flashMode);
//     setState(() {});
//   }

//   Future<void> _toggleFlash() async {
//     if (_controller == null) return;
//     if (_flashMode == FlashMode.off) {
//       _flashMode = FlashMode.auto;
//     } else if (_flashMode == FlashMode.auto)
//       _flashMode = FlashMode.always;
//     else if (_flashMode == FlashMode.always)
//       _flashMode = FlashMode.torch;
//     else
//       _flashMode = FlashMode.off;
//     await _controller!.setFlashMode(_flashMode);
//     setState(() {});
//   }

//   void _startCountdown() {
//     _remainingSeconds = _durationLimit;
//     _recordTimer?.cancel();
//     _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
//       setState(() => _remainingSeconds -= 1);
//       if (_remainingSeconds <= 0) {
//         await _stopRecordingAndNavigate();
//       }
//     });
//   }

//   Future<void> _startRecording() async {
//     if (_controller == null ||
//         !_controller!.value.isInitialized ||
//         _isRecording)
//       return;
//     try {
//       final dir = await getTemporaryDirectory();
//       p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.mp4');
//       await _controller!.startVideoRecording();
//       setState(() => _isRecording = true);
//       _startCountdown();
//     } catch (e) {
//       debugPrint('Start recording error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to start recording')),
//       );
//     }
//   }

//   Future<void> _stopRecordingAndNavigate() async {
//     if (_controller == null || !_isRecording) return;
//     try {
//       final xfile = await _controller!.stopVideoRecording();
//       _recordTimer?.cancel();
//       setState(() {
//         _isRecording = false;
//         _remainingSeconds = 0;
//       });
//       final file = File(xfile.path);
//       if (await file.length() == 0) {
//         ScaffoldMessenger.of(
//           // ignore: use_build_context_synchronously
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Recorded file empty')));
//         return;
//       }
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => PreviewScreen(videoFile: file)),
//       );
//     } catch (e) {
//       debugPrint('Stop recording error: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to stop recording')));
//     }
//   }

//   Widget _buildPreviewWithFilter() {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     Widget preview = CameraPreview(_controller!);

//     // Apply simple shader-based filter if we have a filter id that maps to shader.
//     // For simplicity we use ColorFilter matrix or overlay (FilterSelector supports shader integration).
//     final def = demoFilters[_selectedFilter % demoFilters.length];
//     if (def.colorMatrix != null) {
//       preview = ColorFiltered(
//         colorFilter: ColorFilter.matrix(def.colorMatrix!),
//         child: preview,
//       );
//     } else if (def.overlayColor != null && def.blendMode != null) {
//       preview = Stack(
//         fit: StackFit.expand,
//         children: [
//           preview,
//           Positioned.fill(
//             child: Container(
//               foregroundDecoration: BoxDecoration(
//                 color: def.overlayColor,
//                 backgroundBlendMode: def.blendMode,
//               ),
//             ),
//           ),
//         ],
//       );
//     }
//     // Advanced: if you want to use FragmentProgram shaders, you can load them here and wrap preview with a CustomPainter.
//     return preview;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 color: Colors.black,
//                 child: _buildPreviewWithFilter(),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 12.0,
//                 vertical: 8,
//               ),
//               child: Column(
//                 children: [
//                   FilterSelector(
//                     onFilterChanged: (i) => setState(() => _selectedFilter = i),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         onPressed: _toggleFlash,
//                         icon: Icon(
//                           _flashMode == FlashMode.off
//                               ? Icons.flash_off
//                               : Icons.flash_on,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           const Text('15s'),
//                           Radio<int>(
//                             value: 15,
//                             groupValue: _durationLimit,
//                             onChanged: (v) =>
//                                 setState(() => _durationLimit = v ?? 15),
//                           ),
//                           const SizedBox(width: 6),
//                           const Text('30s'),
//                           Radio<int>(
//                             value: 30,
//                             groupValue: _durationLimit,
//                             onChanged: (v) =>
//                                 setState(() => _durationLimit = v ?? 30),
//                           ),
//                         ],
//                       ),
//                       IconButton(
//                         onPressed: _toggleCamera,
//                         icon: const Icon(Icons.flip_camera_ios),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (_isRecording)
//                         Text(
//                           '$_remainingSeconds s',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       const SizedBox(width: 12),
//                       GestureDetector(
//                         onTap: _isRecording
//                             ? _stopRecordingAndNavigate
//                             : _startRecording,
//                         child: CircleAvatar(
//                           radius: 34,
//                           backgroundColor: _isRecording
//                               ? Colors.red
//                               : Colors.white,
//                           child: Icon(
//                             _isRecording ? Icons.stop : Icons.circle,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//ignore_for_file: use_build_context_synchronously, duplicate_ignore, curly_braces_in_flow_control_structures

// import 'dart:async';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:tiktok/utils/permissions.dart';
// import 'package:tiktok/videos_upload/screens/preview_screen.dart';
// import 'package:tiktok/videos_upload/screens/upload_screen.dart';
// import '../widgets/filter_selector.dart';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen>
//     with WidgetsBindingObserver {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isRecording = false;
//   int _selectedFilter = 0;
//   FlashMode _flashMode = FlashMode.off;
//   final int _durationLimit = 15;
//   Timer? _recordTimer;
//   int _remainingSeconds = 0;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initialize();
//   }

//   @override
//   void dispose() {
//     _recordTimer?.cancel();
//     _controller?.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> _initialize() async {
//     await Permissions.requestCameraAndMic();
//     _cameras = await availableCameras();
//     if (_cameras != null && _cameras!.isNotEmpty) {
//       _controller = CameraController(
//         _cameras!.first,
//         ResolutionPreset.high,
//         enableAudio: true,
//       );
//       await _controller!.initialize();
//       await _controller!.setFlashMode(_flashMode);
//       if (mounted) setState(() {});
//     }
//   }

//   Future<void> _toggleCamera() async {
//     if (_cameras == null || _cameras!.length < 2) return;
//     final current = _controller!.description;
//     final newCamera = _cameras!.firstWhere(
//       (c) => c.lensDirection != current.lensDirection,
//     );
//     await _controller!.dispose();
//     _controller = CameraController(
//       newCamera,
//       ResolutionPreset.high,
//       enableAudio: true,
//     );
//     await _controller!.initialize();
//     await _controller!.setFlashMode(_flashMode);
//     setState(() {});
//   }

//   Future<void> _toggleFlash() async {
//     if (_controller == null) return;
//     if (_flashMode == FlashMode.off)
//       _flashMode = FlashMode.auto;
//     else if (_flashMode == FlashMode.auto)
//       _flashMode = FlashMode.always;
//     else if (_flashMode == FlashMode.always)
//       _flashMode = FlashMode.torch;
//     else
//       _flashMode = FlashMode.off;

//     await _controller!.setFlashMode(_flashMode);
//     setState(() {});
//   }

//   void _startCountdown() {
//     _remainingSeconds = _durationLimit;
//     _recordTimer?.cancel();
//     _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
//       setState(() => _remainingSeconds -= 1);
//       if (_remainingSeconds <= 0) {
//         await _stopRecordingAndNavigate();
//       }
//     });
//   }

//   Future<void> _startRecording() async {
//     if (_controller == null ||
//         !_controller!.value.isInitialized ||
//         _isRecording)
//       return;
//     try {
//       final dir = await getTemporaryDirectory();
//       p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.mp4');
//       await _controller!.startVideoRecording();
//       setState(() => _isRecording = true);
//       _startCountdown();
//     } catch (e) {
//       debugPrint('Start recording error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to start recording')),
//       );
//     }
//   }

//   Future<void> _stopRecordingAndNavigate() async {
//     if (_controller == null || !_isRecording) return;
//     try {
//       final xfile = await _controller!.stopVideoRecording();
//       _recordTimer?.cancel();
//       setState(() {
//         _isRecording = false;
//         _remainingSeconds = 0;
//       });
//       final file = File(xfile.path);
//       if (await file.length() == 0) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Recorded file empty')));
//         return;
//       }
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => PreviewScreen(videoFile: file)),
//       );
//     } catch (e) {
//       debugPrint('Stop recording error: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Failed to stop recording')));
//     }
//   }

//   Widget _buildPreviewWithFilter() {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     Widget preview = CameraPreview(_controller!);
//     final def = demoFilters[_selectedFilter % demoFilters.length];
//     if (def.colorMatrix != null) {
//       preview = ColorFiltered(
//         colorFilter: ColorFilter.matrix(def.colorMatrix!),
//         child: preview,
//       );
//     } else if (def.overlayColor != null && def.blendMode != null) {
//       preview = Stack(
//         fit: StackFit.expand,
//         children: [
//           preview,
//           Positioned.fill(
//             child: Container(
//               foregroundDecoration: BoxDecoration(
//                 color: def.overlayColor,
//                 backgroundBlendMode: def.blendMode,
//               ),
//             ),
//           ),
//         ],
//       );
//     }
//     return preview;
//   }

//   Widget _buildGradientUploadButton() {
//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const UploadScreen()),
//       ),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           gradient: const LinearGradient(
//             colors: [Color(0xFFFF2E63), Color(0xFFFC466B), Color(0xFF3F5EFB)],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 6,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.upload_rounded, color: Colors.white),
//             SizedBox(width: 8),
//             Text(
//               "Upload",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           _buildPreviewWithFilter(),

//           /// 📍 Top bar (flash + timer)
//           Positioned(
//             top: 40,
//             left: 16,
//             right: 16,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   onPressed: _toggleFlash,
//                   icon: Icon(
//                     _flashMode == FlashMode.off
//                         ? Icons.flash_off
//                         : Icons.flash_on,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//                 if (_isRecording)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       "⏱ ${_remainingSeconds}s",
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           /// 📍 Right side toolbar (filter + flip)
//           Positioned(
//             right: 12,
//             bottom: 160,
//             child: Column(
//               children: [
//                 IconButton(
//                   onPressed: _toggleCamera,
//                   icon: const Icon(Icons.flip_camera_ios),
//                   color: Colors.white,
//                   iconSize: 30,
//                 ),
//                 const SizedBox(height: 12),
//                 IconButton(
//                   onPressed: () => showModalBottomSheet(
//                     context: context,
//                     backgroundColor: Colors.black87,
//                     builder: (_) => SizedBox(
//                       height: 200,
//                       child: FilterSelector(
//                         onFilterChanged: (i) =>
//                             setState(() => _selectedFilter = i),
//                       ),
//                     ),
//                   ),
//                   icon: const Icon(Icons.filter_alt_rounded),
//                   color: Colors.white,
//                   iconSize: 30,
//                 ),
//               ],
//             ),
//           ),

//           /// 📍 Center Record Button
//           Positioned(
//             bottom: 80,
//             left: 0,
//             right: 0,
//             child: GestureDetector(
//               onTap: _isRecording ? _stopRecordingAndNavigate : _startRecording,
//               child: CircleAvatar(
//                 radius: 36,
//                 backgroundColor: _isRecording ? Colors.redAccent : Colors.white,
//                 child: Icon(
//                   _isRecording ? Icons.stop : Icons.fiber_manual_record,
//                   color: _isRecording ? Colors.white : Colors.redAccent,
//                   size: 30,
//                 ),
//               ),
//             ),
//           ),

//           /// 📍 Gradient Upload Button (bottom right)
//           Positioned(
//             bottom: 30,
//             right: 20,
//             child: _buildGradientUploadButton(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// deepseeks

// // ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tiktok/utils/permissions.dart';
import 'package:tiktok/videos_upload/screens/preview_screen.dart';
import 'package:tiktok/videos_upload/screens/upload_screen.dart';
import '../widgets/filter_selector.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  int _selectedFilter = 0;
  FlashMode _flashMode = FlashMode.off;
  int _durationLimit = 15;
  Timer? _recordTimer;
  int _remainingSeconds = 0;
  late AnimationController _pulseAnimationController;
  late AnimationController _scaleAnimationController;
  // ignore: unused_field
  final double _recordButtonSize = 80.0;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _initialize();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseAnimationController.dispose();
    _scaleAnimationController.dispose();
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialize() async {
    await Permissions.requestCameraAndMic();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    await _scaleAnimationController.forward().then((_) async {
      final current = _controller!.description;
      final newCamera = _cameras!.firstWhere(
        (c) => c.lensDirection != current.lensDirection,
      );
      await _controller!.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      _scaleAnimationController.reverse();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    });
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }
    _flashMode = newMode;
    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  void _startCountdown() {
    _remainingSeconds = _durationLimit;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _remainingSeconds -= 1);
      if (_remainingSeconds <= 0) {
        await _stopRecordingAndNavigate();
      }
    });
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording)
      return;
    try {
      final dir = await getTemporaryDirectory();
      p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
      _startCountdown();
    } catch (e) {
      debugPrint('Start recording error: $e');
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecordingAndNavigate() async {
    if (_controller == null || !_isRecording) return;
    try {
      final xfile = await _controller!.stopVideoRecording();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _remainingSeconds = 0;
      });
      final file = File(xfile.path);
      if (await file.length() == 0) {
        _showErrorSnackBar('Recorded file is empty');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(videoFile: file),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      debugPrint('Stop recording error: $e');
      _showErrorSnackBar('Failed to stop recording');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPreviewWithFilter() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    Widget preview = CameraPreview(_controller!);

    final def = demoFilters[_selectedFilter % demoFilters.length];
    if (def.colorMatrix != null) {
      preview = ColorFiltered(
        colorFilter: ColorFilter.matrix(def.colorMatrix!),
        child: preview,
      );
    } else if (def.overlayColor != null && def.blendMode != null) {
      preview = Stack(
        fit: StackFit.expand,
        children: [
          preview,
          Positioned.fill(
            child: Container(
              foregroundDecoration: BoxDecoration(
                color: def.overlayColor,
                backgroundBlendMode: def.blendMode,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        preview,

        if (_isRecording)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: _buildRecordingIndicator(),
          ),
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(
                        0.6 * (1 - _pulseAnimationController.value),
                      ),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'REC',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$_remainingSeconds s',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 🎯 Instagram-style Top Bar
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Close button
          // GestureDetector(
          //   onTap: () => Navigator.pop(context),
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.5),
          //       shape: BoxShape.circle,
          //     ),
          //     child: const Icon(Icons.close, color: Colors.white, size: 24),
          //   ),
          // ),

          // Duration selector
          _buildDurationSelector(),

          // Flash button
          GestureDetector(
            onTap: _toggleFlash,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: _buildFlashIcon(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashIcon() {
    IconData icon;
    Color color;
    switch (_flashMode) {
      case FlashMode.off:
        icon = Icons.flash_off_rounded;
        color = Colors.grey;
        break;
      case FlashMode.auto:
        icon = Icons.flash_auto_rounded;
        color = Colors.blue;
        break;
      case FlashMode.always:
        icon = Icons.flash_on_rounded;
        color = Colors.amber;
        break;
      case FlashMode.torch:
        icon = Icons.highlight_rounded;
        color = Colors.yellow;
        break;
    }
    return Icon(icon, color: color, size: 24);
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDurationOption('15s', 15),
          const SizedBox(width: 12),
          _buildDurationOption('30s', 30),
          const SizedBox(width: 12),
          //  _buildDurationOption('60s', 60),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String text, int value) {
    final isSelected = _durationLimit == value;
    return GestureDetector(
      onTap: () => setState(() => _durationLimit = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // 🎯 Instagram-style Bottom Bar
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Selector
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 16),
            child: FilterSelector(
              onFilterChanged: (i) => setState(() => _selectedFilter = i),
            ),
          ),

          // Main Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Upload Button
              _buildUploadButton(),

              // Record Button with Timer
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer Display
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_remainingSeconds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Record Button
                  _buildRecordButton(),
                ],
              ),

              // Camera Flip Button
              _buildCameraFlipButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _navigateToScreen(context, const UploadScreen()),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2E63), Color(0xFF3F5EFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecordingAndNavigate : _startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isRecording ? 70 : 80,
        height: _isRecording ? 70 : 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? Colors.red : Colors.white,
          border: Border.all(
            color: _isRecording ? Colors.red : Colors.white30,
            width: _isRecording ? 4 : 3,
          ),
          boxShadow: [
            if (_isRecording)
              BoxShadow(
                color: Colors.red.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 8,
              ),

            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.all(_isRecording ? 15 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording ? Colors.white : Colors.transparent,
            border: _isRecording
                ? null
                : Border.all(color: Colors.white, width: 2),
          ),
          child: _isRecording
              ? Icon(Icons.stop, color: Colors.red, size: 24)
              : Icon(Icons.circle, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildCameraFlipButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleCamera,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              Icons.flip_camera_ios_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isFrontCamera ? 'Front' : 'Back',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            Positioned.fill(child: _buildPreviewWithFilter()),

            // Top Bar
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

            // Bottom Bar
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
          ],
        ),
      ),
    );
  }
}
