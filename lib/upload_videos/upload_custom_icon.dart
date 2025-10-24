// import 'package:flutter/material.dart';

// class UploadCustomIcon extends StatelessWidget {
//   const UploadCustomIcon({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 45,
//       height: 25,
//       child: Stack(
//         children: [
//           Container(
//             margin: const EdgeInsets.only(left: 12),
//             width: 36,
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 250, 45, 108),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),

//           Container(
//             margin: const EdgeInsets.only(right: 12),
//             width: 36,
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 24, 206, 231),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),

//           Center(
//             child: Container(
//               height: double.infinity,
//               width: 38,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//               ),

//               child: const Icon(Icons.add, color: Colors.black, size: 25),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class UploadCustomIcon extends StatelessWidget {
  const UploadCustomIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center, //  ensures perfect vertical centering
      height: 28, //  slightly taller for symmetry
      width: 34, //  proportional width
      child: Stack(
        alignment: Alignment.center, // centers all layers
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFA2D6C),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF18CEE7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.black,
              size: 26, //  matches your other icons better
            ),
          ),
        ],
      ),
    );
  }
}
