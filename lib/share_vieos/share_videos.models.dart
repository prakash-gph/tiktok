import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tiktok/notification/notification_controller.dart';
//import 'package:share_plus/share_plus.dart';

void shareVideoAndTrack(String videoId, String userId) async {
  final NotificationController notificationController =
      Get.find<NotificationController>();

  // Update share count in Firestore
  await FirebaseFirestore.instance.collection('videos').doc(videoId).update({
    'totalShares': FieldValue.increment(1),
    'sharedBy': FieldValue.arrayUnion([userId]),
  });

  // You might also want to create a shares collection for analytics
  await FirebaseFirestore.instance.collection('shares').add({
    'videoId': videoId,
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
    'platform': 'unknown', // You might detect the platform if possible
  });

  DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();

  if (userId != FirebaseAuth.instance.currentUser!.uid) {
    notificationController.createNotification(
      userId: userId,
      type: 'share',
      senderId: FirebaseAuth.instance.currentUser!.uid,
      senderName:
          (userDocumentSnapshot.data() as Map<String, dynamic>)["name"] ??
          'Unknown User',
      senderProfileImage:
          (userDocumentSnapshot.data() as Map<String, dynamic>)["image"] ?? '',
      videoId: videoId,
      videoThumbnail: "",
    );
  }
}
