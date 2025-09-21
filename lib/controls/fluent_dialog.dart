import 'package:flutter/material.dart';

/// 通用 AlertDialog 封装
/// 示例：
/// showDialog(context: context, builder: (_) => CustomAlert(
///         title: '确认删除',
///         content: '删除后无法恢复，是否继续？',
///         confirmText: '删除',
///         onConfirm: () => delete(),
///       ));
class FluentDialog extends StatelessWidget {
  final String title;
  final Widget? content; // 任意组件
  final String? cancelText;
  final String? confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const FluentDialog({
    super.key,
    required this.title,
    this.content,
    this.cancelText = '取消',
    this.confirmText = '确定',
    this.onCancel,
    this.onConfirm,
  });

  /// 快速创建「纯文本内容」
  factory FluentDialog.text({
    Key? key,
    required String title,
    required Widget content,
    required String cancelText,
    required String confirmText,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  }) =>
      FluentDialog(
        key: key,
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: onCancel,
        onConfirm: onConfirm,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(title),
        content: content,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(4),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
       minimumSize: const Size(0, 0),
     ),
     //此处需要调用回调函数，而不是函数对象。
            onPressed: () {
              if (onCancel != null) {
                onCancel!();
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(cancelText??"取消"),
          ),
          TextButton(
            style: TextButton.styleFrom(
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(4),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
       minimumSize: const Size(0, 0),
     ),
            onPressed: () {
              if (onConfirm != null) {
                onConfirm!();
              } else {
                Navigator.pop(context);
              }
            },
            
            child: Text(confirmText??'退出'),
          ),
        ],
      );
      
  }
}