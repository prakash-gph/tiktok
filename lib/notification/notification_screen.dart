import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/comments/comments_time_ago.dart';
import 'package:tiktok/notification/notification_controller.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Obx(
        () => NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            // Handle scroll events if needed
            return false;
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: notificationController.getNotifications(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              // if (snapshot.connectionState == ConnectionState.waiting) {
              //   return _buildLoadingState();
              // }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // if (snapshot.hasError) {
              //   return _buildErrorState(snapshot);
              // }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return _buildNotificationList(snapshot.data!.docs);
              }

              // If stream has error
              if (snapshot.hasError) {
                return _buildErrorState(snapshot);
              }

              // If no data at all
              return _buildLoadingState();
              // return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  //   Widget _buildCachedNotificationList() {
  //   return ListView.builder(
  //     itemCount: notificationController.cachedNotifications.length,
  //     itemBuilder: (context, index) {
  //       final data = notificationController.cachedNotifications[index];
  //       final timestamp = data['timestamp'] != null
  //           ? (data['timestamp'] as Timestamp).toDate()
  //           : DateTime.now();

  //       return NotificationItem('cached_$index', data, timestamp);
  //     },
  //   );
  // }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isSelectionMode
            ? Text(
                '${_selectedNotifications.length} selected',
                key: const ValueKey('selected'),
                style: const TextStyle(color: Colors.white),
              )
            : const Text(
                'Notifications',
                key: const ValueKey('notifications'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _exitSelectionMode,
            )
          : null,
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        AnimatedOpacity(
          opacity: _selectedNotifications.isEmpty ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
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
          icon: const Icon(Icons.checklist_rounded, color: Colors.white),
          onPressed: () => notificationController.markAllAsRead(),
          tooltip: 'Mark all as read',
        ),
        IconButton(
          icon: const Icon(Icons.select_all, color: Colors.white),
          onPressed: _enterSelectionMode,
          tooltip: 'Select notifications',
        ),
      ];
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildErrorState(AsyncSnapshot<QuerySnapshot> snapshot) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'When someone interacts with your content, you\'ll see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<QueryDocumentSnapshot> docs) {
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
      // Use a batch operation for better performance
      for (String id in _selectedNotifications) {
        await notificationController.deleteNotification(id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedNotifications.length} notification(s) deleted',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
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
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete Notifications',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            _isSelectionMode && _selectedNotifications.length > 1
                ? 'Are you sure you want to delete ${_selectedNotifications.length} notifications?'
                : 'Are you sure you want to delete this notification?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
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
    // Cache timeAgo to avoid recalculating
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
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Delete Notification',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to delete this notification?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
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
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Material(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
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
                _buildProfileAvatar(data),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationTitle(data),
                      const SizedBox(height: 4),
                      Text(
                        cachedTimeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNotificationTrailing(data, doc.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        if (data['senderId'] != null) {
          Get.to(() => ProfileScreen(userId: data['senderId']));
        }
      },
      child: Stack(
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
              child: CachedNetworkImage(
                imageUrl: data['senderProfileImage'] ?? '',
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.person, color: Colors.white),
                fit: BoxFit.cover,
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
      ),
    );
  }

  Widget _buildNotificationTitle(Map<String, dynamic> data) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.white),
        children: [
          TextSpan(
            text: data['senderName'] ?? 'Unknown User',
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
  }

  Widget _buildNotificationTrailing(Map<String, dynamic> data, String docId) {
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

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/comments/comments_time_ago.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import 'package:tiktok/profile/profile_screen.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class NotificationsScreen extends StatefulWidget {
//   final String userId;

//   const NotificationsScreen({super.key, required this.userId});

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final NotificationController notificationController = Get.find();
//   final Set<String> _selectedNotifications = {};
//   bool _isSelectionMode = false;
//   final Map<String, String> _timeAgoCache = {};
//   final ScrollController _scrollController = ScrollController();
//   bool _isRefreshing = false;
//   final Map<String, bool> _deletingNotifications = {};

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _precacheImages();
//     });
//   }

//   void _precacheImages() {
//     precacheImage(
//       const AssetImage('assets/images/placeholder_avatar.png'),
//       context,
//     );
//   }

//   @override
//   void dispose() {
//     _timeAgoCache.clear();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _refreshNotifications() async {
//     setState(() {
//       _isRefreshing = true;
//     });

//     await Future.delayed(const Duration(milliseconds: 800));
//     _timeAgoCache.clear();

//     setState(() {
//       _isRefreshing = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: _buildAppBar(),
//       body: Obx(
//         () => RefreshIndicator(
//           backgroundColor: Colors.black,
//           color: Colors.white,
//           onRefresh: _refreshNotifications,
//           child: StreamBuilder<QuerySnapshot>(
//             stream: notificationController.getNotifications(),
//             builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//               // if (snapshot.connectionState == ConnectionState.waiting &&
//               //     !_isRefreshing) {
//               //   return _buildLoadingState();
//               // }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return _buildEmptyState();
//               }

//               if (snapshot.hasError) {
//                 return _buildErrorState(snapshot);
//               }

//               return _buildNotificationList(snapshot.data!.docs);
//             },
//           ),
//         ),
//       ),
//       floatingActionButton:
//           _isSelectionMode && _selectedNotifications.isNotEmpty
//           ? FloatingActionButton(
//               onPressed: _deleteSelectedNotifications,
//               backgroundColor: Colors.red,
//               child: const Icon(Icons.delete, color: Colors.white),
//             )
//           : null,
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.black,
//       elevation: 0,
//       title: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: _isSelectionMode
//             ? Text(
//                 '${_selectedNotifications.length} selected',
//                 key: const ValueKey('selected'),
//                 style: const TextStyle(color: Colors.white),
//               )
//             : const Text(
//                 'Notifications',
//                 key: ValueKey('notifications'),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//       leading: _isSelectionMode
//           ? IconButton(
//               icon: const Icon(Icons.close, color: Colors.white),
//               onPressed: _exitSelectionMode,
//             )
//           : null,
//       actions: _buildAppBarActions(),
//     );
//   }

//   List<Widget> _buildAppBarActions() {
//     if (_isSelectionMode) {
//       return [
//         if (_selectedNotifications.isNotEmpty)
//           AnimatedOpacity(
//             opacity: 1.0,
//             duration: const Duration(milliseconds: 200),
//             child: IconButton(
//               icon: const Icon(Icons.delete_outline, color: Colors.white),
//               onPressed: _deleteSelectedNotifications,
//               tooltip: 'Delete selected',
//             ),
//           ),
//       ];
//     } else {
//       return [
//         IconButton(
//           icon: const Icon(Icons.checklist_rounded, color: Colors.white),
//           onPressed: _markAllAsRead,
//           tooltip: 'Mark all as read',
//         ),
//         IconButton(
//           icon: const Icon(Icons.select_all, color: Colors.white),
//           onPressed: _enterSelectionMode,
//           tooltip: 'Select notifications',
//         ),
//       ];
//     }
//   }

//   Widget _buildLoadingState() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: 10,
//       itemBuilder: (context, index) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[800],
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       height: 14,
//                       color: Colors.grey[700],
//                     ),
//                     const SizedBox(height: 8),
//                     Container(width: 100, height: 12, color: Colors.grey[700]),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorState(AsyncSnapshot<QuerySnapshot> snapshot) {
//     return Center(
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 64, color: Colors.red),
//             const SizedBox(height: 16),
//             const Text(
//               'Error loading notifications',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text(
//                 snapshot.error.toString(),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => setState(() {}),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.black,
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.notifications_off, size: 64, color: Colors.grey[600]),
//             const SizedBox(height: 16),
//             const Text(
//               'No notifications yet',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             const SizedBox(height: 8),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 32.0),
//               child: Text(
//                 'When someone interacts with your content, you\'ll see it here.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _refreshNotifications,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: Colors.black,
//               ),
//               child: const Text('Refresh'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNotificationList(List<QueryDocumentSnapshot> docs) {
//     return ListView.builder(
//       controller: _scrollController,
//       itemCount: docs.length,
//       itemBuilder: (context, index) {
//         final item = docs[index];
//         final data = item.data() as Map<String, dynamic>;
//         final timestamp = data['timestamp'] != null
//             ? (data['timestamp'] as Timestamp).toDate()
//             : DateTime.now();

