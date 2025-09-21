import 'package:flutter/material.dart';

class ClickArea extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const ClickArea({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(          // 可选：让鼠标变成手型
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,            // 只写它 → 无波纹
        behavior: HitTestBehavior.opaque, // 整片区域可点
        child: child,
      ),
    );
  }
}