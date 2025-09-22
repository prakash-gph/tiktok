// // controllers/notification_controller.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';

// class NotificationController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Create a notification
//   Future<void> createNotification({
//     required String userId,
//     required String type,
//     required String senderId,
//     required String senderName,
//     required String senderProfileImage,
//     required String videoId,
//     String? commentText,
//     String? videoThumbnail,
//   }) async {
//     try {
//       // Don't create notification if user is notifying themselves
//       if (userId == senderId) return;

//       await _firestore.collection('notifications').add({
//         'userId': userId,
//         'type': type,
//         'senderId': senderId,
//         'senderName': senderName,
//         'senderProfileImage': senderProfileImage,
//         'videoId': videoId,
//         'videoThumbnail': videoThumbnail,
//         'commentText': commentText,
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });
//     } catch (e) {
//       print('Error creating notification: $e');
//     }
//   }

//   // Get notifications for current user
//   Stream<QuerySnapshot> getNotifications() {
//     return _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: _auth.currentUser!.uid)
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }

//   // Mark notification as read
//   Future<void> markAsRead(String notificationId) async {
//     await _firestore.collection('notifications').doc(notificationId).update({
//       'read': true,
//     });
//   }

//   // Mark all notifications as read
//   Future<void> markAllAsRead() async {
//     final querySnapshot = await _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: _auth.currentUser!.uid)
//         .where('read', isEqualTo: false)
//         .get();

//     final batch = _firestore.batch();
//     for (final doc in querySnapshot.docs) {
//       batch.update(doc.reference, {'read': true});
//     }
//     await batch.commit();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthenticationController authController = Get.find();
  final RxBool _indexCreating = false.obs;
  final RxString _indexError = ''.obs;
  final RxList<Map<String, dynamic>> _cachedNotifications =
      <Map<String, dynamic>>[].obs;

  bool get isIndexCreating => _indexCreating.value;
  String get indexError => _indexError.value;
  List<Map<String, dynamic>> get cachedNotifications =>
      // ignore: invalid_use_of_protected_member
      _cachedNotifications.value;

  // Get notifications with fallback for index issues
  Stream<QuerySnapshot> getNotifications() {
    String currentUserId = authController.user.uid;

    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            if (error.toString().contains('index')) {
              _handleIndexError(currentUserId);
              return Stream<QuerySnapshot>.empty();
            }
            _indexError.value = 'Error: ${error.toString()}';
            return Stream<QuerySnapshot>.empty();
          });
    } catch (e) {
      _indexError.value = 'Error setting up notifications: $e';
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Handle index creation error with fallback
  void _handleIndexError(String userId) {
    _indexError.value = 'Index is being created. Using fallback data.';
    _indexCreating.value = true;

    // Use a simpler query as fallback
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get()
        .then((querySnapshot) {
          _cachedNotifications.value = querySnapshot.docs
              // ignore: unnecessary_cast
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Sort locally by timestamp
          _cachedNotifications.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp;
            final bTime = b['timestamp'] as Timestamp;
            return bTime.compareTo(aTime);
          });

          _indexCreating.value = false;
        })
        .catchError((error) {
          _indexError.value = 'Fallback also failed: $error';
          _indexCreating.value = false;
        });
  }

  // Other methods remain the same
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      String currentUserId = authController.user!.uid;

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print("Error marking all notifications as read: $e");
    }
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String senderId,
    required String senderName,
    required String senderProfileImage,
    String? videoId,
    String? videoThumbnail,
    String? commentText,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'senderId': senderId,
        'senderName': senderName,
        'senderProfileImage': senderProfileImage,
        'videoId': videoId,
        'videoThumbnail': videoThumbnail,
        'commentText': commentText,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating notification: $e");
    }
  }

  void clearError() {
    _indexError.value = '';
    _indexCreating.value = false;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
