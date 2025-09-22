import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok/upload_videos/upload_from.dart';
import 'package:tiktok/videofilterrecord/camera_screen.dart';

class UploadVideosScreen extends StatefulWidget {
  const UploadVideosScreen({super.key});

  @override
  State<UploadVideosScreen> createState() => _UploadVideosScreenState();
}

class _UploadVideosScreenState extends State<UploadVideosScreen> {
  getVideoFile(ImageSource sourceImg) async {
    final videoFile = await ImagePicker().pickVideo(source: sourceImg);

    if (videoFile != null) {
      //video upload from

      Get.to(
        UploadFrom(videoFile: File(videoFile.path), videoPath: videoFile.path),
      );
    }
  }

  displayDialogBox() {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () {
              getVideoFile(ImageSource.gallery);
            },
            child: Row(
              children: [
                const Icon(Icons.image),
                Expanded(
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Get video from Gallery",
                      maxLines: 3,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SimpleDialogOption(
            onPressed: () {
              // getVideoFile(ImageSource.camera);
              Get.to(CameraScreen());
              // Get.to(HomeVideoScreen());
            },
            child: Row(
              children: const [
                Icon(Icons.camera),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Make video with Camera",
                      maxLines: 3,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SimpleDialogOption(
            onPressed: () {
              Get.back();
            },
            child: Row(
              children: const [
                Icon(Icons.cancel),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("Cancel", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            GestureDetector(
              onTap: () {
                displayDialogBox();
              },
              child: const CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage("images/uploadIcons.png"),
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
