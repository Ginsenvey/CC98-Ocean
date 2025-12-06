import 'dart:developer';
import 'dart:io';

import 'package:bbob_dart/bbob_dart.dart' as bbob;
import 'package:cc98_ocean/controls/audio_player.dart';
import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:cc98_ocean/controls/image_viewer.dart';
import 'package:cc98_ocean/controls/smart_image.dart';
import 'package:cc98_ocean/controls/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bbcode/flutter_bbcode.dart';

class AudioTag extends AdvancedTag {
  AudioTag() : super("audio");

  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }

    // Audio URL is the first child / node. If not, that's an issue for the person writing
    // the BBCode.
    String audioUrl = element.children.first.textContent;

    final player=AudioPlayerWidget(audioUrl: audioUrl);
    if (renderer.peekTapAction() != null) {
      return [
        WidgetSpan(
            child: GestureDetector(
          onTap: renderer.peekTapAction(),
          child: player,
        ))
      ];
    }

    return [
      WidgetSpan(
        child: player,
      )
    ];
  }
}

class VideoTag extends AdvancedTag {
  VideoTag() : super("video");

  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }

    String videoUrl = element.children.first.textContent;

    final player=VideoFrame(videoUrl: videoUrl);
    if (renderer.peekTapAction() != null) {
      return [
        WidgetSpan(
            child: GestureDetector(
          onTap: renderer.peekTapAction(),
          child: player,
        ))
      ];
    }

    return [
      WidgetSpan(
        child: player,
      )
    ];
  }
}
class StrikeTag extends StyleTag {
  StrikeTag() : super('del');

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    return oldStyle.copyWith(decoration: TextDecoration.lineThrough);
  }
}
class HeightLimitedImgTag extends AdvancedTag {
  final double maxHeight;
  HeightLimitedImgTag({required this.maxHeight}) : super("img");
  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }

    // Image URL is the first child / node. If not, that's an issue for the person writing
    // the BBCode.
    String imageUrl = element.children.first.textContent;

    final image = Image(image: SmartNetworkImage(imageUrl),
        height: maxHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Text("[$tag]"));

    if (renderer.peekTapAction() != null) {
      return [
        WidgetSpan(
            child: GestureDetector(
          onTap: renderer.peekTapAction(),
          child: Center(child: image),
        ))
      ];
    }

    return [
      WidgetSpan(
        child: Center(child: image),
      )
    ];
  }
}

class TopicTag extends StyleTag {
  final Function(String)? onTap;
  TopicTag({this.onTap}) : super("topic");
  @override
  void onTagStart(FlutterRenderer renderer) {
    late String url;
    if (renderer.currentTag?.attributes.isNotEmpty ?? false) {
      url ="https://www.cc98.org/topic/${renderer.currentTag!.attributes.keys.first}";
    } 
    else {
      url = "URL is missing!";
    }
    renderer.pushTapAction(() {
      if (onTap == null) {
        log("URL $url has been pressed!");
        return;
      }
      onTap!(url);
    });
    super.onTagStart(renderer);
  }

  @override
  void onTagEnd(FlutterRenderer renderer) {
    renderer.popTapAction();
    super.onTagEnd(renderer);
  }

  @override
  TextStyle transformStyle(
      TextStyle oldStyle, Map<String, String>? attributes) {
    return oldStyle.copyWith(
        decoration: TextDecoration.underline, color: Color.fromARGB(255, 125, 108, 172));
  }
}

class SmartImgTag extends AdvancedTag {
  final BuildContext context;
  SmartImgTag({required this.context}) : super("img");

  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }

    // Image URL is the first child / node. If not, that's an issue for the person writing
    // the BBCode.
    String path = element.children.first.textContent;
    bool isDesktop=Platform.isWindows||Platform.isLinux||Platform.isMacOS;
    final image = path.contains("assets/images")?Image.asset(path,height: 24,fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Image.asset(path.replaceAll("png", "gif"),height: 24,fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Text("[$tag]"))):Image(image: SmartNetworkImage(path),width:isDesktop?MediaQuery.of(context).size.width/3:double.infinity,errorBuilder: (context, error, stack) => Text("[$tag]"));
    final imageWithPreviewer=ClickArea(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>ImagePreview(imageUrl: path))),child: image);
    return [
      WidgetSpan(
        child: imageWithPreviewer,
      )
    ];
  }
}