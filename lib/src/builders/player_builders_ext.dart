import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/widgets.dart';

extension AssetAudioPlayerBuilder on AssetsAudioPlayer {
  PlayerBuilder builderIsPlaying({
    Key key,
    @required PlayingWidgetBuilder builder,
  }) =>
      PlayerBuilder.isPlaying(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderIsBuffering({
    Key key,
    @required IsBufferingWidgetBuilder builder,
  }) =>
      PlayerBuilder.isBuffering(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderIsLooping({
    Key key,
    @required IsLoopingWidgetBuilder builder,
  }) =>
      PlayerBuilder.isLooping(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderRealtimePlayingInfos({
    Key key,
    @required RealtimeWidgetBuilder builder,
  }) =>
      PlayerBuilder.realtimePlayingInfos(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderVolume({
    Key key,
    @required VolumeWidgetBuilder builder,
  }) =>
      PlayerBuilder.volume(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderPlaySpeed({
    Key key,
    @required PlaySpeedWidgetBuilder builder,
  }) =>
      PlayerBuilder.playSpeed(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderCurrentPosition({
    Key key,
    @required PositionWidgetBuilder builder,
  }) =>
      PlayerBuilder.currentPosition(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderForwardRewindSpeed({
    Key key,
    @required ForwardRewindSpeedWidgetBuilder builder,
  }) =>
      PlayerBuilder.forwardRewindSpeed(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderCurrent({
    Key key,
    @required CurrentWidgetBuilder builder,
  }) =>
      PlayerBuilder.current(
        key: key,
        player: this,
        builder: builder,
      );

  PlayerBuilder builderPlayerState({
    Key key,
    @required PlayerStateBuilder builder,
  }) =>
      PlayerBuilder.playerState(
        key: key,
        player: this,
        builder: builder,
      );
}
