// import 'package:flutter/material.dart';

// class InputTextWidget extends StatelessWidget {
//   final TextEditingController textEditingController;
//   final IconData? iconData;
//   final String? assetRefrence;
//   final String lableStringe;
//   final bool isObscure;

//   const InputTextWidget({
//     super.key,
//     required this.textEditingController,
//     this.iconData,
//     this.assetRefrence,
//     required this.lableStringe,
//     required this.isObscure,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: textEditingController,
//       decoration: InputDecoration(
//         labelText: lableStringe,
//         prefixIcon: iconData != null
//             ? Icon(iconData)
//             : Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Image.asset(assetRefrence!, width: 10),
//               ),
//         labelStyle: const TextStyle(fontSize: 20),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(7),
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(7),
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//       ),
//       style: TextStyle(fontSize: 25),
//       obscureText: isObscure,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:tiktok/utils/constants.dart';

class InputTextWidget extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? assetIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autoFocus;
  final bool enabled;
  const InputTextWidget({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.assetIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autoFocus = false,
    this.enabled = true,

    required bool isObscure,
  });

  @override
  State<InputTextWidget> createState() => _InputTextWidgetState();
}

class _InputTextWidgetState extends State<InputTextWidget> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      // obscureText: widget.obscureText && _obscureText,
      obscureText: widget.obscureText ? _obscureText : false,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autoFocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: AppTextStyles.bodyText1,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: AppColors.textSecondary)
            : (widget.assetIcon != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        widget.assetIcon!,
                        width: 20,
                        height: 20,
                      ),
                    )
                  : null),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
