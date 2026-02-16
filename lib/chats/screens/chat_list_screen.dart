import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  final String currentUserId = AuthenticationController.instanceAuth.user.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Detect theme once at the top
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Messages",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.pink : Colors.deepPurple,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No messages yet",
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;
          chatDocs.sort((a, b) {
            final t1 = a['lastMessageTime'] ?? Timestamp(0, 0);
            final t2 = b['lastMessageTime'] ?? Timestamp(0, 0);
            return t2.compareTo(t1);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatDocs.length,
            separatorBuilder: (_, __) => Divider(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
              );
              final chatId = chatDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'User';
                  final image = userData['image'] ?? '';

                  final lastMessage = chatData['lastMessage'] ?? '';
                  final lastMessageType = chatData['lastMessageType'] ?? 'text';
                  final timestamp = (chatData['lastMessageTime'] as Timestamp?)
                      ?.toDate();

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .where('receiverId', isEqualTo: currentUserId)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, unreadSnap) {
                      final unreadCount = unreadSnap.data?.docs.length ?? 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          backgroundImage: image.isNotEmpty
                              ? NetworkImage(image)
                              : null,
                          child: image.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: _buildLastMessagePreview(
                          lastMessage,
                          lastMessageType,
                          isDark,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (timestamp != null)
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  color: unreadCount > 0
                                      ? (isDark
                                            ? Colors.pinkAccent
                                            : Colors.deepPurple)
                                      : (isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600]),
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.pinkAccent
                                      : Colors.deepPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            () => ChatScreen(
                              chatId: chatId,
                              otherUserId: otherUserId,
                              otherUserName: name,
                              otherUserPhoto: image,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildLastMessagePreview(String message, String type, bool isDark) {
  String preview = '';

  switch (type) {
    case 'video_share':
      preview = "Sent a video";
      break;
    case 'text':
    default:
      preview = message;
      break;
  }

  return Text(
    preview,
    style: TextStyle(
      color: isDark ? Colors.grey[400] : Colors.grey[700],
      fontSize: 14,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

String _formatTimestamp(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays >= 7) {
    return DateFormat('dd/MM').format(date);
  } else if (difference.inDays >= 1) {
    return DateFormat('EEE').format(date);
  } else if (difference.inHours >= 1) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes}m';
  } else {
    return 'now';
  }
}
