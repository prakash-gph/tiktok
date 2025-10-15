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

  List<dynamic> get safeLikesList {
    if (likesList is List) return likesList ?? [];
    if (likesList is int) return []; // Return empty list if it's an int
    return [];
  }

  int get safeTotalComments {
    if (totalComments is int) return totalComments ?? 0;
    if (totalComments is List) return totalComments ?? 0;
    return 0;
  }

  int get safeTotalShares {
    if (totalShares is int) return totalShares ?? 0;
    if (totalShares is List) return totalShares ?? 0;
    return 0;
  }

  int get safeViews {
    if (views is int) return views ?? 0;
    if (views is List) return views ?? 0;
    return 0;
  }

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

    "videoUrl": videoUrl,
    "thumbnailUrl": thumbnailUrl,
    "publishedDateTime": publishedDateTime,
    "views": views,
  };

  static Video fromDocumentSnapshot(DocumentSnapshot snapshot) {
    var docSnapshot = snapshot.data() as Map<String, dynamic>? ?? {};

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
    );
  }
}
