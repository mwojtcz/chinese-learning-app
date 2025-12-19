import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

/// Widget that displays Chinese characters based on user preference (simplified/traditional)
class ChineseText extends StatelessWidget {
  final String simplified;
  final String? traditional;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ChineseText(
    this.simplified, {
    this.traditional,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: traditionalChineseNotifier,
      builder: (context, useTraditional, child) {
        final displayText = useTraditional && traditional != null && traditional != simplified
            ? traditional!
            : simplified;
        
        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
