import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tiktok/home/home_screen.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class FirebaseService {
  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _uuid = const Uuid();

  /// ✅ Compress a video file before upload
  static Future<File?> compressVideoFile(String videoFilePath) async {
    final compressedVideo = await VideoCompress.compressVideo(
      videoFilePath,
      quality: VideoQuality.MediumQuality,
    );
    return compressedVideo?.file;
  }

  /// ✅ Generate a thumbnail file from the video
  static Future<File> getThumbnailImage(String videoFilePath) async {
    final thumbnailBytes = await VideoCompress.getByteThumbnail(videoFilePath);

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(thumbnailBytes!);

    return file;
  }

  /// ✅ Upload thumbnail to Firebase Storage
  static Future<String> uploadThumbnailImageToFireBaseStorage(
    String videoId,
    String videoFilePath,
  ) async {
    final thumbnailFile = await getThumbnailImage(videoFilePath);
    UploadTask thumbnailUploadTask = _storage
        .ref()
        .child("All Thumbnails")
        .child("$videoId.jpg")
        .putFile(thumbnailFile);
    TaskSnapshot snapshot = await thumbnailUploadTask;
    String downloadUrlOfUploadedThumbnail = await snapshot.ref.getDownloadURL();
    return downloadUrlOfUploadedThumbnail;
  }

  /// ✅ Main function: Upload video file + metadata to Firebase
  static Future<Map<String, dynamic>> uploadVideoFile(
    File file, {
    required String userId,
    String? songName,
    String? description,
    Function(double)? onProgress,
    Function(String phase)? onPhaseChange,
  }) async {
    try {
      onPhaseChange?.call('starting');

      // Step 1: Generate unique video ID
      final String videoId = _uuid.v4();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final Reference ref = _storage.ref().child('videos/$fileName');

      // Step 2: Compress the video before upload
      onPhaseChange?.call('compressing');
      final compressedFile = await compressVideoFile(file.path);
      final uploadFile = compressedFile ?? file;

      // Step 3: Upload video file
      onPhaseChange?.call('uploading');
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploaded_by': userId,
          'description': description ?? '',
        },
      );

      final UploadTask uploadTask = ref.putFile(uploadFile, metadata);

      // Track upload progress
      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes;
        if (total > 0) {
          final percent = (event.bytesTransferred / total) * 100;
          onProgress?.call(percent);
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String videoUrl = await snapshot.ref.getDownloadURL();

      // Step 4: Upload thumbnail
      onPhaseChange?.call('thumbnail');
      final String thumbnailDownloadUrl =
          await uploadThumbnailImageToFireBaseStorage(videoId, file.path);

      // Step 5: Fetch user info from Firestore
      onPhaseChange?.call('saving');

      final userDoc = await _firestore.collection("users").doc(userId).get();

      final userData = userDoc.data() ?? {};

      // Step 6: Create video metadata
      final videoData = Video(
        userId: userId,
        userName: userData["name"] ?? "Unknown",
        userProfileImage: userData["image"] ?? "",
        videoId: videoId,
        totalComments: 0,
        totalShares: 0,
        likesList: [],
        descriptionTags: description ?? "",
        videoUrl: videoUrl,
        artistSongName: songName ?? "Original sound",
        thumbnailUrl: thumbnailDownloadUrl,
        publishedDateTime: DateTime.now().millisecondsSinceEpoch,
      );

      // Step 7: Save video info to Firestore
      await _firestore
          .collection('videos')
          .doc(videoId)
          .set(videoData.toJson());

      onPhaseChange?.call('completed');

      Get.offAll(() => HomeScreen());

      return {'success': true, 'video': videoData};
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      onPhaseChange?.call('error');
      return {'success': false, 'error': e.toString()};
    }
  }
}
