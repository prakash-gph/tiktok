import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:uuid/uuid.dart';

class CommentInput extends StatefulWidget {
  final String videoId;
  final String? parentCommentId;
  final VoidCallback onCommentAdded;

  // ignore: use_super_parameters
  const CommentInput({
    Key? key,
    required this.videoId,
    this.parentCommentId,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    print(AuthenticationController.instanceAuth.user.photoURL);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        children: [
          // CircleAvatar(
          //   radius: 18,
          //   backgroundImage: NetworkImage(
          //     "${AuthenticationController.instanceAuth.user.uid}",
          //   ),
          // ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 0,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addComment() async {
    if (_controller.text.isEmpty) return;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doc = await firestore
        .collection("videos")
        .doc(widget.videoId)
        .get();

    await firestore.collection("videos").doc(widget.videoId).update({
      "totalComments": (doc.data()! as dynamic)["totalComments"] + 1,
    });

    DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final commentId = _uuid.v4();
    final comment = Comment(
      id: commentId,
      videoId: widget.videoId,
      profilePhoto:
          (userDocumentSnapshot.data() as Map<String, dynamic>)["image"],
      userName: (userDocumentSnapshot.data() as Map<String, dynamic>)["name"],
      userId: AuthenticationController.instanceAuth.user.uid,
      // Replace with actual user ID
      text: _controller.text,
      timestamp: Timestamp.now(),
      parentCommentId: commentId,
    );
    await _firestoreService.addComment(comment);
    _controller.clear();
    widget.onCommentAdded();
  }
}
