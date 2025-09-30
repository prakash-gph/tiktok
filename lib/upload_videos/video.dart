//import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String? userId;
  final String? userName;
  final String? userProfileImage;
  final String? artistSongName;
  final String? videoId;
  final List? likesList;
  final int? totalComments;
  final int? totalShares;
  final String? descriptionTags;
  // final bool isLiked;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? publishedDateTime;
  final int? views;
  Video({
    this.userId,
    this.userName,
    this.userProfileImage,
    this.artistSongName,
    this.videoId,
    this.likesList,
    this.totalComments,
    this.totalShares,
    this.descriptionTags,
    // this.isLiked,
    this.videoUrl,
    this.thumbnailUrl,
    this.publishedDateTime,
    this.views,
  });

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "userName": userName,
    "userProfileImage": userProfileImage,
    "artistSongName": artistSongName,
    "videoId": videoId,
    "likesList": likesList,
    "totalComments": totalComments,
    "totalShares": totalShares,
    "descriptionTags": descriptionTags,
    //"isLiked":isLiked,
    "videoUrl": videoUrl,
    "thumbnailUrl": thumbnailUrl,
    "publishedDateTime": publishedDateTime,
    "views": views,
  };

  static Video fromDocumentSnapshot(DocumentSnapshot snapshot) {
    var docSnapshot = snapshot.data() as Map<String, dynamic>;

    return Video(
      userId: docSnapshot["userId"],
      userName: docSnapshot["userName"],
      userProfileImage: docSnapshot["userProfileImage"],
      artistSongName: docSnapshot["artistSongName"],
      videoId: docSnapshot["videoId"],
      likesList: docSnapshot["likesList"],
      totalComments: docSnapshot["totalComments"],
      totalShares: docSnapshot["totalShares"],
      descriptionTags: docSnapshot["descriptionTags"],
      videoUrl: docSnapshot["videoUrl"],
      thumbnailUrl: docSnapshot["thumbnailUrl"],
      publishedDateTime: docSnapshot["publishedDateTime"],
      views: docSnapshot["views"],

      //isLiked: docSnapshot["isLiked"],
    );
  }
}
