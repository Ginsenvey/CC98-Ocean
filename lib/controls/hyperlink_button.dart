import 'package:flutter/material.dart';

/// 迷你圆角文字按钮
/// 对外公开 3 个常用参数，其余样式固定
class HyperlinkButton extends StatelessWidget {
  final VoidCallback? onPressed;  // 点击事件       // 背景颜色
  final Color? iconColor;         // 图标颜色
  final Widget child;             // 子组件

  const HyperlinkButton({
    super.key,
    this.onPressed,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        padding: const EdgeInsets.all(5),
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center, 
        iconColor: iconColor,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return Colors.grey[300];
      if (states.contains(WidgetState.pressed)) return Colors.grey[400];
      return Colors.transparent;                                     // 常态
    }),
      ),
      child: child,
    );
  }
}