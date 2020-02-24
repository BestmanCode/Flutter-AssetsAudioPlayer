import 'dart:async';

import 'package:assets_audio_player/playing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

import 'playing.dart';
export 'playing.dart';

import 'playable.dart';
export 'playable.dart';

/// The AssetsAudioPlayer, playing audios from assets/
/// Example :
///
///     AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
///
///     _assetsAudioPlayer.open(Audio(
///         "/assets/audio/myAudio.mp3",
///     ))
///
/// Don't forget to declare the audio folder in your `pubspec.yaml`
///
///     flutter:
///       assets:
///         - assets/audios/
///
class AssetsAudioPlayer {
  /// The channel between the native and Dart
  final MethodChannel _channel = const MethodChannel('assets_audio_player');

  /// Stores opened asset audio path to use it on the `_current` BehaviorSubject (in `PlayingAudio`)
  String _lastOpenedAssetsAudioPath;

  _CurrentPlaylist _playlist;

  ReadingPlaylist get playlist {
    if (_playlist == null) {
      return null;
    } else {
      return ReadingPlaylist(
        //immutable copy
        audios: _playlist.playlist.audios,
        currentIndex: _playlist.playlistIndex,
      );
    }
  }

  /// Then mediaplayer playing state (mutable)
  final BehaviorSubject<bool> _isPlaying = BehaviorSubject<bool>.seeded(false);

  /// Boolean observable representing the current mediaplayer playing state
  ///
  /// retrieve directly the current player state
  ///     final bool playing = _assetsAudioPlayer.isPlaying.value;
  ///
  /// will follow the AssetsAudioPlayer playing state
  ///     return StreamBuilder(
  ///         stream: _assetsAudioPlayer.currentPosition,
  ///         builder: (context, asyncSnapshot) {
  ///             final bool isPlaying = asyncSnapshot.data;
  ///             return Text(isPlaying ? "Pause" : "Play");
  ///         }),
  ValueStream<bool> get isPlaying => _isPlaying.stream;

  /// Then mediaplayer playing audio (mutable)
  final BehaviorSubject<Playing> _current = BehaviorSubject();

  /// The current playing audio, filled with the total song duration
  /// Exposes a PlayingAudio
  ///
  /// Retrieve directly the current played asset
  ///     final PlayingAudio playing = _assetsAudioPlayer.current.value;
  ///
  /// Listen to the current playing song
  ///     _assetsAudioPlayer.current.listen((playing){
  ///         final path = playing.audio.path;
  ///         final songDuration = playing.audio.duration;
  ///     })
  ///
  ValueStream<Playing> get current => _current.stream;

  /// Called when the the complete playlist finished to play (mutable)
  final BehaviorSubject<bool> _playlistFinished =
      BehaviorSubject<bool>.seeded(false);

  /// Called when the complete playlist has finished to play
  ///     _assetsAudioPlayer.finished.listen((finished){
  ///
  ///     })
  ///
  ValueStream<bool> get playlistFinished => _playlistFinished.stream;

  /// Called when the current playlist song has finished (mutable)
  /// Using a playlist, the `finished` stram will be called only if the complete playlist finished
  /// _assetsAudioPlayer.playlistAudioFinished.listen((audio){
  ///      the $audio has finished to play, moving to next audio
  /// })
  final PublishSubject<Playing> _playlistAudioFinished = PublishSubject();

  /// Called when the current playlist song has finished
  /// Using a playlist, the `finished` stram will be called only if the complete playlist finished
  Stream<Playing> get playlistAudioFinished => _playlistAudioFinished.stream;

  /// Then current playing song position (in seconds) (mutable)
  final BehaviorSubject<Duration> _currentPosition =
      BehaviorSubject<Duration>.seeded(const Duration());

