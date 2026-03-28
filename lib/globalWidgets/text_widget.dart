import 'package:flutter/material.dart';

class ReusableTextWidget extends StatelessWidget {
  final String text;
  final double? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextDecoration? isUnderText;
  final TextOverflow? overflow;

  const ReusableTextWidget({
    super.key,
    required this.text,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.textAlign,
    this.maxLines,
    this.isUnderText,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: fontSize ?? 11,
          decoration: isUnderText,
          fontFamily: fontFamily ?? 'Raleway',
          fontWeight: fontWeight ?? FontWeight.normal,
          fontStyle: fontStyle ?? FontStyle.normal,
          color: color,
          overflow: overflow ?? TextOverflow.ellipsis),
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
