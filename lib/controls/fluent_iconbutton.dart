import 'package:flutter/material.dart';

/// 图标按钮
class FluentIconbutton extends StatelessWidget {
  final VoidCallback? onPressed;  // 点击事件       // 背景颜色
  final Color? iconColor;         // 图标颜色
  final IconData icon;
             // 子组件

  const FluentIconbutton({
    super.key,
    this.onPressed,
    this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
            onPressed:()=>{onPressed?.call()}, 
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              fixedSize: const Size.square(32),
              minimumSize: Size(32,32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Icon(icon,color: iconColor));
  }
}