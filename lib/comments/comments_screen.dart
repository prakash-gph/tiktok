import 'package:flutter/material.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_input.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/comments/comments_widget.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;

  const CommentsScreen({super.key, required this.videoId});

  @override
  // ignore: library_private_types_in_public_api
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _firestoreService.getComments(widget.videoId),

              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final comments = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return CommentWidget(
                        comment: comments[index],
                        videoId: widget.videoId,
                        reply: (comments) {
                          _commentController.text = '@${comments.userName} ';
                          _commentController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _commentController.text.length,
                                ),
                              );
                          FocusScope.of(context).requestFocus(FocusNode());
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading comments'));
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          CommentInput(
            videoId: widget.videoId,
            onCommentAdded: () {
              // Refresh comments if needed
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
