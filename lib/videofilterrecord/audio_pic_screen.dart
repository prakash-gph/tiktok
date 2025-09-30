import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/videofilterrecord/audio_tracker.dart';

class AudioPickerScreen extends StatelessWidget {
  final void Function(AudioTrack) onSelected;
  const AudioPickerScreen({required this.onSelected, super.key});

  Future<void> _pick(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
    );
    if (res == null || res.files.isEmpty) return;
    final file = res.files.first;
    final track = AudioTrack(title: file.name, artist: null, url: file.path!);
    onSelected(track);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick audio from device')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _pick(context),
          child: const Text('Pick audio file'),
        ),
      ),
    );
  }
}
