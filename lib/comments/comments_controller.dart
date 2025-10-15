import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/comments/comments_modle.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser> getUser(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(AuthenticationController.instanceAuth.user.uid)
        .get();
    return AppUser.fromSnap(doc);
  }

  Stream<AppUser> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => AppUser.fromSnap(snapshot));
  }

  // Comment operations
  Future<void> addComment(Comment comment) async {
    await _firestore
        .collection('videos')
        .doc(comment.videoId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toMap());
  }

  Stream<List<Comment>> getComments(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        // .where('parentCommentId', isNull: true)
        // .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Comment.fromSnap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> likeComment(
    String videoId,
    String commentId,
    String userId,
  ) async {
    await _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
  }

  Future<void> unlikeComment(
    String videoId,
    String commentId,
    String userId,
  ) async {
    await _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId)
        .update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
  }

  // Add a reply to a comment
  Future<void> addReply(Comment parentComment, Comment reply) async {
    final replyWithParent = reply.copyWith(parentCommentId: parentComment.id);
    await _firestore
        .collection('videos')
        .doc(reply.videoId)
        .collection("comments")
        .doc(reply.parentCommentId)
        .collection("replies")
        .add(replyWithParent.toMap());
  }

  Stream<List<Comment>> getReplies(String videoId, String parentCommentId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .where('parentCommentId', isEqualTo: parentCommentId)
        // .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint("Replies fetched: ${snapshot.size}");
          return snapshot.docs
              .map((doc) => Comment.fromSnap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<int> getCommentCount(String videoId) async {
    final snapshot = await _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        // .where('parentCommentId', isNull: true)
        .get();
    return snapshot.size;
  }

  Future<int> getReplyCount(String videoId, String parentCommentId) async {
    final snapshot = await _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(parentCommentId)
        .collection("replies")
        .where('parentCommentId', isEqualTo: parentCommentId)
        .get();
    return snapshot.size;
  }
}
