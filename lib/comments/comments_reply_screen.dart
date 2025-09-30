// import 'package:flutter/material.dart';
// import 'package:tiktok/comments/comments_controller.dart';
// import 'package:tiktok/comments/comments_modle.dart';
// import 'package:tiktok/comments/comments_reply_widgets.dart';

// class CommentRepliesScreen extends StatelessWidget {
//   final String parentCommentId;
//   final String videoId;

//   const CommentRepliesScreen({
//     super.key,
//     required this.parentCommentId,
//     required this.videoId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final FirestoreService firestoreService = FirestoreService();

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text(
//           'Replies',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: StreamBuilder<List<Comment>>(
//         stream: firestoreService.getReplies(videoId, parentCommentId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final replies = snapshot.data ?? [];
//           if (replies.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No replies yet\nBe the first to reply!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey, fontSize: 16),
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: replies.length,
//             itemBuilder: (context, index) {
//               final reply = replies[index];
//               return CommentReplyItem(
//                 reply: reply,
//                 onLike: () {
//                   // TODO: wire to FirestoreService.likeReply()
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

//  add theme --------------->

import 'package:flutter/material.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/comments/comments_reply_widgets.dart';

class CommentRepliesScreen extends StatelessWidget {
  final String parentCommentId;
  final String videoId;

  const CommentRepliesScreen({
    super.key,
    required this.parentCommentId,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          'Replies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Comment>>(
        stream: firestoreService.getReplies(videoId, parentCommentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: isDarkMode ? Colors.red[300] : Colors.red[700],
                ),
              ),
            );
          }

          final replies = snapshot.data ?? [];
          if (replies.isEmpty) {
            return Center(
              child: Text(
                'No replies yet\nBe the first to reply!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: replies.length,
            itemBuilder: (context, index) {
              final reply = replies[index];
              return CommentReplyItem(
                reply: reply,
                onLike: () {
                  // TODO: wire to FirestoreService.likeReply()
                },
              );
            },
          );
        },
      ),
    );
  }
}
