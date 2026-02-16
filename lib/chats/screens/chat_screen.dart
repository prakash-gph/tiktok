import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = AuthenticationController.instanceAuth.user.uid;

  final Set<String> _markedAsRead = <String>{};
  bool _isNearBottom = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 100,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset <=
        _scrollController.position.minScrollExtent + 200) {
      _isNearBottom = true;
    } else if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 500) {
      _isNearBottom = true;
    } else {
      _isNearBottom = false;
    }
  }

  void _scrollToBottom() {
    if (!_isNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markAllVisibleMessagesAsRead();
    }
  }

  void _onMessageVisible(String messageId, bool isFromMe, bool isRead) {
    if (isFromMe || isRead || _markedAsRead.contains(messageId)) return;

    _markedAsRead.add(messageId);
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true})
        .catchError((e) => debugPrint("Read receipt error: $e"));
  }

  void _markAllVisibleMessagesAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      if (!_markedAsRead.contains(doc.id)) {
        batch.update(doc.reference, {'isRead': true});
        _markedAsRead.add(doc.id);
      }
    }
    if (snapshot.docs.isNotEmpty) await batch.commit();
  }

  void _goToUserProfile() {
    Get.to(
      () => ProfileScreen(
        userId: widget.otherUserId,
        isCurrentUser: widget.otherUserId == currentUserId,
      ),
    );
  }

  void _showDeleteOptions(String messageId, bool isSender) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      backgroundColor: Colors.transparent,
      Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(top: 12),
            ),
            const SizedBox(height: 16),
            if (isSender)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  "Delete for everyone",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _deleteForEveryone(messageId);
                },
              ),
            if (isSender) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(isSender ? "Delete for me" : "Unsend from my view"),
              onTap: () {
                Get.back();
                _deleteForMe(messageId);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteForMe(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedFor': FieldValue.arrayUnion([currentUserId]),
        });
  }

  Future<void> _deleteForEveryone(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: GestureDetector(
          onTap: _goToUserProfile,
          child: Row(
            children: [
              Hero(
                tag: "avatar_${widget.otherUserId}",
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.otherUserPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(widget.otherUserPhoto)
                      : null,
                  child: widget.otherUserPhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Say hi! 👋",
                      style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: docs.length,
                  cacheExtent: 1000,
                  itemBuilder: (context, index) {
                    final msg = docs[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final messageId = msg.id;
                    final isMe = data['senderId'] == currentUserId;

                    final deletedFor =
                        (data['deletedFor'] as List<dynamic>?)
                            ?.cast<String>() ??
                        [];
                    if (deletedFor.contains(currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    return VisibilityDetector(
                      key: Key("msg_$messageId"),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction > 0.1 &&
                            !isMe &&
                            !(data['isRead'] == true)) {
                          _onMessageVisible(
                            messageId,
                            isMe,
                            data['isRead'] == true,
                          );
                        }
                      },
                      child: GestureDetector(
                        onLongPress: () => _showDeleteOptions(messageId, isMe),
                        child: data['type'] == 'video_share'
                            ? VideoMessageBubble(
                                data: data,
                                isMe: isMe,
                                isDark: isDark,
                              )
                            : TextMessageBubble(
                                data: data,
                                isMe: isMe,
                                isDark: isDark,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: isDark
                        ? Colors.pinkAccent
                        : Colors.deepPurple,
                    elevation: 0,
                    onPressed: () {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      _sendTextMessage(text);
                      _messageController.clear();
                      _scrollToBottom();
                    },
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage(String text) async {
    final user = AuthenticationController.instanceAuth.user;
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();

    await ref.set({
      'type': 'text',
      'text': text,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'User',
      'receiverId': widget.otherUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'deletedFor': [],
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageType': 'text',
        'participants': [user.uid, widget.otherUserId],
      },
      SetOptions(merge: true),
    );

    _scrollToBottom();
  }
}

// Reusable Text Bubble
class TextMessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isDark;

  const TextMessageBubble({
    super.key,
    required this.data,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final isRead = data['isRead'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? Colors.deepPurple : Colors.deepPurple)
              : (isDark
                    ? Colors.grey[800]
                    : const Color.fromARGB(255, 192, 184, 184)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data['text'] ?? '',
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp != null
                      ? DateFormat('h:mm a').format(timestamp)
                      : 'Sending...',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done,
                    size: 16,
                    color: isRead ? Colors.cyan : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Video Bubble (No Chewie in list!)
class VideoMessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isDark;

  const VideoMessageBubble({
    super.key,
    required this.data,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final videoUrl = data['videoUrl'] as String;
    final thumbnailUrl = data['thumbnailUrl'] as String?;
    final description = data['description'] as String? ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final isRead = data['isRead'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () =>
                  Get.to(() => FullScreenVideoPlayer(videoUrl: videoUrl)),
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            width: 240,
                            height: 360,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[800]),
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey[800]),
                          )
                        : Container(
                            width: 240,
                            height: 360,
                            color: Colors.grey[800],
                          ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 80,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
                child: Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13.5,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp != null
                      ? DateFormat('h:mm a').format(timestamp)
                      : 'Sending...',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done,
                    size: 16,
                    color: isRead ? Colors.cyan : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed FullScreenVideoPlayer with proper disposal
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _videoController
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController,
              autoPlay: true,
              looping: false,
              allowFullScreen: true,
              allowMuting: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: Colors.pinkAccent,
                handleColor: Colors.pink,
                backgroundColor: Colors.grey,
                bufferedColor: Colors.white30,
              ),
            );
          });
        })
        // ignore: invalid_return_type_for_catch_error
        .catchError((e) => debugPrint("Video init error: $e"));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: _chewieController != null && _videoController.value.isInitialized
          ? Center(child: Chewie(controller: _chewieController!))
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
