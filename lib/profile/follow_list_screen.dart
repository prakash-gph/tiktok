// lib/screens/follow_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/profile/profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String mode; // 'followers' or 'following'

  const FollowListScreen({Key? key, required this.userId, required this.mode})
    : super(key: key);

  @override
  _FollowListScreenState createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.mode == 'followers' ? 'Followers' : 'Following',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.userId)
            .collection(widget.mode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                widget.mode == 'followers'
                    ? 'No followers yet'
                    : 'Not following anyone',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
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
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.grey),
                      title: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        "${user.image}",
                      ),
                      backgroundColor: Colors.grey[800],
                    ),
                    title: Text(
                      "${user.name}",
                      style: TextStyle(color: Colors.white),
                    ),
                    // subtitle: Text(
                    //  // user.bio.isNotEmpty ? user.bio : 'No bio',
                    //   style: TextStyle(color: Colors.grey),
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: "${user.uid}",
                            isCurrentUser: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
