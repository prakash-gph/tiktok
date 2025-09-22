// // lib/notifications/widgets/notification_badge.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tiktok/notification/notification_controller.dart';

// class NotificationBadge extends StatelessWidget {
//   final NotificationController controller = Get.find<NotificationController>();
//   final VoidCallback onPressed;

//   NotificationBadge({Key? key, required this.onPressed}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Obx(
//       () => Stack(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: onPressed,
//           ),
//           if (controller.unreadCount.value > 0)
//             Positioned(
//               right: 8,
//               top: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                 child: Text(
//                   controller.unreadCount.value > 99
//                       ? '99+'
//                       : controller.unreadCount.value.toString(),
//                   style: const TextStyle(color: Colors.white, fontSize: 10),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
