// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/upload_videos/video.dart';

// class GetVideoUrlController extends GetxController {
//   final Rx<List<Video>> _videoList = Rx<List<Video>>([]);
//   final Rx<String> _errorMessage = Rx<String>('');
//   final Rx<bool> _isLoading = Rx<bool>(true);

//   List<Video> get videoList => _videoList.value;
//   String get errorMessage => _errorMessage.value;
//   bool get isLoading => _isLoading.value;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchVideos();
//   }

//   void fetchVideos() {
//     _isLoading.value = true;
//     _videoList.bindStream(
//       FirebaseFirestore.instance
//           .collection("videos")
//           .snapshots()
//           .handleError((error) {
//             _errorMessage.value = "Error fetching videos: ${error.toString()}";
//             _isLoading.value = false;
//           })
//           .map((QuerySnapshot query) {
//             List<Video> retVal = [];
//             for (var element in query.docs) {
//               try {
//                 retVal.add(Video.fromDocumentSnapshot(element));
//               } catch (e) {
//                 // ignore: avoid_print
//                 print("Error parsing video: $e");
//               }
//             }
//             _isLoading.value = false;
//             return retVal;
//           }),
//     );
//   }

//   // Optional: Refresh method
//   Future<void> refreshVideos() async {
//     _videoList.value = [];
//     _isLoading.value = true;
//     fetchVideos();
//   }

//   likeVideos(String id) async {
//     DocumentSnapshot doc = await FirebaseFirestore.instance
//         .collection("videos")
//         .doc(id)
//         .get();
//     var uid = AuthenticationController.instanceAuth.user.uid;

//     if ((doc.data()! as dynamic)["likesList"].contains(uid)) {
//       await FirebaseFirestore.instance.collection("videos").doc(id).update({
//         "likesList": FieldValue.arrayRemove([uid]),
//       });
//     } else {
//       await FirebaseFirestore.instance.collection("videos").doc(id).update({
//         "likesList": FieldValue.arrayUnion([uid]),
//       });
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/upload_videos/video.dart';

class GetVideoUrlController extends GetxController {
  final Rx<List<Video>> _videoList = Rx<List<Video>>([]);
  final Rx<String> _errorMessage = Rx<String>('');
  final Rx<bool> _isLoading = Rx<bool>(true);

  // Get the notification controller instance
  final NotificationController notificationController =
      Get.find<NotificationController>();
  final AuthenticationController authController =
      Get.find<AuthenticationController>();

  List<Video> get videoList => _videoList.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoading => _isLoading.value;
  String get authUserId => authController.user.uid;

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  void fetchVideos() {
    _isLoading.value = true;
    _videoList.bindStream(
      FirebaseFirestore.instance
          .collection("videos")
          .snapshots()
          .handleError((error) {
            _errorMessage.value = "Error fetching videos: ${error.toString()}";
            _isLoading.value = false;
          })
          .map((QuerySnapshot query) {
            List<Video> retVal = [];
            for (var element in query.docs) {
              try {
                retVal.add(Video.fromDocumentSnapshot(element));
              } catch (e) {
                print("Error parsing video: $e");
              }
            }
            _isLoading.value = false;
            return retVal;
          }),
    );
  }

  Future<void> refreshVideos() async {
    _videoList.value = [];
    _isLoading.value = true;
    fetchVideos();
  }

  Future<void> likeVideo(
    String videoId,
    String videoOwnerId,
    String videoOwnerName,
    String videoThumbnail,
  ) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("videos")
          .doc(videoId)
          .get();

      if (!doc.exists) return;

      if ((doc.data()! as dynamic)["likesList"].contains(authUserId)) {
        // Unlike the video
        await FirebaseFirestore.instance
            .collection("videos")
            .doc(videoId)
            .update({
              "likesList": FieldValue.arrayRemove([authUserId]),
            });
      } else {
        // Like the video
        await FirebaseFirestore.instance
            .collection("videos")
            .doc(videoId)
            .update({
              "likesList": FieldValue.arrayUnion([authUserId]),
            });

        DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        // Create notification for the video owner if it's not the current user
        if (videoOwnerId != authUserId) {
          await notificationController.createNotification(
            userId: videoOwnerId,
            type: 'like',
            senderId: authUserId,
            senderName:
                (userDocumentSnapshot.data() as Map<String, dynamic>)["name"] ??
                'Unknown User',
            senderProfileImage:
                (userDocumentSnapshot.data()
                    as Map<String, dynamic>)["image"] ??
                '',
            videoId: videoId,
            videoThumbnail: videoThumbnail,
          );
        }
      }
    } catch (e) {
      print("Error in likeVideo: $e");
    }
  }
}
