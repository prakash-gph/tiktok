// import 'package:flutter/material.dart';
// import 'package:tiktok/videos_upload/screens/upload_screen.dart';
// import 'camera_screen.dart';

// class CameraHomeScreen extends StatelessWidget {
//   const CameraHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = Theme.of(context).colorScheme.primary;
//     final Color surfaceColor = Theme.of(context).colorScheme.surface;
//     final Color onSurface = Theme.of(context).colorScheme.onSurface;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Create Reel',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//       ),
//       body: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Theme.of(context).colorScheme.background,
//               Theme.of(context).colorScheme.surface.withOpacity(0.7),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Visual Header
//                 Icon(
//                   Icons.video_camera_back_rounded,
//                   size: 80,
//                   color: primaryColor,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Share your story with the world',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: onSurface.withOpacity(0.8),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 50),

//                 // Record Video Button
//                 _buildActionButton(
//                   context: context,
//                   icon: Icons.videocam_rounded,
//                   title: 'Record Video',
//                   subtitle: 'Create a new video with camera',
//                   onPressed: () =>
//                       _navigateToScreen(context, const CameraScreen()),
//                   primaryColor: primaryColor,
//                   surfaceColor: surfaceColor,
//                 ),
//                 const SizedBox(height: 20),

//                 //Upload Video Button
//                 _buildActionButton(
//                   context: context,
//                   icon: Icons.upload_rounded,
//                   title: 'Upload Video',
//                   subtitle: 'Choose from your gallery',
//                   onPressed: () =>
//                       _navigateToScreen(context, const UploadScreen()),
//                   primaryColor: primaryColor,
//                   surfaceColor: surfaceColor,
//                 ),

//                 // Spacer to push content up
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onPressed,
//     required Color primaryColor,
//     required Color surfaceColor,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       child: Material(
//         borderRadius: BorderRadius.circular(16),
//         color: surfaceColor,
//         elevation: 2,
//         child: InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(16),
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: primaryColor.withOpacity(0.1),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, size: 24, color: primaryColor),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.6),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios_rounded,
//                   size: 16,
//                   color: Theme.of(
//                     context,
//                   ).colorScheme.onSurface.withOpacity(0.5),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _navigateToScreen(BuildContext context, Widget screen) {
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => screen,
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(0.0, 1.0);
//           const end = Offset.zero;
//           const curve = Curves.easeInOut;
//           var tween = Tween(
//             begin: begin,
//             end: end,
//           ).chain(CurveTween(curve: curve));
//           return SlideTransition(
//             position: animation.drive(tween),
//             child: child,
//           );
//         },
//         transitionDuration: const Duration(milliseconds: 300),
//       ),
//     );
//   }
// }
