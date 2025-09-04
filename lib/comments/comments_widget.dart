import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/comments/comments_reply_screen.dart';
import 'package:tiktok/comments/comments_seemore_text.dart';
import 'package:tiktok/comments/comments_time_ago.dart';
import 'package:uuid/uuid.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final String videoId;
  final Function(Comment) reply;

  // ignore: use_super_parameters
  const CommentWidget({
    Key? key,
    required this.comment,
    required this.videoId,
    required this.reply,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _textController = TextEditingController();

  bool _isReplying = false;
  bool _isLiked = false;
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment.likedBy.contains(
      AuthenticationController.instanceAuth.user.uid,
    ); // Replace with actual user ID
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestoreService.getUserStream(widget.comment.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        widget.comment.profilePhoto,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.comment.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: const Color.fromARGB(255, 253, 0, 194),
                            ),
                          ),
                          SizedBox(height: 4),
                          SeeMoreText(
                            text: widget.comment.text,
                            maxLength: 100,
                            textStyle: TextStyle(fontSize: 14),
                            seeMoreStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                timeAgo(widget.comment.timestamp.toDate()),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 16),
                              GestureDetector(
                                onTap: _likeComment,
                                child: Text(
                                  'Like',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isReplying = !_isReplying;
                                  });
                                },
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _likeComment,
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.comment.likes.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isReplying) _buildReplyInput(),

                if (widget.comment.replies!.isNotEmpty &&
                    widget.comment.replies != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 52, top: 8),
                    child: Column(
                      children: [
                        ...widget.comment.replies!.map(
                          (reply) => CommentWidget(
                            comment: reply,
                            reply: widget.reply,
                            videoId: widget.videoId,
                          ),
                        ),
                      ],
                    ),
                  ),

                FutureBuilder(
                  future: _firestoreService.getReplyCount(
                    widget.videoId,
                    widget.comment.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > 0) {
                      final replyCount = snapshot.data!;
                      return Column(
                        children: [
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommentRepliesScreen(
                                    parentCommentId:
                                        // ignore: unnecessary_string_interpolations
                                        widget.comment.id,
                                    //ignore: unnecessary_string_interpolations
                                    videoId: widget.videoId,
                                  ),
                                ),
                              );
                              // setState(() {
                              //   _showReplies = _showReplies;
                              // });
                            },
                            child: Text(
                              'View $replyCount replies',

                              //  ? 'Hide $replyCount replies'
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 18, backgroundColor: Colors.grey[800]),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 14, color: Colors.grey[800]),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[800],
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

  ////
  void _likeComment() {
    setState(() {
      _isLiked = !_isLiked;
    });

    final userId = AuthenticationController
        .instanceAuth
        .user
        .uid; // Replace with actual user ID
    if (_isLiked) {
      _firestoreService.likeComment(widget.videoId, widget.comment.id, userId);
    } else {
      _firestoreService.unlikeComment(
        widget.videoId,
        widget.comment.id,
        userId,
      );
    }
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 52),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _postReply,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.send, color: Colors.black, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _postReply() async {
    if (_textController.text.trim().isEmpty) return;

    DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final replyCommentId = _uuid.v4();
    final reply = Comment(
      id: replyCommentId, // Will be generated by Firestore
      videoId: widget.videoId,
      userId: AuthenticationController.instanceAuth.user.uid,
      userName: (userDocumentSnapshot.data() as Map<String, dynamic>)["name"],
      profilePhoto:
          (userDocumentSnapshot.data() as Map<String, dynamic>)["image"],
      text: _textController.text,
      timestamp: Timestamp.now(),
      likes: 0,
      parentCommentId: widget.comment.id,
    );

    await _firestoreService.addReply(widget.comment, reply);
    _textController.clear();
    setState(() => _isReplying = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