//         return NotificationItem(
//           key: ValueKey(item.id),
//           doc: item,
//           data: data,
//           timestamp: timestamp,
//           isSelectionMode: _isSelectionMode,
//           isSelected: _selectedNotifications.contains(item.id),
//           isDeleting: _deletingNotifications[item.id] ?? false,
//           onSelect: _toggleNotificationSelection,
//           onLongPress: _handleLongPress,
//           onTap: _handleNotificationTap,
//           timeAgoCache: _timeAgoCache,
//           onDismiss: () => _deleteNotification(item.id),
//         );
//       },
//     );
//   }

//   void _handleLongPress(String id) {
//     if (!_isSelectionMode) _enterSelectionMode();
//     _toggleNotificationSelection(id);
//   }

//   void _handleNotificationTap(String id, Map<String, dynamic> data) {
//     if (_isSelectionMode) {
//       _toggleNotificationSelection(id);
//     } else {
//       notificationController.markAsRead(id);
//     }
//   }

//   void _enterSelectionMode() {
//     setState(() {
//       _isSelectionMode = true;
//     });
//   }

//   void _exitSelectionMode() {
//     setState(() {
//       _isSelectionMode = false;
//       _selectedNotifications.clear();
//     });
//   }

//   void _toggleNotificationSelection(String id) {
//     setState(() {
//       if (_selectedNotifications.contains(id)) {
//         _selectedNotifications.remove(id);
//         if (_selectedNotifications.isEmpty) {
//           _isSelectionMode = false;
//         }
//       } else {
//         _selectedNotifications.add(id);
//       }
//     });
//   }

