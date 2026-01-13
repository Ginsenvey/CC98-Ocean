import 'package:flutter/material.dart';

class AdaptiveScrollView extends StatelessWidget {
  final Widget child;
  final double maxHeight;
  final Axis scrollDirection;
  
  const AdaptiveScrollView({
    required this.child,
    this.maxHeight = 300,
    this.scrollDirection = Axis.vertical,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxHeight = maxHeight.clamp(
          0, 
          constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity
        ).toDouble();
        return SingleChildScrollView(
          scrollDirection: scrollDirection,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 0,
              maxHeight: effectiveMaxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

