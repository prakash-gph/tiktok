// // lib/screens/follow_list_screen.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:tiktok/authentication/user.dart';
// import 'package:tiktok/profile/profile_screen.dart';

// class FollowListScreen extends StatefulWidget {
//   final String userId;
//   final String mode; // 'followers' or 'following'

//   const FollowListScreen({Key? key, required this.userId, required this.mode})
//     : super(key: key);

//   @override
//   _FollowListScreenState createState() => _FollowListScreenState();
// }

// class _FollowListScreenState extends State<FollowListScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text(
//           widget.mode == 'followers' ? 'Followers' : 'Following',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('users')
//             .doc(widget.userId)
//             .collection(widget.mode)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return Center(child: CircularProgressIndicator(color: Colors.red));
//           }

//           if (snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Text(
//                 widget.mode == 'followers'
//                     ? 'No followers yet'
//                     : 'Not following anyone',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final followerDoc = snapshot.data!.docs[index];
//               return FutureBuilder<DocumentSnapshot>(
//                 future: _firestore
//                     .collection('users')
//                     .doc(followerDoc.id)
//                     .get(),
//                 builder: (context, userSnapshot) {
//                   if (!userSnapshot.hasData) {
//                     return ListTile(
//                       leading: CircleAvatar(backgroundColor: Colors.grey),
//                       title: Text(
//                         'Loading...',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     );
//                   }

//                   if (!userSnapshot.data!.exists) {
//                     return ListTile(
//                       title: Text(
//                         'User not found',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     );
//                   }

//                   final user = AppUser.fromSnap(userSnapshot.data!);
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: CachedNetworkImageProvider(
//                         "${user.image}",
//                       ),
//                       backgroundColor: Colors.grey[800],
//                     ),
//                     title: Text(
//                       "${user.name}",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     // subtitle: Text(
//                     //   user.bio!.isNotEmpty ? "${user.bio}" : "",
//                     //   style: TextStyle(color: Colors.grey),
//                     //   maxLines: 1,
//                     //   overflow: TextOverflow.ellipsis,
//                     // ),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ProfileScreen(
//                             userId: "${user.uid}",
//                             isCurrentUser: false,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

//  add theme

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          widget.mode == 'followers' ? 'Followers' : 'Following',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
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
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.mode == 'followers'
                        ? Icons.people_outline
                        : Icons.person_outline,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.mode == 'followers'
                        ? 'No followers yet'
                        : 'Not following anyone',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.mode == 'followers'
                        ? 'When someone follows you, they will appear here'
                        : 'Users you follow will appear here',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    return _buildLoadingListItem(context);
                  }

                  if (!userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text(
                        'User not found',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                        ),
                      ),
                    );
                  }

                  final user = AppUser.fromSnap(userSnapshot.data!);
                  return _buildUserListItem(user, context);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingListItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(AppUser user, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Profile Avatar
                Hero(
                  tag: 'profile_${user.uid}_${widget.mode}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider(
                      "${user.image}",
                    ),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user.name}",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
