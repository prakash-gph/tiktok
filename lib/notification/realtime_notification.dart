// // Create a widget for the notification icon with badge
// Widget _buildNotificationIcon() {
//   return StreamBuilder(
//     stream: FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: authUserId)
//         .where('read', isEqualTo: false)
//         .snapshots(),
//     builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//       int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
      
//       return Stack(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () => Get.to(() => NotificationsScreen()),
//           ),
//           if (unreadCount > 0)
//             Positioned(
//               right: 8,
//               top: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(
//                   minWidth: 16,
//                   minHeight: 16,
//                 ),
//                 child: Text(
//                   unreadCount > 99 ? '99+' : unreadCount.toString(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       );
//     },
//   );
// }