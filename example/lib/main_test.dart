import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  HomeState createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  final assetsAudioPlayer = AssetsAudioPlayer();
  int count = 0;
  int playlistCount = 0;
  Audio currentAudio = Audio('assets/audios/water.mp3');

  @override
  void initState() {
    super.initState();
    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
      setState(() {
        count++;
      });
    });
    assetsAudioPlayer.playlistFinished.listen((finished) {
      print(finished.toString());
      if (finished) {
        setState(() {
          playlistCount++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text("load"),
              onPressed: () {
                assetsAudioPlayer.open(
                  currentAudio,
                  showNotification: true,
                  notificationSettings:
                      NotificationSettings(prevEnabled: false),
                  loopMode: LoopMode.single,
                  autoStart: false,
                );
              },
            ),
            PlayerBuilder.isPlaying(
              player: assetsAudioPlayer,
              builder: (context, isPlaying) {
                return RaisedButton(
                  child: Text(isPlaying ? "Pause" : "Play"),
                  onPressed: () {
                    setState(() {
                      if (isPlaying) {
                        assetsAudioPlayer.pause();
                      } else {
                        assetsAudioPlayer.play();
                      }
                    });
                  },
                );
              },
            ),
            PlayerBuilder.loopMode(
              player: assetsAudioPlayer,
              builder: (context, loopMode) {
                return RaisedButton(
                  child: Text(loopMode == LoopMode.playlist
                      ? "looping"
                      : "not-looping"),
                  onPressed: () {
                    setState(() {
                      if (loopMode == LoopMode.playlist) {
                        assetsAudioPlayer.setLoopMode(LoopMode.none);
                      } else {
                        assetsAudioPlayer.setLoopMode(LoopMode.playlist);
                      }
                    });
                  },
                );
              },
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('count: ' + count.toString()),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('playlist count: ' + playlistCount.toString()),
            )
          ],
        ),
      ),
    );
  }
}