  /// Retrieve directly the current song position (in seconds)
  ///     final Duration position = _assetsAudioPlayer.currentPosition.value;
  ///
  ///     return StreamBuilder(
  ///         stream: _assetsAudioPlayer.currentPosition,
  ///         builder: (context, asyncSnapshot) {
  ///             final Duration duration = asyncSnapshot.data;
  ///             return Text(duration.toString());
  ///         }),
  Stream<Duration> get currentPosition => _currentPosition.stream;

  final BehaviorSubject<bool> _loop = BehaviorSubject<bool>.seeded(false);

  /// Called when the looping state changes
  ///     _assetsAudioPlayer.isLooping.listen((looping){
  ///
  ///     })
  ///
  ValueStream<bool> get isLooping => _loop.stream;

  /// returns the looping state : true -> looping, false -> not looping
  bool get loop => _loop.value;

  /// assign the looping state : true -> looping, false -> not looping
  set loop(value) {
    _loop.value = value;
  }

  /// toggle the looping state
  /// if it was looping -> stops this
  /// if it was'nt looping -> now it is
  void toggleLoop() {
    loop = !loop;
  }

  /// Call it to dispose stream
  void dispose() {
    stop();

    _currentPosition.close();
    _isPlaying.close();
    _playlistFinished.close();
    _current.close();
    _playlistAudioFinished.close();
    _loop.close();
  }

  AssetsAudioPlayer() {
    _channel.setMethodCallHandler((MethodCall call) async {
      //print("received call ${call.method} with arguments ${call.arguments}");
      switch (call.method) {
        case 'log':
          print("log: " + call.arguments);
          break;
        case 'player.finished':
          _onfinished(call.arguments);
          break;
        case 'player.current':
          final totalDuration = _toDuration(call.arguments["totalDuration"]);

          final playingAudio = PlayingAudio(
            assetAudioPath: _lastOpenedAssetsAudioPath,
            duration: totalDuration,
          );

          if (_playlist != null) {
            _current.value = Playing(
              audio: playingAudio,
              index: _playlist.playlistIndex,
              hasNext: _playlist.hasNext(),
              playlist: ReadingPlaylist(
                  audios: _playlist.playlist.audios,
                  currentIndex: _playlist.playlistIndex),
            );
          }
          break;
        case 'player.position':
          if (call.arguments is int) {
            _currentPosition.value = Duration(seconds: call.arguments);
          } else if (call.arguments is double) {
            double value = call.arguments;
            _currentPosition.value = Duration(seconds: value.round());
          }
          break;
        case 'player.isPlaying':
          _isPlaying.value = call.arguments;
          break;
        default:
          print('[ERROR] Channel method ${call.method} not implemented.');
      }
    });
  }

  void playlistPlayAtIndex(int index) {
    _playlist.moveTo(index);
    _open(_playlist.currentAudioPath());
  }

  bool previous() {
    if (_playlist != null) {
      if (_playlist.hasPrev()) {
        _playlist.selectPrev();
        _open(_playlist.currentAudioPath());
        return true;
      } else if (_playlist.playlistIndex == 0) {
        seek(Duration.zero);
        return true;
      }
    }

    return false;
  }

  bool next({bool stopIfLast = false}) {
    if (_playlist != null) {
      if (_playlist.hasNext()) {
        _playlistAudioFinished.add(Playing(
          audio: this._current.value.audio,
          index: this._current.value.index,
          hasNext: true,
          playlist: this._current.value.playlist,
        ));
        _playlist.selectNext();
        _open(_playlist.currentAudioPath());

        return true;
      } else if (loop) {
        //last element
        _playlistAudioFinished.add(Playing(
          audio: this._current.value.audio,
          index: this._current.value.index,
          hasNext: false,
          playlist: this._current.value.playlist,
        ));

        _playlist.returnToFirst();
        _open(_playlist.currentAudioPath());

        return true;
      } else if (stopIfLast) {
        stop();
        return true;
      }
    }
    return false;
  }

  void _onfinished(bool isFinished) {
    bool nextDone = next(stopIfLast: false);
    if (nextDone) {
      _playlistFinished.value = false; //continue playing the playlist
    } else {
      _playlistFinished.value = true; // no next elements -> finished
    }
  }

