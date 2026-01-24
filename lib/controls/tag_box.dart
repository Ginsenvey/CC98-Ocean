import 'package:flutter/material.dart';

/// 文字标签组件
class TextTagBox extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;

  const TextTagBox({
    super.key,
    required this.text,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
    this.textStyle,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        text,
        style: (textStyle ?? TextStyle()).copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}

