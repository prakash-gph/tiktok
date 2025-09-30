// // import 'dart:io';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';

// // class MediaService {
// // /// Merge local video and audio files. Returns output file path or null.
// // static Future<String?> mergeVideoAndAudio(String videoPath, String audioPath) async {
// // try {
// // final tmp = await getTemporaryDirectory();
// // final outPath = '${t

// import 'dart:io';
// //import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

// class MediaService {
//    static final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
//   static Future<String?> mergeVideoAndAudio(
//     String videoPath,
//     String audioPath,
//   ) async {
//     try {
//       // Get temporary directory for output file
//       final tmp = await getTemporaryDirectory();
//       final outPath =
//           '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}_merged.mp4';

//       // FFmpeg command:
//       // - Copy video stream
//       // - Encode audio to AAC
//       // - Map video from input 0 and audio from input 1
//       // - Truncate to shortest duration
//       final cmd =
//           '-y -i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest "$outPath"';

//       // Execute FFmpeg
//       final session = await _flutterFFmpeg.execute(cmd);
//       final rc = await session.getReturnCode();

//       if (rc != null && rc.isValueSuccess()) {
//         return outPath;
//       }

//       return null; // merge failed
//     } catch (e) {
//       return null; // error occurred
//     }
//   }
// }

// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

// class MediaService {
//   static final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

//   static Future<String?> mergeVideoAudio(
//     String path,
//     String url, {
//     required String videoPath,
//     required String audioPath,
//     required String outputPath,
//   }) async {
//     try {
//       // FFmpeg command to merge video and audio
//       final command =
//           '-i $videoPath -i $audioPath -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest $outputPath';

//       final returnCode = await _flutterFFmpeg.execute(command);

//       if (returnCode == 0) {
//         return outputPath;
//       } else {
//         print('FFmpeg failed with return code: $returnCode');
//         return null;
//       }
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }
// }
