// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// // ignore: unnecessary_import
// import 'package:get/get_core/src/get_main.dart';
// import 'package:tiktok/authentication/authentication_controller.dart';
// import 'package:tiktok/comments/comments_controller.dart';
// import 'package:tiktok/comments/comments_modle.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import 'package:uuid/uuid.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class CommentInput extends StatefulWidget {
//   final String videoId;
//   final String? parentCommentId;
//   final VoidCallback onCommentAdded;
//   final String videoOwnerId;
//   // ignore: use_super_parameters
//   const CommentInput({
//     Key? key,
//     required this.videoId,
//     this.parentCommentId,
//     required this.onCommentAdded,
//     required this.videoOwnerId,
//   }) : super(key: key);

//   @override
//   // ignore: library_private_types_in_public_api
//   _CommentInputState createState() => _CommentInputState();
// }

// class _CommentInputState extends State<CommentInput> {
//   final TextEditingController _controller = TextEditingController();
//   final FirestoreService _firestoreService = FirestoreService();
//   final NotificationController notificationController =
//       Get.find<NotificationController>();

//   final Uuid _uuid = Uuid();
//   bool _isSending = false;
//   String? _userImageUrl;
//   // ignore: unused_field
//   String? _userName;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       final userDocumentSnapshot = await FirebaseFirestore.instance
//           .collection("users")
//           .doc(FirebaseAuth.instance.currentUser!.uid)
//           .get();

//       if (userDocumentSnapshot.exists) {
//         final userData = userDocumentSnapshot.data() as Map<String, dynamic>;
//         setState(() {
//           _userImageUrl = userData["image"];
//           _userName = userData["name"];
//         });
//       }
//     } catch (e) {
//       print('Error loading user data: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // User Avatar
//           if (_userImageUrl != null)
//             Container(
//               margin: const EdgeInsets.only(right: 12),
//               child: CircleAvatar(
//                 radius: 20,
//                 backgroundImage: CachedNetworkImageProvider(_userImageUrl!),
//                 backgroundColor: Colors.grey[800],
//               ),
//             )
//           else
//             Container(
//               margin: const EdgeInsets.only(right: 12),
//               child: CircleAvatar(
//                 radius: 20,
//                 backgroundColor: Colors.grey[800],
//                 child: Icon(Icons.person, color: Colors.grey[500]),
//               ),
//             ),

//           // Comment Input Field
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[800],
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       style: TextStyle(color: Colors.white, fontSize: 14),
//                       decoration: InputDecoration(
//                         hintText: 'Add a comment...',
//                         hintStyle: TextStyle(color: Colors.grey[500]),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
//                         isDense: true,
//                       ),
//                       maxLines: 3,
//                       minLines: 1,
//                     ),
//                   ),

//                   // Send Button
//                   Container(
//                     margin: const EdgeInsets.only(right: 8),
//                     child: IconButton(
//                       icon: _isSending
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : Icon(Icons.send, color: Colors.grey[400]),
//                       onPressed: _isSending ? null : _addComment,
//                       iconSize: 20,
//                       padding: EdgeInsets.zero,
//                       constraints: BoxConstraints(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _addComment() async {
//     if (_controller.text.isEmpty) return;

//     setState(() {
//       _isSending = true;
//     });

//     try {
//       final FirebaseFirestore firestore = FirebaseFirestore.instance;
//       DocumentSnapshot doc = await firestore
//           .collection("videos")
//           .doc(widget.videoId)
//           .get();

//       if (doc.exists) {
//         await firestore.collection("videos").doc(widget.videoId).update({
//           "totalComments": (doc.data()! as dynamic)["totalComments"] + 1,
//         });
//       }

//       DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
//           .collection("users")
//           .doc(FirebaseAuth.instance.currentUser!.uid)
//           .get();

//       final commentId = _uuid.v4();
//       final userData = userDocumentSnapshot.data() as Map<String, dynamic>;

//       final comment = Comment(
//         id: commentId,
//         videoId: widget.videoId,
//         profilePhoto: userData["image"] ?? "",
//         userName: userData["name"] ?? "Unknown User",
//         userId: AuthenticationController.instanceAuth.user.uid,
//         text: _controller.text,
//         timestamp: Timestamp.now(),
//         parentCommentId: widget.parentCommentId ?? commentId,
//       );

//       widget.onCommentAdded();
//       if (widget.videoOwnerId !=
//           AuthenticationController.instanceAuth.user.uid) {
//         await notificationController.createNotification(
//           userId: widget.videoOwnerId,
//           type: 'comment',
//           senderId: AuthenticationController.instanceAuth.user.uid,
//           senderName: userData["name"] ?? "Unknown User",
//           senderProfileImage: userData["image"] ?? "",
//           videoId: widget.videoId,
//           commentText: _controller.text,
//           videoThumbnail: "",
//         );
//       }

//       await _firestoreService.addComment(comment);
//       _controller.clear();

//       // Show success feedback
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Comment added'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       // Show error feedback
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to add comment: $e'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//       print('Error adding comment: $e');
//     } finally {
//       setState(() {
//         _isSending = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }

//  add theme --------------------------->

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentInput extends StatefulWidget {
  final String videoId;
  final String? parentCommentId;
  final VoidCallback onCommentAdded;
  final String videoOwnerId;

  const CommentInput({
    Key? key,
    required this.videoId,
    this.parentCommentId,
    required this.onCommentAdded,
    required this.videoOwnerId,
  }) : super(key: key);

  @override
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationController notificationController =
      Get.find<NotificationController>();

  final Uuid _uuid = Uuid();
  bool _isSending = false;
  String? _userImageUrl;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDocumentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDocumentSnapshot.exists) {
        final userData = userDocumentSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userImageUrl = userData["image"];
          _userName = userData["name"];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User Avatar
          if (_userImageUrl != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(_userImageUrl!),
                backgroundColor: theme.dividerColor,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.dividerColor,
                child: Icon(Icons.person, color: theme.hintColor),
              ),
            ),

          // Comment Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),

                  // Send Button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            )
                          : Icon(Icons.send, color: theme.iconTheme.color),
                      onPressed: _isSending ? null : _addComment,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addComment() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot doc = await firestore
          .collection("videos")
          .doc(widget.videoId)
          .get();

      if (doc.exists) {
        await firestore.collection("videos").doc(widget.videoId).update({
          "totalComments": (doc.data()! as dynamic)["totalComments"] + 1,
        });
      }

      DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      final commentId = _uuid.v4();
      final userData = userDocumentSnapshot.data() as Map<String, dynamic>;

      final comment = Comment(
        id: commentId,
        videoId: widget.videoId,
        profilePhoto: userData["image"] ?? "",
        userName: userData["name"] ?? "Unknown User",
        userId: AuthenticationController.instanceAuth.user.uid,
        text: _controller.text,
        timestamp: Timestamp.now(),
        parentCommentId: widget.parentCommentId ?? commentId,
      );

      widget.onCommentAdded();
      if (widget.videoOwnerId !=
          AuthenticationController.instanceAuth.user.uid) {
        await notificationController.createNotification(
          userId: widget.videoOwnerId,
          type: 'comment',
          senderId: AuthenticationController.instanceAuth.user.uid,
          senderName: userData["name"] ?? "Unknown User",
          senderProfileImage: userData["image"] ?? "",
          videoId: widget.videoId,
          commentText: _controller.text,
          videoThumbnail: "",
        );
      }

      await _firestoreService.addComment(comment);
      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error adding comment: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
