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
