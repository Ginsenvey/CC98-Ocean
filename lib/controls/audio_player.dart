import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
///定义了音频播放组件
///
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
    // 监听音频状态变化
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _playerState = state);
    });

    // 监听音频时长
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    // 监听播放进度
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });
  }

  Future<void> _playPause() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 播放控制按钮
          IconButton(
            icon: Icon(
              _playerState == PlayerState.playing 
                ? Icons.pause : Icons.play_arrow,
              size: 36,
            ),
            onPressed: _playPause,
          ),
          
          // 进度条
          Slider(
            min: 0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.toDouble(),
            onChanged: (value) async {
              await _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          
          // 时间显示
          Text(
            "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}"
            " / "
            "${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}",
          ),
        ],
      ),
    );
  }
}