  /// Converts a number to duration
  Duration _toDuration(num value) {
    if (value is int) {
      return Duration(seconds: value);
    } else if (value is double) {
      return Duration(seconds: value.round());
    } else {
      return Duration();
    }
  }

  //private method, used in open(playlist) and open(path)
  void _open(String assetAudioPath) async {
    if (assetAudioPath != null) {
      try {
        _channel.invokeMethod('open', assetAudioPath);
      } catch (e) {
        print(e);
      }

      _lastOpenedAssetsAudioPath = assetAudioPath;
    }
  }

  void _openPlaylist(Playlist playlist) async {
    this._playlist = _CurrentPlaylist(playlist: playlist);
    _playlist.moveTo(playlist.startIndex);
    _open(_playlist.currentAudioPath());
  }

  /// Open a song from the asset
  /// ### Example
  ///
  ///     AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  ///
  ///     _assetsAudioPlayer.open(Audio("assets/audios/song1.mp3"))
  ///
  /// Don't forget to declare the audio folder in your `pubspec.yaml`
  ///
  ///     flutter:
  ///       assets:
  ///         - assets/audios/
  ///
  void open(Playable playable) async {
    if (playable is Playlist &&
        playable.audios != null &&
        playable.audios.length > 0) {
      _openPlaylist(playable);
    } else if (playable is Audio) {
      _openPlaylist(Playlist(audios: [playable]));
    } else {
      //do nothing
      //throw exception ?
    }
  }

  /// Toggle the current playing state
  /// If the media player is playing, then pauses it
  /// If the media player has been paused, then play it
  ///
  ///     _assetsAudioPlayer.playOfPause();
  ///
  void playOrPause() async {
    final bool playing = _isPlaying.value;
    if (playing) {
      pause();
    } else {
      play();
    }
  }

  /// Tells the media player to play the current song
  ///     _assetsAudioPlayer.play();
  ///
  void play() {
    _channel.invokeMethod('play');
  }

  /// Tells the media player to play the current song
  ///     _assetsAudioPlayer.pause();
  ///
  void pause() {
    _channel.invokeMethod('pause');
  }

  /// Change the current position of the song
  /// Tells the player to go to a specific position of the current song
  ///
  ///     _assetsAudioPlayer.seek(Duration(minutes: 1, seconds: 34));
  ///
  void seek(Duration to) {
    _channel.invokeMethod('seek', to.inSeconds.round());
  }

  /// Tells the media player to stop the current song, then release the MediaPlayer
  ///     _assetsAudioPlayer.stop();
  ///
  void stop() {
    _channel.invokeMethod('stop');
  }

//void shufflePlaylist() {
//  TODO()
//}

  /// TODO Playlist Loop / Loop 1
//void playlistLoop(PlaylistLoop /* enum */ mode) {
//  TODO()
//}
}

class _CurrentPlaylist {
  final Playlist playlist;

  int playlistIndex = 0;

  int selectNext() {
    if (hasNext()) {
      playlistIndex += 1;
    }
    return playlistIndex;
  }

  int moveTo(int index) {
    if (index < 0) {
      playlistIndex = 0;
    } else {
      playlistIndex = index % playlist.numberOfItems;
    }
    return playlistIndex;
  }

  //nullable
  String audioPath({int at}) {
    if (at < playlist.audios.length) {
      return playlist.audios[at]?.path;
    } else {
      return null;
    }
  }

  String currentAudioPath() {
    return audioPath(at: playlistIndex);
  }

  bool hasNext() {
    return playlistIndex + 1 < playlist.numberOfItems;
  }

  _CurrentPlaylist({@required this.playlist});

  void returnToFirst() {
    playlistIndex = 0;
  }

  bool hasPrev() {
    return playlistIndex > 0;
  }

  void selectPrev() {
    playlistIndex--;
    if (playlistIndex < 0) {
      playlistIndex = 0;
    }
  }
}
