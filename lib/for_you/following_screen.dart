import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FollowService _followService = FollowService();

  // ignore: unused_field
  AppUser? _currentUser;
  bool _isLoading = true;
  final Map<String, bool> _unfollowLoadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _currentUser = AppUser.fromSnap(userDoc);
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unfollowUser(String targetUserId) async {
    setState(() {
      _unfollowLoadingStates[targetUserId] = true;
    });

    try {
      await _followService.unfollowUser(targetUserId);
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unfollowing user'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _unfollowLoadingStates[targetUserId] = false;
    });
  }

  Future<void> _confirmUnfollow(String targetUserId, String username) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Unfollow $username?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'They will no longer be able to view your exclusive content.',
            style: TextStyle(color: Colors.white70),
          ),
          backgroundColor: Colors.grey[900],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Unfollow', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _unfollowUser(targetUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Following',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection("following")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group, color: Colors.grey, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Not following anyone yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Users you follow will appear here',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final followerDoc = snapshot.data!.docs[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .doc(followerDoc.id)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return _buildUserItemShimmer();
                        }

                        if (!userSnapshot.data!.exists) {
                          return ListTile(
                            title: Text(
                              'User not found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final user = AppUser.fromSnap(userSnapshot.data!);
                        final isCurrentUser =
                            _auth.currentUser?.uid == widget.userId;
                        final isLoading =
                            _unfollowLoadingStates[user.uid] ?? false;

                        return _buildUserItem(user, isCurrentUser, isLoading);
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildUserItemShimmer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, color: Colors.grey[800]),
                SizedBox(height: 8),
                Container(width: 80, height: 12, color: Colors.grey[800]),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(AppUser user, bool isCurrentUser, bool isLoading) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(userId: "${user.uid}", isCurrentUser: false),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Profile Avatar
                Hero(
                  tag: 'profile_${user.uid}',
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: CachedNetworkImageProvider(
                      "${user.image}",
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user.name}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: _followService.getFollowersCount("${user.uid}"),
                        builder: (context, snapshot) {
                          final followers = snapshot.data ?? 0;

                          // ignore: no_leading_underscores_for_local_identifiers
                          String _formatCount(int count) {
                            if (count < 1000) return count.toString();
                            if (count < 1000000)
                              // ignore: curly_braces_in_flow_control_structures
                              return '${(count / 1000).toStringAsFixed(1)}K';
                            return '${(count / 1000000).toStringAsFixed(1)}M';
                          }

                          return Text(
                            '${_formatCount(followers)} followers',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Unfollow Button (only shown if current user is viewing their own following)
                if (isCurrentUser)
                  isLoading
                      ? Container(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.person_remove,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            _confirmUnfollow("${user.uid}", "${user.name}");
                          },
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
