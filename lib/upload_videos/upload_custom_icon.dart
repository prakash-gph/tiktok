import 'package:flutter/material.dart';

class UploadCustomIcon extends StatelessWidget {
  const UploadCustomIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45, // slightly wider for TikTok-style proportions
      height: 32, // taller but still safe from overflow
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left pink block
          Positioned(
            left: 5,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFA2D6C),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Right blue block
          Positioned(
            right: 5,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF18CEE7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Center white box (main button)
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ],
      ),
    );
  }
}
