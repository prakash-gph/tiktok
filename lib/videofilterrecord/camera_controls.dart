import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final bool isRecording;
  final bool hasRecordedVideo;
  final VoidCallback onRecordPressed;
  final VoidCallback onCameraTogglePressed;

  const CameraControls({
    Key? key,
    required this.isRecording,
    required this.hasRecordedVideo,
    required this.onRecordPressed,
    required this.onCameraTogglePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Added padding
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Changed from spaceEvenly
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library, size: 28), // Reduced size
            onPressed: () {},
          ),
          GestureDetector(
            onTap: onRecordPressed,
            child: Container(
              width: 65, // Reduced size
              height: 65, // Reduced size
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3, // Reduced border width
                ),
                color: isRecording
                    ? Colors.red
                    : (hasRecordedVideo ? Colors.green : Colors.transparent),
              ),
              child: Center(
                child: hasRecordedVideo && !isRecording
                    ? const Icon(
                        Icons.check,
                        size: 28,
                        color: Colors.white,
                      ) // Reduced size
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.flip_camera_ios,
              size: 28, // Reduced size
              color: isRecording ? Colors.grey : Colors.white,
            ),
            onPressed: isRecording ? null : onCameraTogglePressed,
          ),
        ],
      ),
    );
  }
}
