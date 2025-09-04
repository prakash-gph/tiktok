import 'package:flutter/material.dart';

class InputTextWidget extends StatelessWidget {
  final TextEditingController textEditingController;
  final IconData? iconData;
  final String? assetRefrence;
  final String lableStringe;
  final bool isObscure;

  const InputTextWidget({
    super.key,
    required this.textEditingController,
    this.iconData,
    this.assetRefrence,
    required this.lableStringe,
    required this.isObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        labelText: lableStringe,
        prefixIcon: iconData != null
            ? Icon(iconData)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetRefrence!, width: 10),
              ),
        labelStyle: const TextStyle(fontSize: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      style: TextStyle(fontSize: 25),
      obscureText: isObscure,
    );
  }
}
