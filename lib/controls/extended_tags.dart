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
  HeightLimitedImgTag() : super("img");

  @override
  List<InlineSpan> parse(FlutterRenderer renderer, bbob.Element element) {
    if (element.children.isEmpty) {
      return [TextSpan(text: "[$tag]")];
    }

    // Image URL is the first child / node. If not, that's an issue for the person writing
    // the BBCode.
    String imageUrl = element.children.first.textContent;

    final image = Image.network(imageUrl,
        height: 100,
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