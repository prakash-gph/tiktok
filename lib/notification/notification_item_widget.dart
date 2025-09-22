// // lib/notifications/widgets/notification_item.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/comments/comments_screen.dart';
// import 'package:tiktok/notification/notification_controller.dart';
// import 'package:tiktok/notification/notification_model.dart';
// import 'package:tiktok/profile/profile_screen.dart';

// class NotificationItem extends StatelessWidget {
//   final NotificationModel notification;
//   final NotificationController controller = Get.find<NotificationController>();

//   NotificationItem({Key? key, required this.notification}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: Key(notification.id),
//       direction: DismissDirection.endToStart,
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       onDismissed: (direction) {
//         controller.deleteNotification(notification.id);
//       },
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundImage: NetworkImage(notification.sourceUserProfileImage),
//         ),
//         title: Text(
//           notification.message,
//           style: TextStyle(
//             fontWeight: notification.isRead
//                 ? FontWeight.normal
//                 : FontWeight.bold,
//           ),
//         ),
//         // subtitle: Text(
//         //   timeago.format(notification.createdAt),
//         //   style: const TextStyle(fontSize: 12),
//         // ),
//         trailing: notification.isRead
//             ? null
//             : const Icon(Icons.circle, size: 10, color: Colors.blue),
//         onTap: () {
//           if (!notification.isRead) {
//             controller.markAsRead(notification.id);
//           }

//           // Navigate based on notification type
//           if (notification.type == 'like' || notification.type == 'comment') {
//             Get.to(() => CommentsScreen(videoId: notification.postId!, videoOwnerId: '',));
//           } else if (notification.type == 'follow') {
//             Get.to(() => ProfileScreen(userId: notification.sourceUserId));
//           }
//         },
//       ),
//     );
//   }
// }
