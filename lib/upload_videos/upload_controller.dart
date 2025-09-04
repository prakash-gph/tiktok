import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/globle.dart';
import 'package:tiktok/home/home_screen.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:video_compress/video_compress.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

class UploadController extends GetxController {
  //static var videoList;

  // Compress video file
  Future<File?> compressVideoFile(String videoFilePath) async {
    final compressedVideo = await VideoCompress.compressVideo(
      videoFilePath,
      quality: VideoQuality.LowQuality,
    );
    return compressedVideo!.file;
  }

  // Upload compressed video to Firebase Storage
  Future<String> uploadCompressedVideoFileToFireBaseStorage(
    String videoId,
    String videoFilePath,
  ) async {
    final compressedVideoFile = await compressVideoFile(videoFilePath);
    UploadTask videoUploadTask = FirebaseStorage.instance
        .ref()
        .child("All Videos")
        .child(videoId)
        .putFile(compressedVideoFile!);
    TaskSnapshot snapshot = await videoUploadTask;
    String downloadUrlOfUploadedVideo = await snapshot.ref.getDownloadURL();
    return downloadUrlOfUploadedVideo;
  }

  // Get thumbnail image as a File
  Future<File> getThumbnailImage(String videoFilePath) async {
    final thumbnailBytes = await VideoCompress.getByteThumbnail(videoFilePath);

    // Create a temporary file from the thumbnail bytes
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(thumbnailBytes!);

    return file;
  }

  // Upload thumbnail to Firebase Storage
  Future<String> uploadThumbnailImageToFireBaseStorage(
    String videoId,
    String videoFilePath,
  ) async {
    final thumbnailFile = await getThumbnailImage(videoFilePath);
    UploadTask thumbnailUploadTask = FirebaseStorage.instance
        .ref()
        .child("All Thumbnails")
        .child(videoId)
        .putFile(thumbnailFile);
    TaskSnapshot snapshot = await thumbnailUploadTask;
    String downloadUrlOfUploadedThumbnail = await snapshot.ref.getDownloadURL();
    return downloadUrlOfUploadedThumbnail;
  }

  // Save video information to Firestore
  Future<void> saveVideoInformationToFirestoreDatabase(
    String artistSongName,
    String descriptionTags,
    String videoFilePath,
    BuildContext context,
  ) async {
    try {
      showProgressBar = true;
      update(); // Notify listeners about the progress bar change

      DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      String videoId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload video and thumbnail sequentially to avoid type issues
      String videoDownloadUrl =
          await uploadCompressedVideoFileToFireBaseStorage(
            videoId,
            videoFilePath,
          );
      String thumbnailDownloadUrl = await uploadThumbnailImageToFireBaseStorage(
        videoId,
        videoFilePath,
      );

      Video videoObject = Video(
        userId: FirebaseAuth.instance.currentUser!.uid,
        userName: (userDocumentSnapshot.data() as Map<String, dynamic>)["name"],
        userProfileImage:
            (userDocumentSnapshot.data() as Map<String, dynamic>)["image"],
        videoId: videoId,
        totalComments: 0,
        totalShares: 0,
        likesList: [],
        artistSongName: artistSongName,
        descriptionTags: descriptionTags,
        videoUrl: videoDownloadUrl,
        thumbnailUrl: thumbnailDownloadUrl,
        publishedDateTime: DateTime.now().millisecondsSinceEpoch,
      );

      await FirebaseFirestore.instance
          .collection("videos")
          .doc(videoId)
          .set(videoObject.toJson());

      Get.offAll(() => HomeScreen());
      Get.snackbar(
        "New Video",
        "You have successfully uploaded your new video",
      );
    } catch (error) {
      Get.snackbar(
        "Video Upload Failed",
        "Try again. Error occurred: ${error.toString()}",
      );
    } finally {
      showProgressBar = false;
      update(); // Notify listeners about the progress bar change
    }
  }
}
