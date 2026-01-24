import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class SimpleCapsuleSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String)? onSubmitted;
  final TextEditingController? controller;

  const SimpleCapsuleSearchBar({
    super.key,
    this.hintText = '搜索',
    this.onSubmitted,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,  // 固定高度
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          // 搜索图标 - 垂直居中
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
            child: Icon(
              FluentIcons.search_16_regular, 
              size: 20.0, 
              color: Colors.grey,
            ),
          ),
          
          // 输入框 - 使用 Expanded 确保宽度
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,  // 左侧对齐
              child: Container(
                height: 40.0,  // 与容器高度一致
                alignment: Alignment.centerLeft,  // 内容垂直居中
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16.0,
                    height: 1.0,  // 设置行高为1，避免文字偏移
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 16.0,
                      height: 1.0,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,  // 移除内边距
                    isDense: true,  // 紧凑模式
                    isCollapsed: true,  // 收起模式，更好的垂直控制
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ),
          
          // Go按钮 - 垂直居中
          if (onSubmitted != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 8.0),
              child: Container(
                height: 32.0,  // 按钮高度
                alignment: Alignment.center,  // 按钮内文字垂直居中
                child: GestureDetector(
                  onTap: () {
                    if (controller != null) {
                      onSubmitted!(controller!.text);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Text(
                      '搜索',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 12.0,
                        height: 1.0,  // 文字行高
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}