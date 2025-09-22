import 'package:flutter/material.dart';
import 'package:tiktok/utils/constants.dart';

class AppProgressIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const AppProgressIndicator({
    super.key,
    this.size = 40,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 3,
      ),
    );
  }
}
