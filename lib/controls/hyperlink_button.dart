import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:flutter/material.dart';

/// 图标按钮
class HyperlinkButton extends StatelessWidget {
  final VoidCallback? onPressed;  // 点击事件       // 背景颜色
  final Color? iconColor;         // 图标颜色
  final IconData icon;
  final String text;
             // 子组件

  const HyperlinkButton({
    super.key,
    this.onPressed,
    this.iconColor,
    required this.icon,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
            onPressed:()=>{onPressed?.call()}, 
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8,vertical: 16),
              
              minimumSize: Size(32,32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                Icon(icon,color: iconColor),
                Text(text,style:TextStyle(color: ColorTokens.primaryLight,fontSize: 15))
              ],
    ));
  }
}