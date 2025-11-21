import 'package:media_kit/media_kit.dart';                     
import 'package:media_kit_video/media_kit_video.dart'; 
import 'package:flutter/material.dart';
class VideoFrame extends StatefulWidget {
  final String videoUrl;
  const VideoFrame({Key? key,required this.videoUrl}) : super(key: key);
  @override
  State<VideoFrame> createState() => VideoFrameState();
}

class VideoFrameState extends State<VideoFrame> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.videoUrl),play: false);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width:MediaQuery.of(context).size.width,
          height:MediaQuery.of(context).size.width * 9.0 / 16.0,
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(6),
            child: Video(controller: controller)),
        ),
      ),
    );
  }
}