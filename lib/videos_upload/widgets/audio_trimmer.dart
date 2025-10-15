import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:tiktok/videos_upload/model/audio_selection.dart';

class AudioTrimmerWidget extends StatefulWidget {
  final ValueChanged<AudioSelection> onChanged;
  const AudioTrimmerWidget({super.key, required this.onChanged});

  @override
  State<AudioTrimmerWidget> createState() => _AudioTrimmerWidgetState();
}

class _AudioTrimmerWidgetState extends State<AudioTrimmerWidget> {
  String? _audioName; // Displayed song name
  // Selected audio file path
  double _start = 0;
  double _duration = 15;

  Future<void> _pickAudio() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res == null || res.files.isEmpty) return;

    final path = res.files.first.path!;
    final name = p.basenameWithoutExtension(path);

    setState(() {
      _audioName = name;
      _start = 0;
      _duration = 15;
    });

    // Always call onChanged
    widget.onChanged(
      AudioSelection(
        path: path,
        start: _start,
        duration: _duration,
        songName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.music_note),
              label: const Text('Pick Audio'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _audioName ?? 'Original sound', // fallback
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