//   Future<void> _markAllAsRead() async {
//     try {
//       await notificationController.markAllAsRead();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('All notifications marked as read'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _deleteNotification(String id) async {
//     setState(() {
//       _deletingNotifications[id] = true;
//     });

//     try {
//       await notificationController.deleteNotification(id);

//       if (_selectedNotifications.contains(id)) {
//         _selectedNotifications.remove(id);
//         if (_selectedNotifications.isEmpty) {
//           _isSelectionMode = false;
//         }
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Notification deleted'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error deleting notification: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } finally {
//       setState(() {
//         _deletingNotifications.remove(id);
//       });
//     }
//   }

//   Future<void> _deleteSelectedNotifications() async {
//     final confirmed = await _showDeleteConfirmationDialog();
//     if (confirmed == true) {
//       final toDelete = Set<String>.from(_selectedNotifications);

//       for (String id in toDelete) {
//         await _deleteNotification(id);
//       }

//       _exitSelectionMode();
//     }
//   }

//   Future<bool?> _showDeleteConfirmationDialog() async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.grey[900],
//           title: const Text(
//             'Delete Notifications',
//             style: TextStyle(color: Colors.white),
//           ),
//           content: Text(
//             _selectedNotifications.length > 1
//                 ? 'Are you sure you want to delete ${_selectedNotifications.length} notifications?'
//                 : 'Are you sure you want to delete this notification?',
//             style: const TextStyle(color: Colors.white70),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class NotificationItem extends StatelessWidget {
//   final QueryDocumentSnapshot doc;
//   final Map<String, dynamic> data;
//   final DateTime timestamp;
//   final bool isSelectionMode;
//   final bool isSelected;
//   final bool isDeleting;
//   final Function(String) onSelect;
//   final Function(String) onLongPress;
//   final Function(String, Map<String, dynamic>) onTap;
//   final Map<String, String> timeAgoCache;
//   final Function() onDismiss;

