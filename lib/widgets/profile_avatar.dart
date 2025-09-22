import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok/authentication/authentication_controller.dart';
import 'package:tiktok/utils/constants.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.radius = 60, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthenticationController>(
      builder: (authController) {
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              CircleAvatar(
                radius: radius,
                backgroundColor: AppColors.cardBackground,
                backgroundImage: authController.profileImage != null
                    ? FileImage(authController.profileImage!)
                    : const AssetImage("assets/images/default_avatar.png")
                          as ImageProvider,
                child: authController.profileImage == null
                    ? Icon(
                        Icons.person,
                        size: radius,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
