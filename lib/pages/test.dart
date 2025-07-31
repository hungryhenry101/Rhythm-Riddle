import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/result.dart';
import 'package:just_audio/just_audio.dart';

//直接跳转到result并传递参数
void jumpToResultPage(BuildContext context, Map result) {
  Navigator.pushNamed(context, '/SinglePlayerGameResult', arguments: result);
}

class TestPage extends StatelessWidget {
  
  TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("test"),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => {},
              child: Text("jump to result page")
            ),
            ElevatedButton(
              onPressed: () async{
                final player = AudioPlayer();
                player.setUrl("https://192.168.0.100/musiclab/music/38.mp3");
                await player.play();
                print("played");
              } ,
              child: Text("play music")
            ),
          ],
        ),
      ),
    );
  }
}