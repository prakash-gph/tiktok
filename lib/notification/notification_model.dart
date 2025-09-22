// lib/notifications/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'like', 'comment', 'follow', 'mention', 'share'
  final String sourceUserId;
  final String sourceUserUsername;
  final String sourceUserProfileImage;
  final String? postId;
  final String? commentId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.sourceUserId,
    required this.sourceUserUsername,
    required this.sourceUserProfileImage,
    this.postId,
    this.commentId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      sourceUserId: data['sourceUserId'] ?? '',
      sourceUserUsername: data['sourceUserUsername'] ?? '',
      sourceUserProfileImage: data['sourceUserProfileImage'] ?? '',
      postId: data['postId'],
      commentId: data['commentId'],
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'sourceUserId': sourceUserId,
      'sourceUserUsername': sourceUserUsername,
      'sourceUserProfileImage': sourceUserProfileImage,
      'postId': postId,
      'commentId': commentId,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
