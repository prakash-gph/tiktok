// lib/services/follow_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Follow a user
  Future<void> followUser(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    if (currentUserId == targetUserId) return; // Can't follow yourself

    // Add to current user's following list
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    // Add to target user's followers list
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    // Update follower/following counts
    await _updateFollowerCount(targetUserId, 1);
    await _updateFollowingCount(currentUserId, 1);
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    if (currentUserId == targetUserId) return; // Can't unfollow yourself

    // Remove from current user's following list
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .delete();

    // Remove from target user's followers list
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .delete();

    // Update follower/following counts
    await _updateFollowerCount(targetUserId, -1);
    await _updateFollowingCount(currentUserId, -1);
  }

  // Check if current user is following a target user
  Future<bool> isFollowing(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    if (currentUserId == targetUserId) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  // Get followers count
  Future<int> getFollowersCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();

    return snapshot.size;
  }

  // Get following count
  Future<int> getFollowingCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    return snapshot.size;
  }

  // Update follower count
  Future<void> _updateFollowerCount(String userId, int change) async {
    await _firestore.collection('users').doc(userId).update({
      'followers': FieldValue.increment(change),
    });
  }

  // Update following count
  Future<void> _updateFollowingCount(String userId, int change) async {
    await _firestore.collection('users').doc(userId).update({
      'following': FieldValue.increment(change),
    });
  }
}
