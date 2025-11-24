import 'dart:ui';

import 'package:cc98_ocean/core/kernel.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


///带有webvpn封装的图片源
class SmartNetworkImage extends ImageProvider<SmartNetworkImage> {
  final String url;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const SmartNetworkImage(this.url, {this.memCacheWidth, this.memCacheHeight});


  Future<Uint8List> _loadBytes() async {
    final res = await Connector().get(url); // ← 想怎么下就怎么下
    if (res.statusCode != 200) throw Exception('${res.statusCode}');
    return res.bodyBytes;
  }

  @override
  ImageStreamCompleter loadImage(
      SmartNetworkImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadBytes()
          .then((bytes) async => decode(await ImmutableBuffer.fromUint8List(bytes))),
      scale: 1.0,
      informationCollector: () => [
        DiagnosticsProperty('SmartNetworkImage', url),
      ],
    );
  }

  @override
  Future<SmartNetworkImage> obtainKey(ImageConfiguration cfg) => SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartNetworkImage && url == other.url;

  @override
  int get hashCode => url.hashCode;
}