import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';

import 'abstract_web_player.dart';

/// Web Player
class WebPlayerHtml extends WebPlayer {
  @override
  WebPlayerHtml({MethodChannel channel}) : super(channel: channel);

  StreamSubscription _onEndListener;
  StreamSubscription _onCanPlayListener;

  void _clearListeners() {
    _onEndListener?.cancel();
    _onCanPlayListener?.cancel();
  }

  html.AudioElement _audioElement;

  @override
  get volume => _audioElement?.volume ?? 1.0;

  @override
  set volume(double volume) {
    _audioElement?.volume = volume;
    channel.invokeMethod(WebPlayer.methodVolume, volume);
  }

  @override
  get playSpeed => _audioElement?.playbackRate ?? 1.0;

  @override
  set playSpeed(double playSpeed) {
    _audioElement?.playbackRate = playSpeed;
    channel.invokeMethod(WebPlayer.methodPlaySpeed, playSpeed);
  }

  bool _isPlaying = false;

  @override
  get isPlaying => _isPlaying;

  @override
  set isPlaying(bool value) {
    _isPlaying = value;
    channel.invokeMethod(WebPlayer.methodIsPlaying, value);
    if (value) {
      _listenPosition();
    } else {
      _stopListenPosition();
    }
  }

  @override
  double get currentPosition => _audioElement.currentTime;

  var __listenPosition = false;

  double _durationMs;
  double _position;

  void _listenPosition() async {
    __listenPosition = true;
    Future.doWhile(() {
      final durationMs = _audioElement.duration * 1000;
      if (durationMs != _durationMs) {
        _durationMs = durationMs;
        channel.invokeMethod(
            WebPlayer.methodCurrent, {"totalDurationMs": durationMs});
      }

      if (_position != currentPosition) {
        _position = currentPosition;
        final positionMs = currentPosition * 1000;
        channel.invokeMethod(WebPlayer.methodPosition, positionMs);
      }
      return Future.delayed(Duration(milliseconds: 200)).then((value) {
        return __listenPosition;
      });
    });
  }

  void _stopListenPosition() {
    __listenPosition = false;
  }

  @override
  void play() {
    if (_audioElement != null) {
      isPlaying = true;
      forwardHandler?.stop();
      _audioElement.play();
    }
  }

  @override
  void pause() {
    if (_audioElement != null) {
      isPlaying = false;
      forwardHandler?.stop();
      _audioElement.pause();
    }
  }

  @override
  void stop() {
    forwardHandler?.stop();
    forwardHandler = null;

    _clearListeners();

    if (_audioElement != null) {
      isPlaying = false;
      pause();
      _audioElement.currentTime = 0;
      channel.invokeMethod(WebPlayer.methodPosition, 0);
    }
  }

  @override
  Future<void> open({
    String path,
    String audioType,
    double volume,
    double seek,
    bool autoStart,
    double playSpeed,
    Map networkHeaders,
  }) async {
    stop();
    _durationMs = null;
    _position = null;
    _audioElement = html.AudioElement(findAssetPath(path, audioType));

    //it seems html audielement cannot take networkHeaders :'(

    _onEndListener = _audioElement.onEnded.listen((event) {
      channel.invokeMethod(WebPlayer.methodFinished, true);
    });
    _onCanPlayListener = _audioElement.onCanPlay.listen((event) {
      if (autoStart) {
        play();
      }
      this.volume = volume;

      final durationMs = _audioElement.duration * 1000;
      if (durationMs != _durationMs) {
        _durationMs = durationMs;
        channel.invokeMethod(
            WebPlayer.methodCurrent, {"totalDurationMs": durationMs});
      }

      if (seek != null) {
        this.seek(to: seek);
      }

      if (playSpeed != null) {
        this.playSpeed(playSpeed);
      }

      //single event
      _onCanPlayListener?.cancel();
      _onCanPlayListener = null;
    });
  }

  @override
  void seek({double to}) {
    print("Final Seeking To $to from ${_audioElement.currentTime}");
    if (_audioElement != null && to != null) {
      /// Explainer on the `/1000`
      /// The value being sent down from the plugin
      /// is in `milliseconds` and `AudioElement` uses seconds.
      /// This is to convert it.
      double toInSeconds = to / 1000;
      _audioElement?.currentTime = toInSeconds;
    }
  }

  @override
  void loopSingleAudio(bool loop) {
    _audioElement?.loop = loop;
  }

  void seekBy({double by}) {
    final current = currentPosition;
    final to = current + by;
    seek(to: to);
  }

  ForwardHandler forwardHandler;
  @override
  void forwardRewind(double speed) {
    pause();
    channel.invokeMethod(WebPlayer.methodForwardRewindSpeed, speed);
    if (forwardHandler != null) {
      forwardHandler.stop();
    }
    forwardHandler = ForwardHandler();
    _listenPosition(); //for this usecase, enable listen position
    forwardHandler.start(this, speed);
  }
}

class ForwardHandler {
  bool _isEnabled = false;
  static final _timelapse = 300;

  void start(WebPlayerHtml player, double speed) async {
    _isEnabled = true;
    while (_isEnabled) {
      player.seekBy(by: speed * _timelapse);
      await Future.delayed(Duration(milliseconds: _timelapse));
    }
  }

  void stop() {
    _isEnabled = false;
  }
}
