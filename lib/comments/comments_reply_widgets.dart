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
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(left: 30, bottom: 8), // indent replies
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(reply.profilePhoto),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color.fromARGB(255, 253, 0, 194),
                  ),
                ),
                const SizedBox(height: 4),
                SeeMoreText(
                  text: reply.text,
                  maxLength: 100,
                  textStyle: const TextStyle(fontSize: 14),
                  seeMoreStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      timeAgo(reply.timestamp.toDate()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    // GestureDetector(
                    //   onTap: onLike,
                    //   child: Text(
                    //     'Like',
                    //     style: TextStyle(
                    //       color: reply.likes > 0 ? Colors.red : Colors.grey,
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),
                    // if (reply.likes > 0) ...[
                    //   const SizedBox(width: 4),
                    //   Text(
                    //     '${reply.likes}',
                    //     style: const TextStyle(
                    //       color: Colors.grey,
                    //       fontSize: 12,
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
