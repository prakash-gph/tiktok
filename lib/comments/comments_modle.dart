import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String videoId;
  final String userId;
  final String userName;
  final String profilePhoto;
  final String text;
  final int likes;
  final Timestamp timestamp;
  final String? parentCommentId;
  final List<String> likedBy;
  final List? replies;

  Comment({
    required this.id,
    required this.videoId,
    required this.profilePhoto,
    required this.userName,
    required this.userId,
    required this.text,
    this.likes = 0,
    required this.timestamp,
    this.parentCommentId,
    this.likedBy = const [],
    this.replies = const [],
  });

  factory Comment.fromSnap(Map<String, dynamic> map, id) {
    return Comment(
      id: map['id'],
      videoId: map['videoId'],
      userName: map['userName'],
      profilePhoto: map['profilePhoto'],
      userId: map['userId'],
      text: map['text'],
      likes: map['likes'] ?? 0,
      timestamp: map['timestamp'],
      parentCommentId: map['parentCommentId'],
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoId': videoId,
      'userName': userName,
      'profilePhoto': profilePhoto,
      'userId': userId,
      'text': text,
      'likes': likes,
      'timestamp': timestamp,
      'parentCommentId': parentCommentId,
      'likedBy': likedBy,
    };
  }

  Comment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? userName,
    String? profilePhoto,
    String? text,
    Timestamp? timestamp,
    int? likes,
    List<Comment>? replies,
    String? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}
