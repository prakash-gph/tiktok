import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:share_plus/share_plus.dart';

void shareVideoAndTrack(String videoId, String userId) async {
  // Share the video
  // Share.share('Check out this TikTok video!');

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
}
