import 'dart:ui';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:flutter/material.dart';

///浮动提示组件。
class InfoFlower{
  ///呈现图标和文字
  static void show(
  BuildContext context, {
  required IconData icon,
  required String text,
  Duration showFor = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => AcrylicToast(
      entry: entry,
      showFor: showFor,
      text: text,
      icon: icon,
    ),
  );
  overlay.insert(entry);
}
  ///呈现自定义内容
  static void showContent(
  BuildContext context, {
  required Widget child,
  Duration showFor = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => AcrylicToast.custom(
      entry: entry,
      showFor: showFor,
      child: child,
    ),
  );
  overlay.insert(entry);
}
}


class AcrylicToast extends StatefulWidget {
  final IconData? icon;
  final OverlayEntry entry;
  final String? text;
  final Widget? customChild;
  final Duration showFor;

  const AcrylicToast({
    required this.entry,
    this.icon,
    this.text,
    this.customChild,
    required this.showFor,
  });

  factory AcrylicToast.custom({
    required OverlayEntry entry, 
    required Widget child,
    required Duration showFor,
  }) =>
      AcrylicToast(entry:entry,customChild: child, showFor: showFor);

  @override
  State<AcrylicToast> createState() => _AcrylicToastState();
}

class _AcrylicToastState extends State<AcrylicToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _anim;

  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<Offset>(begin: const Offset(0, 2), end: Offset.zero)
        .animate(CurveTween(curve: Curves.easeOutBack).animate(_ctrl));
    _ctrl.forward();

    Future.delayed(widget.showFor, _remove);
  }

  void _remove() {
    _ctrl.reverse().whenComplete(() => widget.entry.remove());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.customChild ??
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (widget.icon != null) Icon(widget.icon!),
          if (widget.icon != null && widget.text != null)
            const SizedBox(width: 12),
          if (widget.text != null) Flexible(child: Text(widget.text!)),
        ]);


return Positioned(
  left: 30,
  right: 30,
  bottom: 100,
  child: SlideTransition(
    position: _anim,
    child: ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(8),
      child: Material(
        color:  Colors.white.withOpacity(0.15),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:ColorTokens.softBlue.withOpacity(0.05),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
            // 内容
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              alignment: Alignment.center,
              child: child,
            ),
          ],
        ),
      ),
    ),
  ),
);

  }

}