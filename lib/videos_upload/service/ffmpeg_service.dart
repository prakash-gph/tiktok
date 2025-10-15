// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_https_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_https_flutter/return_code.dart';

class FFmpegService {
  /// Trim audio: start (s) and duration (s). Returns path to trimmed file or null.
  static Future<String?> trimAudio(
    String audioPath,
    double startSeconds,
    double durationSeconds,
  ) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out = p.join(
        tmp.path,
        'trimmed_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      final cmd =
          '-i "$audioPath" -ss ${startSeconds.toStringAsFixed(3)} -t ${durationSeconds.toStringAsFixed(3)} -c:a aac -b:a 192k -y "$out"';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        final f = File(out);
        return f.existsSync() ? out : null;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('trimAudio failed rc=${rc?.getValue()} logs:$logs');
        return null;
      }
    } catch (e) {
      debugPrint('trimAudio exception: $e');
      return null;
    }
  }

  /// Merge video + audio: map video stream from first input and audio from second. Returns output path or null.
  static Future<String?> mergeVideoWithAudio(
    String videoPath,
    String audioPath,
  ) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out = p.join(
        tmp.path,
        'merged_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final cmd =
          '-i "${videoPath}" -i "${audioPath}" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest -y "$out"';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        final f = File(out);
        return f.existsSync() ? out : null;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint(
          'mergeVideoWithAudio failed rc=${rc?.getValue()} logs:$logs',
        );
        return null;
      }
    } catch (e) {
      debugPrint('mergeVideoWithAudio exception: $e');
      return null;
    }
  }
}
