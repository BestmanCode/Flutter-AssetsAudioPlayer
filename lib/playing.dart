import 'package:flutter/foundation.dart';

import 'playable.dart';

/// Represents the current played audio asset
/// When the player opened a song, it will ping AssetsAudioPlayer.current with a `AssetsAudio`
///
/// ### Example
///     final assetAudio = AssetsAudio(
///       assets/audios/song1.mp3,
///     )
///
///     _assetsAudioPlayer.current.listen((PlayingAudio current){
///         //ex: retrieve the current song's total duration
///     });
///
///     _assetsAudioPlayer.open(assetAudio);
///
@immutable
class PlayingAudio {
  ///the opened asset
  final String assetAudioPath;

  ///the current song's total duration
  final Duration duration;

  const PlayingAudio({
    this.assetAudioPath = "",
    this.duration = Duration.zero,
  });

  @override
  String toString() {
    return 'PlayingAudio{assetAudioPath: $assetAudioPath, duration: $duration}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingAudio &&
          runtimeType == other.runtimeType &&
          assetAudioPath == other.assetAudioPath &&
          duration == other.duration;

  @override
  int get hashCode => assetAudioPath.hashCode ^ duration.hashCode;
}

@immutable
class ReadingPlaylist {
  final List<Audio> audios;
  final int currentIndex;

  const ReadingPlaylist({@required this.audios, this.currentIndex = 0});

  @override
  String toString() {
    return 'ReadingPlaylist{audios: $audios, currentIndex: $currentIndex}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPlaylist &&
          runtimeType == other.runtimeType &&
          audios == other.audios &&
          currentIndex == other.currentIndex;

  @override
  int get hashCode => audios.hashCode ^ currentIndex.hashCode;
}

@immutable
class Playing {
  //TODO rename
  ///the opened asset
  final PlayingAudio audio;

  /// this audio index in playlist
  final int index;

  /// if this audio has a next element (if no : last element)
  final bool hasNext;

  /// the parent playlist
  final ReadingPlaylist playlist;

  Playing({
    @required this.audio,
    @required this.index,
    @required this.hasNext,
    @required this.playlist,
  });

  @override
  String toString() {
    return 'Playing{audio: $audio, index: $index, hasNext: $hasNext, playlist: $playlist}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playing &&
          runtimeType == other.runtimeType &&
          audio == other.audio &&
          index == other.index &&
          hasNext == other.hasNext &&
          playlist == other.playlist;

  @override
  int get hashCode =>
      audio.hashCode ^ index.hashCode ^ hasNext.hashCode ^ playlist.hashCode;
}

@immutable
class RealtimePlayingInfos {
  final String playerId;

  final Playing current;
  final Duration duration;
  final Duration currentPosition;
  final double volume;
  final bool isPlaying;
  final bool isLooping;

  RealtimePlayingInfos({
    @required this.playerId,
    @required this.current,
    @required this.currentPosition,
    @required this.volume,
    @required this.isPlaying,
    @required this.isLooping,
  }) : this.duration = current.audio.duration;

  double get playingPercent => this.duration.inMilliseconds == 0 ? 0 : this.currentPosition.inMilliseconds / this.duration.inMilliseconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RealtimePlayingInfos &&
              runtimeType == other.runtimeType &&
              playerId == other.playerId &&
              current == other.current &&
              duration == other.duration &&
              currentPosition == other.currentPosition &&
              volume == other.volume &&
              isPlaying == other.isPlaying &&
              isLooping == other.isLooping;

  @override
  int get hashCode =>
      playerId.hashCode ^
      current.hashCode ^
      duration.hashCode ^
      currentPosition.hashCode ^
      volume.hashCode ^
      isPlaying.hashCode ^
      isLooping.hashCode;

  @override
  String toString() {
    return 'RealtimePlayingInfos{playerId: $playerId, current: $current, duration: $duration, currentPosition: $currentPosition, volume: $volume, isPlaying: $isPlaying, isLooping: $isLooping}';
  }


}