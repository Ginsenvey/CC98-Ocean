import 'package:cc98_ocean/controls/fluent_dialog.dart';
import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class PageBar extends StatelessWidget {
  final int currentPage;      // 1-based
  final int totalPages;       // 1-based
  final ValueChanged<int> onJump; // 外部只需 setState(newPage)

  const PageBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 6,
      children: [
        // 第一页
        FluentIconbutton(icon: FluentIcons.previous_16_regular,onPressed: currentPage == 1 ? null : () => onJump(1)),
        // 上一页
        FluentIconbutton(
          icon: FluentIcons.chevron_left_16_regular,
          onPressed: currentPage == 1 ? null : () => onJump(currentPage-1),
        ),

        // 中间 「当前页/总页」 按钮（可点击弹窗）
        TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () async {
            final newPage = await _showJumpDialog(context, currentPage, totalPages);
            if (newPage != null && newPage >= 1 && newPage <= totalPages) {
              onJump(newPage);
            }
          },
          
          child: Text('$currentPage/$totalPages',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),

        // 下一页
        FluentIconbutton(
          icon: FluentIcons.chevron_right_16_regular,
          onPressed: currentPage == totalPages ? null : () => onJump(currentPage + 1),
        ),
        // 末页
        FluentIconbutton(
          icon: FluentIcons.next_16_regular,
          onPressed: currentPage== totalPages ? null : () => onJump(totalPages),
        ),
      ],
    );
  }
}

Future<int?> _showJumpDialog(
  BuildContext context,
  int current,
  int total,
) async {
  final ctl = TextEditingController(text: current.toString());
  return showDialog<int>(
    context: context,
    builder: (_) => FluentDialog(
      title: "输入目的地",
      content:  TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey),
          hintText: '1 - $total',
          suffixText: '/$total',
        ),
        onSubmitted: (_) => Navigator.pop(context, int.tryParse(ctl.text)),
      ),
      confirmText: "Go",
      cancelText: "取消",
      onConfirm: () {
        Navigator.pop(context, int.tryParse(ctl.text));
      },
      )
  );
}