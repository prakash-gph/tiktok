import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:tiktok/globle.dart';
import 'package:tiktok/upload_videos/upload_controller.dart';
import 'package:tiktok/widgets/input_text_widgets.dart';
import 'package:video_player/video_player.dart';

class UploadFrom extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const UploadFrom({
    super.key,
    required this.videoFile,
    required this.videoPath,
  });

  @override
  State<UploadFrom> createState() => _UploadFromState();
}

class _UploadFromState extends State<UploadFrom> {
  UploadController uploadVideoController = Get.put(UploadController());
  VideoPlayerController? playerController;
  TextEditingController artistSongtextEditingController =
      TextEditingController();
  TextEditingController descriptionTagtextEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {
      playerController = VideoPlayerController.file(widget.videoFile);
    });

    playerController!.initialize();
    playerController!.play();
    playerController!.setVolume(2);
    playerController!.setLooping(true);
  }

  @override
  void dispose() {
    super.dispose();
    playerController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.3,
              child: VideoPlayer(playerController!),
            ),
            const SizedBox(height: 30),

            //upload btn if user clicked
            //circular progress bar
            //input field
            showProgressBar == true
                // ignore: avoid_unnecessary_containers
                ? Container(
                    child: const SimpleCircularProgressBar(
                      progressColors: [
                        Colors.pink,
                        Colors.green,
                        Colors.blueAccent,
                        Colors.amber,
                        Colors.red,
                        Colors.purpleAccent,
                      ],
                      animationDuration: 220,
                      backColor: Colors.white38,
                    ),
                  )
                : Column(
                    children: [
                      // artist song
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        child: InputTextWidget(
                          controller: artistSongtextEditingController,
                          label: "Artist-Song",
                          icon: Icons.music_video_rounded,
                          isObscure: false,
                        ),
                      ),

                      const SizedBox(height: 10),

                      //description tag
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        child: InputTextWidget(
                          controller: descriptionTagtextEditingController,
                          label: "Description-tag",
                          icon: Icons.slideshow_sharp,
                          isObscure: false,
                        ),
                      ),

                      const SizedBox(height: 10),

                      //upload button
                      Container(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 55,
                        decoration: const BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (artistSongtextEditingController
                                    .text
                                    .isNotEmpty &&
                                descriptionTagtextEditingController
                                    .text
                                    .isNotEmpty) {
                              uploadVideoController
                                  .saveVideoInformationToFirestoreDatabase(
                                    artistSongtextEditingController.text,
                                    descriptionTagtextEditingController.text,
                                    widget.videoPath,
                                    context,
                                  );
                            } else {
                              Get.snackbar(
                                "Fill the table",
                                "Artist-song,Description-tag",
                              );
                              return;
                            }

                            setState(() {
                              showProgressBar = true;
                            });
                          },
                          child: const Center(
                            child: Text(
                              "Upload Now",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,

                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
