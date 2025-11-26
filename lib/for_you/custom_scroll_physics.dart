import 'package:flutter/material.dart';

class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({super.parent});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 1.0, stiffness: 60, damping: 11);
}

// import 'package:flutter/material.dart';

// /// 🎯 Instagram/TikTok-like smooth page scrolling physics
// class InstagramScrollPhysics extends ScrollPhysics {
//   const InstagramScrollPhysics({super.parent});

//   @override
//   InstagramScrollPhysics applyTo(ScrollPhysics? ancestor) {
//     return InstagramScrollPhysics(parent: buildParent(ancestor));
//   }

//   /// Controls how “bouncy” or “tight” the scroll feels at the edge
//   @override
//   double applyBoundaryConditions(ScrollMetrics position, double value) {
//     // Prevent overscroll glow (like TikTok)
//     if (value < position.pixels &&
//         position.pixels <= position.minScrollExtent) {
//       return value - position.pixels;
//     } else if (value > position.pixels &&
//         position.pixels >= position.maxScrollExtent) {
//       return value - position.pixels;
//     }
//     return 0.0;
//   }

//   /// This creates that "snap to page" momentum
//   @override
//   Simulation? createBallisticSimulation(
//     ScrollMetrics position,
//     double velocity,
//   ) {
//     // When user lifts their finger
//     if ((velocity.abs() < 50) ||
//         (position.pixels <= position.minScrollExtent) ||
//         (position.pixels >= position.maxScrollExtent)) {
//       return super.createBallisticSimulation(position, velocity);
//     }

//     final double targetPixels = _getTargetPixels(
//       position,
//       velocity,
//     ); // Snap target
//     if (targetPixels != position.pixels) {
//       return ScrollSpringSimulation(
//         spring,
//         position.pixels,
//         targetPixels,
//         velocity,
//         tolerance: tolerance,
//       );
//     }

//     return null;
//   }

//   /// Defines the natural “feel” of the physics
//   @override
//   SpringDescription get spring =>
//       const SpringDescription(mass: 1.0, stiffness: 60, damping: 11);

//   /// Makes sure scroll snaps to the nearest full page
//   double _getTargetPixels(ScrollMetrics position, double velocity) {
//     final double page = position.pixels / position.viewportDimension;

//     // If velocity > 0 → go to next page; < 0 → go to previous page
//     double targetPage;
//     if (velocity > 500) {
//       targetPage = page.ceilToDouble();
//     } else if (velocity < -500) {
//       targetPage = page.floorToDouble();
//     } else {
//       targetPage = page.roundToDouble();
//     }

//     return targetPage * position.viewportDimension;
//   }

//   /// Controls sensitivity to drag speed (lower = slower scroll)
//   @override
//   double get dragStartDistanceMotionThreshold => 3.5;
// }
