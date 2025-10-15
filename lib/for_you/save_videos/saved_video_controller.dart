// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/for_you/save_videos/saved_video_model.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';

// class SavedVideoController extends GetxController {
//   final RxList<SavedVideoModel> savedVideos = <SavedVideoModel>[].obs;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String userId = AuthenticationController.instanceAuth.user.uid;

//   Future<void> toggleSaveVideo(SavedVideoModel video) async {
//     final docRef = _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('savedVideos')
//         .doc(video.videoId);

//     final doc = await docRef.get();

//     if (doc.exists) {
//       await docRef.delete();
//       savedVideos.removeWhere((v) => v.videoId == video.videoId);
//     } else {
//       await docRef.set(video.toMap());
//       savedVideos.add(video);
//     }
//   }

//   Stream<List<SavedVideoModel>> getSavedVideosStream() {
//     return _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('savedVideos')
//         .orderBy('savedAt', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs
//               .map((doc) => SavedVideoModel.fromMap(doc.data()))
//               .toList(),
//         );
//   }

//   Future<bool> isVideoSaved(String videoId) async {
//     final doc = await _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('savedVideos')
//         .doc(videoId)
//         .get();
//     return doc.exists;
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedVideoService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Save video to user's saved list
  Future<void> saveVideo(String videoId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('savedVideos')
        .doc(videoId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  /// Remove from saved list
  Future<void> unsaveVideo(String videoId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('savedVideos')
        .doc(videoId)
        .delete();
  }

  /// Check if a video is already saved
  Stream<bool> isVideoSaved(String videoId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('savedVideos')
        .doc(videoId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  /// Get all saved videos (list of videoIds)
  Stream<List<String>> getSavedVideoIds() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('savedVideos')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
