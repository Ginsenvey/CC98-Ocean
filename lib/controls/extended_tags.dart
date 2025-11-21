import 'dart:developer';

import 'package:bbob_dart/bbob_dart.dart' as bbob;
import 'package:cc98_ocean/controls/audio_player.dart';
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
    //final text=Text("点击播放音频",style: TextStyle(color: Colors.blue,decoration: TextDecoration.underline),);
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

    final image = Image.network(imageUrl,
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
        decoration: TextDecoration.underline, color: Colors.blue);
  }
}
class EmojiTag extends AdvancedTag {
  EmojiTag() : super("emoji");

  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }
    String path = element.children.first.textContent;
    final image = Image.asset(path,
        errorBuilder: (context, error, stack) => Image.asset(path.replaceAll("png", "gif"),
        errorBuilder: (context, error, stack) => Text("[$tag]")));

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