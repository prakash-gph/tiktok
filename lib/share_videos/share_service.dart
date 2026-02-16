// lib/services/share_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> shareVideoToUsers({
    required String videoId,
    required String videoUrl,
    required String thumbnailUrl,
    required String description,
    required String senderId,
    required String senderName,
    required String senderImage,
    required List<String> receiverIds,
  }) async {
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    for (String receiverId in receiverIds) {
      final chatId = [senderId, receiverId]..sort();
      final combinedId = chatId.join("_");

      final messageRef = _firestore
          .collection('chats')
          .doc(combinedId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'type': 'video_share',
        'videoId': videoId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'senderId': senderId,
        'senderName': senderName,
        'senderImage': senderImage,
        'receiverId': receiverId,
        'timestamp': timestamp,
        'isRead': false,
      });

      // Update last message preview
      batch.set(_firestore.collection('chats').doc(combinedId), {
        'lastMessage': 'Sent a video',
        'lastMessageTime': timestamp,
        'lastMessageType': 'video_share',
        'participants': [senderId, receiverId],
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
