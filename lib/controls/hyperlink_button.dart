import 'package:flutter/material.dart';

/// 迷你圆角文字按钮
/// 对外公开 3 个常用参数，其余样式固定
class HyperlinkButton extends StatelessWidget {
  final VoidCallback? onPressed;  // 点击事件       // 背景颜色
  final Color? iconColor;         // 图标颜色
  final Widget child;        
  final Size?  size;  // 子组件

  const HyperlinkButton({
    super.key,
    this.onPressed,
    this.iconColor,
    required this.child,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        minimumSize: const Size(32, 32),
        fixedSize: size,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center, 
        iconColor: iconColor,
      ),  
      child: child,
    );
  }
}