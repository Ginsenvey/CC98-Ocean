import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ExpandButton extends StatefulWidget {
  final bool initialExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Color? color;
  final double iconSize;
  final double padding;

  const ExpandButton({
    super.key,
    this.initialExpanded = false,
    this.onExpansionChanged,
    this.color,
    this.iconSize = 20,
    this.padding = 8,
  });

  @override
  State<ExpandButton> createState() => _ExpandButtonState();
}

class _ExpandButtonState extends State<ExpandButton>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotation = Tween<double>(
            begin: 0, end:-90)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (!_isExpanded) _controller.value = 1; // 初始朝右
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.reverse() : _controller.forward();
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              fixedSize: const Size.square(32),
              minimumSize: Size(32,32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
      onPressed: _toggle,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, __) => Transform.rotate(
          angle: _rotation.value * 3.1415926 / 180,
          child: Icon(
            FluentIcons.chevron_down_16_regular,
            size: widget.iconSize,
            color: widget.color ?? theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}