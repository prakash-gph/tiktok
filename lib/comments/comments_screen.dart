// import 'package:flutter/material.dart';
// import 'package:tiktok/comments/comments_controller.dart';
// import 'package:tiktok/comments/comments_input.dart';
// import 'package:tiktok/comments/comments_modle.dart';
// import 'package:tiktok/comments/comments_widget.dart';
// import 'package:shimmer/shimmer.dart';

// class CommentsScreen extends StatefulWidget {
//   final String videoId;
//   final String videoOwnerId;
//   const CommentsScreen({
//     super.key,
//     required this.videoId,
//     required this.videoOwnerId,
//   });

//   @override
//   // ignore: library_private_types_in_public_api
//   _CommentsScreenState createState() => _CommentsScreenState();
// }

// class _CommentsScreenState extends State<CommentsScreen> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final TextEditingController _commentController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoading = true;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     // Simulate initial loading delay for better UX
//     Future.delayed(Duration(milliseconds: 300), () {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Widget _buildLoadingShimmer() {
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey[800]!,
//           highlightColor: Colors.grey[700]!,
//           child: Container(
//             margin: EdgeInsets.only(bottom: 16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(radius: 20, backgroundColor: Colors.grey),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         height: 14,
//                         color: Colors.grey,
//                       ),
//                       SizedBox(height: 8),
//                       Container(
//                         width: double.infinity,
//                         height: 12,
//                         color: Colors.grey,
//                       ),
//                       SizedBox(height: 4),
//                       Container(width: 100, height: 10, color: Colors.grey),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, color: Colors.grey, size: 64),
//           SizedBox(height: 16),
//           Text(
//             'Failed to load comments',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Please check your connection and try again',
//             style: TextStyle(color: Colors.grey, fontSize: 14),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _hasError = false;
//                 _isLoading = true;
//               });
//               Future.delayed(Duration(milliseconds: 500), () {
//                 if (mounted) {
//                   setState(() => _isLoading = false);
//                 }
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: Text('Try Again'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 64),
//           SizedBox(height: 16),
//           Text(
//             'No comments yet',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Be the first to comment on this video',
//             style: TextStyle(color: Colors.grey, fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: Text(
//           'Comments',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: Colors.white),
//             onPressed: () {
//               setState(() {
//                 _isLoading = true;
//                 _hasError = false;
//               });
//               Future.delayed(Duration(milliseconds: 500), () {
//                 if (mounted) {
//                   setState(() => _isLoading = false);
//                 }
//               });
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//                 ? _buildLoadingShimmer()
//                 : _hasError
//                 ? _buildErrorState()
//                 : StreamBuilder<List<Comment>>(
//                     stream: _firestoreService.getComments(widget.videoId),
//                     builder: (context, snapshot) {
//                       if (snapshot.hasError) {
//                         return _buildErrorState();
//                       }

//                       if (!snapshot.hasData) {
//                         return _buildLoadingShimmer();
//                       }

//                       final comments = snapshot.data!;

//                       if (comments.isEmpty) {
//                         return _buildEmptyState();
//                       }

//                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                         _scrollToBottom();
//                       });

//                       return ListView.builder(
//                         controller: _scrollController,
//                         padding: EdgeInsets.all(16),
//                         itemCount: comments.length,
//                         itemBuilder: (context, index) {
//                           return CommentWidget(
//                             comment: comments[index],
//                             videoId: widget.videoId,
//                             reply: (comment) {
//                               _commentController.text = '@${comment.userName} ';
//                               _commentController.selection =
//                                   TextSelection.fromPosition(
//                                     TextPosition(
//                                       offset: _commentController.text.length,
//                                     ),
//                                   );
//                               FocusScope.of(context).requestFocus(FocusNode());
//                               _scrollToBottom();
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//           ),
//           CommentInput(
//             videoId: widget.videoId,
//             videoOwnerId: widget.videoOwnerId,
//             onCommentAdded: () {
//               setState(() {});
//               _scrollToBottom();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

//     add  theme ----------------->

import 'package:flutter/material.dart';
import 'package:tiktok/comments/comments_controller.dart';
import 'package:tiktok/comments/comments_input.dart';
import 'package:tiktok/comments/comments_modle.dart';
import 'package:tiktok/comments/comments_widget.dart';
import 'package:shimmer/shimmer.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;
  final String videoOwnerId;
  const CommentsScreen({
    super.key,
    required this.videoId,
    required this.videoOwnerId,
  });

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Simulate initial loading delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDarkMode
                      ? Colors.grey[600]!
                      : Colors.grey[400]!,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 10,
                        color: isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load comments',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mode_comment_outlined,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment on this video',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Comments',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer(context)
                : _hasError
                ? _buildErrorState(context)
                : StreamBuilder<List<Comment>>(
                    stream: _firestoreService.getComments(widget.videoId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && !_hasError) {
                            setState(() => _hasError = true);
                          }
                        });
                        return _buildErrorState(context);
                      }

                      if (!snapshot.hasData) {
                        return _buildLoadingShimmer(context);
                      }

                      final comments = snapshot.data!;

                      if (comments.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentWidget(
                            comment: comments[index],
                            videoId: widget.videoId,
                            reply: (comment) {
                              _commentController.text = '@${comment.userName} ';
                              _commentController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _commentController.text.length,
                                    ),
                                  );
                              FocusScope.of(context).requestFocus(FocusNode());
                              _scrollToBottom();
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          CommentInput(
            videoId: widget.videoId,
            videoOwnerId: widget.videoOwnerId,
            onCommentAdded: () {
              if (mounted) {
                setState(() {});
              }
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }
}
