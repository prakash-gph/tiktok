import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReelsCreatorScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ReelsCreatorScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _ReelsCreatorScreenState createState() => _ReelsCreatorScreenState();
}

class _ReelsCreatorScreenState extends State<ReelsCreatorScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  bool _isRecording = false;
  bool _isPlayingMusic = false;
  double _recordingProgress = 0.0;
  String _selectedAudio = "No audio selected";
  File? _selectedImage;
  int _mode = 0; // 0 for camera, 1 for gallery

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(
        widget.cameras.first,
        ResolutionPreset.ultraHigh,
      );
      _initializeControllerFuture = _controller.initialize();
    }
  }

  @override
  void dispose() {
    if (widget.cameras.isNotEmpty) {
      _controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _mode = 1; // Switch to gallery mode
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _switchToCamera() {
    setState(() {
      _mode = 0;
      _selectedImage = null;
    });
  }

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _animateRecordingProgress();
    });

    if (_isPlayingMusic) {
      await _audioPlayer.resume();
    } else if (_selectedAudio != "No audio selected") {
      await _audioPlayer.play(AssetSource('audios/sample_music.mp3'));
      setState(() {
        _isPlayingMusic = true;
      });
    }
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
      _recordingProgress = 0.0;
    });

    if (_isPlayingMusic) {
      await _audioPlayer.pause();
    }
  }

  void _animateRecordingProgress() {
    Future.doWhile(() {
      if (!_isRecording) return false;

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isRecording && mounted) {
          setState(() {
            _recordingProgress += 0.01;
            if (_recordingProgress >= 1.0) {
              _recordingProgress = 0.0;
            }
          });
        }
      });

      return _isRecording;
    });
  }

  void _toggleAudioPlayback() async {
    if (_isPlayingMusic) {
      await _audioPlayer.pause();
    } else if (_selectedAudio != "No audio selected") {
      await _audioPlayer.play(AssetSource('audios/sample_music.mp3'));
    }

    setState(() {
      _isPlayingMusic = !_isPlayingMusic;
    });
  }

  void _showSoundSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Sound",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search for sounds",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildSoundItem("Trending Sound 1", "Artist 1"),
                    _buildSoundItem("Viral Audio", "Artist 2"),
                    _buildSoundItem("Popular Song", "Artist 3"),
                    _buildSoundItem("Original Audio", "User Name"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundItem(String title, String artist) {
    return ListTile(
      leading: const Icon(Icons.music_note, size: 40),
      title: Text(title),
      subtitle: Text(artist),
      trailing: const Text("0:15", style: TextStyle(color: Colors.grey)),
      onTap: () {
        setState(() {
          _selectedAudio = title;
        });
        Navigator.pop(context);
      },
    );
  }

  void _switchCamera() {
    if (widget.cameras.length < 2) return; // Need at least 2 cameras to switch

    final lensDirection = _controller.description.lensDirection;
    CameraDescription newCamera;

    if (lensDirection == CameraLensDirection.front) {
      newCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } else {
      newCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    }

    setState(() {
      _controller = CameraController(newCamera, ResolutionPreset.ultraHigh);
      _initializeControllerFuture = _controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview or selected image
          if (_mode == 0 && widget.cameras.isNotEmpty)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          else if (_mode == 0 && widget.cameras.isEmpty)
            const Center(child: Text('No cameras available'))
          else if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

          // Top controls
          _buildTopControls(),

          // Recording progress indicator
          if (_isRecording) _buildRecordingProgress(),

          // Right side controls
          _buildSideControls(),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            _mode == 0 ? "New Reel" : "Edit Photo",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_mode == 0 && widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, size: 30),
              onPressed: _switchCamera,
            )
          else if (_mode == 1)
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 30),
              onPressed: _switchToCamera,
            )
          else
            const SizedBox(width: 48), // Placeholder for layout balance
        ],
      ),
    );
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 10,
      top: 100,
      child: Column(
        children: [
          _buildIconButton(
            Icons.photo_library,
            "Gallery",
            _pickImageFromGallery,
          ),
          const SizedBox(height: 20),
          _buildIconButton(Icons.face, "Beauty", () {}),
          const SizedBox(height: 20),
          _buildIconButton(Icons.filter, "Filter", () {}),
          const SizedBox(height: 20),
          _buildIconButton(Icons.flash_on, "Flash", () {}),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, size: 30), onPressed: onPressed),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Audio info
          Text(_selectedAudio, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),

          // Recording button and additional controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Audio picker button
              IconButton(
                icon: const Icon(Icons.music_note, size: 30),
                onPressed: _showSoundSelection,
              ),

              // Recording/Import button
              if (_mode == 0)
                GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 4),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add, size: 40),
                  onPressed: () {
                    // Process the selected image
                  },
                ),

              // Audio playback toggle
              IconButton(
                icon: Icon(
                  _isPlayingMusic ? Icons.volume_up : Icons.volume_off,
                  size: 30,
                ),
                onPressed: _toggleAudioPlayback,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingProgress() {
    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: LinearProgressIndicator(
        value: _recordingProgress,
        backgroundColor: Colors.grey,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
      ),
    );
  }
}
