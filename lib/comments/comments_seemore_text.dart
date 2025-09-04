import 'package:flutter/material.dart';

class SeeMoreText extends StatefulWidget {
  final String text;
  final int maxLength;
  final TextStyle? textStyle;
  final TextStyle? seeMoreStyle;

  // ignore: use_super_parameters
  const SeeMoreText({
    Key? key,
    required this.text,
    this.maxLength = 100,
    this.textStyle,
    this.seeMoreStyle,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SeeMoreTextState createState() => _SeeMoreTextState();
}

class _SeeMoreTextState extends State<SeeMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(color: Colors.white);
    final defaultSeeMoreStyle = TextStyle(color: Colors.grey);

    if (widget.text.length <= widget.maxLength) {
      return Text(widget.text, style: widget.textStyle ?? defaultTextStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpanded
              ? widget.text
              // ignore: prefer_interpolation_to_compose_strings
              : widget.text.substring(0, widget.maxLength) + '...',
          style: widget.textStyle ?? defaultTextStyle,
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'See less' : 'See more',
            style: widget.seeMoreStyle ?? defaultSeeMoreStyle,
          ),
        ),
      ],
    );
  }
}
