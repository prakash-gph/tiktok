// import 'package:flutter/material.dart';
// import 'package:tiktok/comments/comments_modle.dart';
// import 'package:tiktok/comments/comments_seemore_text.dart';
// import 'package:tiktok/comments/comments_time_ago.dart';

// class CommentReplyItem extends StatelessWidget {
//   final Comment reply;
//   final VoidCallback? onLike;

//   const CommentReplyItem({super.key, required this.reply, this.onLike});

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Container(
//       padding: const EdgeInsets.all(10),
//       margin: const EdgeInsets.only(left: 30, bottom: 8), // indent replies
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(
//             radius: 18,
//             backgroundImage: NetworkImage(reply.profilePhoto),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   reply.userName,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w900,
//                     fontSize: 14,
//                     color: Colors.pinkAccent.shade400,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 SeeMoreText(
//                   text: reply.text,
//                   maxLength: 100,
//                   textStyle: TextStyle(
//                     fontSize: 14,
//                     color: isDarkMode ? Colors.white : Colors.black,
//                   ),
//                   seeMoreStyle: TextStyle(
//                     color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
//                     fontSize: 12,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Text(
//                       timeAgo(reply.timestamp.toDate()),
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     // Uncomment to enable likes
//                     // GestureDetector(
//                     //   onTap: onLike,
//                     //   child: Text(
//                     //     'Like',
//                     //     style: TextStyle(
//                     //       color: reply.likes > 0 ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
//                     //       fontSize: 12,
//                     //       fontWeight: FontWeight.bold,
//                     //     ),
//                     //   ),
//                     // ),
//                     // if (reply.likes > 0) ...[
//                     //   const SizedBox(width: 4),
//                     //   Text(
//                     //     '${reply.likes}',
//                     //     style: TextStyle(
//                     //       color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
//                     //       fontSize: 12,
//                     //     ),
//                     //   ),
//                     // ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/comments/comments_seemore_text.dart';
import 'package:tiktok/comments/comments_time_ago.dart';

class CommentReplyItem extends StatelessWidget {
  final Comment reply;
  final VoidCallback? onLike;

  const CommentReplyItem({super.key, required this.reply, this.onLike});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(reply.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String profilePhoto = reply.profilePhoto;
        String userName = reply.userName;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          profilePhoto = userData['image'] ?? profilePhoto;
          userName = userData['name'] ?? userName;
        }

        return Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(left: 30, bottom: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: profilePhoto.isNotEmpty
                    ? NetworkImage(profilePhoto)
                    : null,
                child: profilePhoto.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.pinkAccent.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SeeMoreText(
                      text: reply.text,
                      maxLength: 100,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      seeMoreStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo(reply.timestamp.toDate()),
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Add like button if needed
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
