// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> searchUsers(String query) {
    if (query.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots();
  }

  Stream<QuerySnapshot> searchVideos(String query) {
    if (query.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('videos')
        .where('keywords', arrayContains: query.toLowerCase())
        .snapshots();
  }

  // Search for hashtags
  Stream<QuerySnapshot> searchHashtags(String query) {
    return _firestore
        .collection('videos')
        // ignore: duplicate_ignore
        // ignore: prefer_interpolation_to_compose_strings
        .where('hashtags', arrayContains: '#' + query.toLowerCase())
        .snapshots();
  }

  // Add to recent searches
  Future<void> addToRecentSearches(String userId, String searchTerm) async {
    await _firestore.collection('users').doc(userId).update({
      'recentSearches': FieldValue.arrayUnion([searchTerm]),
    });
  }

  // Get trending searches
  Future<List<String>> getTrendingSearches() async {
    final snapshot = await _firestore
        .collection('trending')
        .doc('searches')
        .get();

    if (snapshot.exists) {
      return List<String>.from(snapshot.data()!['topSearches']);
    }

    return [];
  }
}
