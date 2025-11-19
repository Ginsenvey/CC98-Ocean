import 'dart:async';

import 'package:cc98_ocean/controls/fluent_iconbutton.dart';
import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
  late StreamSubscription<PlayerState> _stateSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
  // 1. 保存订阅对象
  _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
    if (mounted) setState(() => _playerState = state);
  });

  _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
    if (mounted) setState(() => _duration = d);
  });

  _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
    if (mounted) setState(() => _position = p);
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
    _stateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ColorTokens.dividerBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 播放控制按钮
            FluentIconbutton(
              icon: _playerState == PlayerState.playing 
                  ? FluentIcons.pause_16_regular : FluentIcons.play_16_regular,
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
              style: TextStyle(color: ColorTokens.primaryLight),
            ),
          ],
        ),
      ),
    );
  }
}



