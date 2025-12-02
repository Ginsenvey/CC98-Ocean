import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdaptiveDivider extends StatelessWidget {
  const AdaptiveDivider({super.key});

  static const double _thinThickness = 1;
  static const double _thickThickness = 6;

  //厚度判定
  @visibleForTesting
  static double thicknessFor(BuildContext context) {
    if (kIsWeb) return _thinThickness;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _thinThickness;
    }
    return _thickThickness;
  }

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,                 
      thickness: thicknessFor(context),
      color: Theme.of(context).dividerColor, // 响应主题更改
    );
  }
  
}