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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final String videoId;
  final Function(Comment) reply;

  const CommentWidget({
    Key? key,
    required this.comment,
    required this.videoId,
    required this.reply,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  bool _isReplying = false;
  bool _isLiked = false;
  bool _isLoadingReply = false;
  bool _isLoadingReplies = false;
  bool _showReplies = false;
  final Uuid _uuid = Uuid();
  int _replyCount = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _isLiked =
        widget.comment.likedBy?.contains(
          AuthenticationController.instanceAuth.user.uid,
        ) ??
        false;
    _loadReplyCount();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.comment.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadReplyCount() async {
    try {
      final count = await _firestoreService.getReplyCount(
        widget.videoId,
        widget.comment.id,
      );
      setState(() {
        _replyCount = count;
      });
    } catch (e) {
      print('Error loading reply count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment content
          _buildCommentContent(),

          // Reply input (if expanded)
          if (_isReplying) _buildReplyInput(),

          // Replies section
          if (_showReplies &&
              widget.comment.replies != null &&
              widget.comment.replies!.isNotEmpty)
            _buildRepliesSection(),

          // View replies button
          if (_replyCount > 0 && !_showReplies) _buildViewRepliesButton(),
        ],
      ),
    );
  }

  Widget _buildCommentContent() {
    if (_userData == null) {
      return _buildLoadingState();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User avatar
        _buildUserAvatar(),

        const SizedBox(width: 12),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username and comment text
              _buildUsernameAndComment(),

              const SizedBox(height: 8),

              // Actions and timestamp
              _buildCommentActions(),
            ],
          ),
        ),

        // Like button and count
        _buildLikeSection(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: CircleAvatar(radius: 20, backgroundColor: Colors.grey[800]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[800]!,
                highlightColor: Colors.grey[700]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: Colors.grey[800]),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[800],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildCommentActions(),
            ],
          ),
        ),
        _buildLikeSection(),
      ],
    );
  }

  Widget _buildUserAvatar() {
    final imageUrl = _userData?['image'] ?? widget.comment.profilePhoto;

    return CircleAvatar(
      radius: 20,
      backgroundImage: CachedNetworkImageProvider(imageUrl),
      backgroundColor: Colors.grey[800],
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback to placeholder if image fails to load
        setState(() {
          _userData = null;
        });
      },
    );
  }

  Widget _buildUsernameAndComment() {
    final username = _userData?['name'] ?? widget.comment.userName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFFFF006B),
          ),
        ),
        const SizedBox(height: 4),
        SeeMoreText(
          text: widget.comment.text,
          maxLength: 100,
          textStyle: const TextStyle(fontSize: 14, color: Colors.white),
          seeMoreStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCommentActions() {
    return Row(
      children: [
        Text(
          timeAgo(widget.comment.timestamp.toDate()),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _likeComment,
          child: Text(
            'Like',
            style: TextStyle(
              color: _isLiked ? const Color(0xFFFF006B) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _isReplying = !_isReplying;
              if (_isReplying) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  _replyFocusNode.requestFocus();
                });
              }
            });
          },
          child: Text(
            'Reply',
            style: TextStyle(
              color: _isReplying ? const Color(0xFFFF006B) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLikeSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _likeComment,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.comment.likes.toString(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            focusNode: _replyFocusNode,
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
                vertical: 12,
              ),
              suffixIcon: _isLoadingReply
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFF006B)),
                      onPressed: _postReply,
                    ),
            ),
            maxLines: null,
          ),
          if (_isLoadingReply)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Color(0xFFFF006B),
                minHeight: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection() {
    if (_isLoadingReplies) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, left: 32),
        child: Column(
          children: List.generate(3, (index) => _buildReplyShimmer()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 12),
      child: Column(
        children: widget.comment.replies!
            .map(
              (reply) => CommentWidget(
                comment: reply,
                reply: widget.reply,
                videoId: widget.videoId,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReplyShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16, backgroundColor: Colors.grey[800]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 12, color: Colors.grey[800]),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.grey[800],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRepliesButton() {
    return FutureBuilder(
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
                        parentCommentId: widget.comment.id,
                        videoId: widget.videoId,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View $replyCount replies',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  void _likeComment() {
    setState(() {
      _isLiked = !_isLiked;
    });

    final userId = AuthenticationController.instanceAuth.user.uid;
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

  void _postReply() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoadingReply = true;
    });

    try {
      DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      final replyCommentId = _uuid.v4();
      final reply = Comment(
        id: replyCommentId,
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

      _loadReplyCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post reply: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReply = false;
          _isReplying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }
}
