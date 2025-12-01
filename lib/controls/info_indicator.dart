import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:flutter/material.dart';

class ErrorIndicator extends StatefulWidget {
  final VoidCallback? onTapped;
  final String info;
  final IconData icon;
  const ErrorIndicator({super.key, this.onTapped, required this.icon,required this.info});

  
  
  @override
  State<ErrorIndicator> createState()=>_ErrorIndicatorState();
}

class _ErrorIndicatorState extends State<ErrorIndicator> with SingleTickerProviderStateMixin{
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _scale = TweenSequence<double>([
      // 先缩小
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      // 过冲放大
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 40),
      // 回弹到原尺寸
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut));
  }
  
  @override
  Widget build(Object context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_){ 
          _ctrl.forward(from: 0);}, 
        onTap: widget.onTapped,
        child: AnimatedBuilder(
          animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
          child: Card(
            elevation: 0,
            color: ColorTokens.softPurple.withAlpha(100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
            child: SizedBox.square(
              dimension: 160,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 64, color: ColorTokens.primaryLight),
                    const SizedBox(height: 16),
                    Text(widget.info),
                    const SizedBox(height: 8),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}