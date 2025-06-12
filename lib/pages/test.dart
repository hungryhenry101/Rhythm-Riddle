import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Test extends StatefulWidget {
  const Test({Key? key}) : super(key: key);
  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  final player = AudioPlayer();

  Future<void> playAudio() async {
    await player.setAudioSource(AudioSource.uri(Uri.parse(
        "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3")));
    player.play();
    print("Audio Played");
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("test"),
        ),
        body: Center(
            child: TextButton(
                onPressed: () {
                  playAudio();
                },
                child: Text("Play Audio"))));
  }
}