//   const NotificationItem({
//     super.key,
//     required this.doc,
//     required this.data,
//     required this.timestamp,
//     required this.isSelectionMode,
//     required this.isSelected,
//     required this.isDeleting,
//     required this.onSelect,
//     required this.onLongPress,
//     required this.onTap,
//     required this.timeAgoCache,
//     required this.onDismiss,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final notificationId = doc.id;
//     final cachedTimeAgo = timeAgoCache.putIfAbsent(
//       notificationId,
//       () => timeAgo(timestamp),
//     );

//     return Dismissible(
//       key: Key(doc.id),
//       direction: DismissDirection.endToStart,
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white, size: 30),
//       ),
//       confirmDismiss: (direction) async {
//         return await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               backgroundColor: Colors.grey[900],
//               title: const Text(
//                 'Delete Notification',
//                 style: TextStyle(color: Colors.white),
//               ),
//               content: const Text(
//                 'Are you sure you want to delete this notification?',
//                 style: TextStyle(color: Colors.white70),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(false),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(true),
//                   child: const Text(
//                     'Delete',
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//       onDismissed: (direction) {
//         onDismiss();
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         color: isSelected
//             ? Colors.blue.withOpacity(0.2)
//             : isDeleting
//             ? Colors.red.withOpacity(0.1)
//             : Colors.transparent,
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onLongPress: () => onLongPress(doc.id),
//             onTap: () => onTap(doc.id, data),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 vertical: 12.0,
//                 horizontal: 16.0,
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildProfileAvatar(data),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildNotificationTitle(data),
//                         const SizedBox(height: 4),
//                         Text(
//                           cachedTimeAgo,
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildNotificationTrailing(data, doc.id),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileAvatar(Map<String, dynamic> data) {
//     return GestureDetector(
//       onTap: () {
//         if (data['senderId'] != null) {
//           Get.to(() => ProfileScreen(userId: data['senderId']));
//         }
//       },
//       child: Stack(
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: data['type'] == 'follow'
//                     ? Colors.blue
//                     : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//             child: ClipOval(
//               child: CachedNetworkImage(
//                 imageUrl: data['senderProfileImage'] ?? '',
//                 placeholder: (context, url) => Container(
//                   color: Colors.grey[800],
//                   child: const Icon(Icons.person, color: Colors.white),
//                 ),
//                 errorWidget: (context, url, error) =>
//                     const Icon(Icons.person, color: Colors.white),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           if (data['type'] == 'follow')
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Colors.blue,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.person_add,
//                   size: 12,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           if (isDeleting)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.5),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Center(
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     strokeWidth: 2,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationTitle(Map<String, dynamic> data) {
//     return RichText(
//       text: TextSpan(
//         style: const TextStyle(fontSize: 14, color: Colors.white),
//         children: [
//           TextSpan(
//             text: data['senderName'] ?? 'Unknown User',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           TextSpan(text: ' ${_getNotificationText(data['type'])}'),
//           if (data['type'] == 'comment' && data['commentText'] != null)
//             TextSpan(
//               text: ': "${data['commentText']}"',
//               style: const TextStyle(fontStyle: FontStyle.italic),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationTrailing(Map<String, dynamic> data, String docId) {
//     if (isSelectionMode) {
//       return Checkbox(
//         value: isSelected,
//         onChanged: (value) => onSelect(docId),
//         fillColor: MaterialStateProperty.all(Colors.blue),
//       );
//     } else {
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (data['read'] == false)
//             Container(
//               width: 10,
//               height: 10,
//               decoration: const BoxDecoration(
//                 color: Colors.blue,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           const SizedBox(height: 4),
//         ],
//       );
//     }
//   }

//   String _getNotificationText(String type) {
//     switch (type) {
//       case 'like':
//         return 'liked your video...❤';
//       case 'comment':
//         return 'commented on your video...💬';
//       case 'share':
//         return 'shared your video';
//       case 'follow':
//         return 'started following you';
//       default:
//         return 'interacted with your content';
//     }
//   }
// }
