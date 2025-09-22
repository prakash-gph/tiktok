import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  final double progress;

  const RecordingTimer({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
    );
  }
}
