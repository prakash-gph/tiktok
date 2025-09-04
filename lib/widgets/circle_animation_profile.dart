import 'package:flutter/material.dart';

class CircleAnimationProfile extends StatefulWidget {
  final Widget child;

  const CircleAnimationProfile({super.key, required this.child});

  @override
  State<CircleAnimationProfile> createState() => _CircleAnimationProfileState();
}

class _CircleAnimationProfileState extends State<CircleAnimationProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    controller.forward();
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(controller),
      child: widget.child,
    );
  }
}
