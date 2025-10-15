// ignore_for_file: use_build_context_synchronously

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/comments/comments_time_ago.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tiktok/theme/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required String userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController notificationController = Get.find();
  final Set<String> _selectedNotifications = {};
  bool _isSelectionMode = false;
  final Map<String, String> _timeAgoCache = {};

  @override
  void dispose() {
    _timeAgoCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(
        () => NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            return false;
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: notificationController.getNotifications(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return _buildNotificationList(snapshot.data!.docs, context);
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot, context);
              }

              return _buildLoadingState(context);
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isSelectionMode
            ? Text(
                '${_selectedNotifications.length} selected',
                key: const ValueKey('selected'),
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              )
            : Text(
                'Notifications',
                key: const ValueKey('notifications'),
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: _exitSelectionMode,
            )
          : null,
      actions: _buildAppBarActions(context),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    if (_isSelectionMode) {
      return [
        AnimatedOpacity(
          opacity: _selectedNotifications.isEmpty ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _selectedNotifications.isEmpty
                ? null
                : _deleteSelectedNotifications,
            tooltip: 'Delete selected',
          ),
        ),
      ];
    } else {
      return [
        IconButton(
          icon: Icon(
            Icons.checklist_rounded,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => notificationController.markAllAsRead(),
          tooltip: 'Mark all as read',
        ),
        IconButton(
          icon: Icon(
            Icons.select_all,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: _enterSelectionMode,
          tooltip: 'Select notifications',
        ),
      ];
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget _buildErrorState(
    AsyncSnapshot<QuerySnapshot> snapshot,
    BuildContext context,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'When someone interacts with your content, you\'ll see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<QueryDocumentSnapshot> docs,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now();

        return NotificationItem(
          key: ValueKey(doc.id),
          doc: doc,
          data: data,
          timestamp: timestamp,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedNotifications.contains(doc.id),
          onSelect: _toggleNotificationSelection,
          onLongPress: _handleLongPress,
          onTap: _handleNotificationTap,
          timeAgoCache: _timeAgoCache,
        );
      },
    );
  }

  void _handleLongPress(String id) {
    if (!_isSelectionMode) _enterSelectionMode();
    _toggleNotificationSelection(id);
  }

  void _handleNotificationTap(String id, Map<String, dynamic> data) {
    if (_isSelectionMode) {
      _toggleNotificationSelection(id);
    } else {
      notificationController.markAsRead(id);
      // Navigate to the video if needed
      if (data['videoId'] != null) {
        // Get.to(() => VideoDetailScreen(videoId: data['videoId']));
      }
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotifications.clear();
    });
  }

  void _toggleNotificationSelection(String id) {
    setState(() {
      if (_selectedNotifications.contains(id)) {
        _selectedNotifications.remove(id);
        if (_selectedNotifications.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotifications.add(id);
      }
    });
  }

  Future<void> _deleteSelectedNotifications() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      for (String id in _selectedNotifications) {
        await notificationController.deleteNotification(id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedNotifications.length} notification(s) deleted',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _exitSelectionMode();
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    _isSelectionMode = false;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            'Delete Notifications',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: Text(
            _selectedNotifications.length > 1
                ? 'Are you sure you want to delete ${_selectedNotifications.length} notifications?'
                : 'Are you sure you want to delete this notification?',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(String) onSelect;
  final Function(String) onLongPress;
  final Function(String, Map<String, dynamic>) onTap;
  final Map<String, String> timeAgoCache;

  const NotificationItem({
    super.key,
    required this.doc,
    required this.data,
    required this.timestamp,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
    required this.onLongPress,
    required this.onTap,
    required this.timeAgoCache,
  });

  @override
  Widget build(BuildContext context) {
    final notificationId = doc.id;
    final cachedTimeAgo = timeAgoCache.putIfAbsent(
      notificationId,
      () => timeAgo(timestamp),
    );

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Delete Notification',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this notification?',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        final controller = Get.find<NotificationController>();
        controller.deleteNotification(doc.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification deleted',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Material(
        color: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1))
            : Colors.transparent,
        child: InkWell(
          onLongPress: () => onLongPress(doc.id),
          onTap: () => onTap(doc.id, data),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileAvatar(data, context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationTitle(data, context),
                      const SizedBox(height: 4),
                      Text(
                        cachedTimeAgo,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNotificationTrailing(data, doc.id, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> data, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (data['senderId'] != null) {
          Get.to(() => ProfileScreen(userId: data['senderId']));
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(data['senderId'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final profileImage = userData?['image'] ?? '';

          return Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data['type'] == 'follow'
                        ? Colors.blue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: profileImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profileImage,
                          placeholder: (context, url) => Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                ),
              ),
              if (data['type'] == 'follow')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Widget _buildNotificationTitle(
  //   Map<String, dynamic> data,
  //   BuildContext context,
  // ) {
  //   return RichText(
  //     text: TextSpan(
  //       style: TextStyle(
  //         fontSize: 14,
  //         color: Theme.of(context).textTheme.bodyLarge?.color,
  //       ),
  //       children: [
  //         TextSpan(
  //           text: data['senderName'] ?? 'Unknown User',
  //           style: const TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         TextSpan(text: ' ${_getNotificationText(data['type'])}'),
  //         if (data['type'] == 'comment' && data['commentText'] != null)
  //           TextSpan(
  //             text: ': "${data['commentText']}"',
  //             style: const TextStyle(fontStyle: FontStyle.italic),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildNotificationTitle(
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['senderId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Loading...");
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final senderName = userData['name'] ?? 'Unknown User';

        return RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            children: [
              TextSpan(
                text: senderName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' ${_getNotificationText(data['type'])}'),
              if (data['type'] == 'comment' && data['commentText'] != null)
                TextSpan(
                  text: ': "${data['commentText']}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTrailing(
    Map<String, dynamic> data,
    String docId,
    BuildContext context,
  ) {
    if (isSelectionMode) {
      return Checkbox(
        value: isSelected,
        onChanged: (value) => onSelect(docId),
        fillColor: MaterialStateProperty.all(Colors.blue),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data['read'] == false)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(height: 4),
        ],
      );
    }
  }

  String _getNotificationText(String type) {
    switch (type) {
      case 'like':
        return 'liked your video...❤';
      case 'comment':
        return 'commented on your video...💬';
      case 'share':
        return 'shared your video';
      case 'follow':
        return 'started following you';
      default:
        return 'interacted with your content';
    }
  }
}
