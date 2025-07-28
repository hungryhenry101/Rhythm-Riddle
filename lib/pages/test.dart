import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/result.dart';
import 'package:just_audio/just_audio.dart';

final data = {
  "playlistId": 17,
  "playlistTitle": "欧美",
  "difficulty": 1,
  "resultList": [
  Result(
    quizType: QuizType.chooseMusic,
    correctAnswers: [
      "Hey Brother"
    ],
    musicId: 4,
    submission: "Hey Brother",
    options: [
      {
        "title": "Waiting For Love",
        "subtitle": "Avicii, Martin Garrix"
      },
      {
        "title": "Hey Brother",
        "subtitle": "Avicii"
      },
      {
        "title": "Blinding Lights",
        "subtitle": "The Weeknd"
      },
      {
        "title": "Liar Liar",
        "subtitle": "Avicii, Aloe Blacc"
      }
    ],
    answerTime: 3
  ),
  Result(
    quizType: QuizType.chooseArtist,
    correctAnswers: [
      "Maroon 5"
    ],
    musicId: 21,
    submission: "Maroon 5",
    options: [
      {
        "title": "Taylor Swift",
        "image_url": "https://hungryhenry.cn/musiclab/artist/7_logo.jpg"
      },
      {
        "title": "Maroon 5",
        "image_url": "https://hungryhenry.cn/musiclab/artist/10_logo.jpg"
      },
      {
        "title": "Eminem",
        "image_url": "https://hungryhenry.cn/musiclab/artist/13_logo.jpg"
      },
      {
        "title": "Alan Walker",
        "image_url": "https://hungryhenry.cn/musiclab/artist/12_logo.jpg"
      }
    ],
    answerTime: 3
  ),
  Result(
    quizType: QuizType.chooseMusic,
    correctAnswers: [
      "Fix You"
    ],
    musicId: 13,
    submission: "Fix You",
    options: [
      {
        "title": "Fix You",
        "subtitle": "Coldplay"
      },
      {
        "title": "Lover",
        "subtitle": "Taylor Swift"
      },
      {
        "title": "She Will Be Loved",
        "subtitle": "Maroon 5"
      },
      {
        "title": "Subwoofer Lullaby",
        "subtitle": "C418"
      }
    ],
    answerTime: 4
  ),
  Result(
    quizType: QuizType.chooseAlbum,
    correctAnswers: [
      "X&Y"
    ],
    musicId: 7,
    submission: "bruhtimeout",
    options: [
      {
        "title": "X&Y",
        "subtitle": "Coldplay",
        "image_url": "https://hungryhenry.cn/musiclab/album/3.jpg"
      },
      {
        "title": "After Hours",
        "subtitle": "The Weeknd",
        "image_url": "https://hungryhenry.cn/musiclab/album/16.jpg"
      },
      {
        "title": "Purpose",
        "subtitle": "Justin Bieber",
        "image_url": "https://hungryhenry.cn/musiclab/album/15.jpg"
      },
      {
        "title": "It Won't Be Soon Before Long",
        "subtitle": "Maroon 5",
        "image_url": "https://hungryhenry.cn/musiclab/album/8.jpg"
      }
    ],
    answerTime: 15
  ),
  Result(
    quizType: QuizType.chooseGenre,
    correctAnswers: [
      "Folk Pop"
    ],
    musicId: 37,
    submission: "R&B",
    options: [
      {
        "title": "Folk Pop"
      },
      {
        "title": "R&B"
      },
      {
        "title": "Funk Pop"
      },
      {
        "title": "Dance Pop"
      }
    ],
    answerTime: 14
  ),
  Result(
    quizType: QuizType.chooseArtist,
    correctAnswers: [
      "Maroon 5"
    ],
    musicId: 24,
    submission: "Maroon 5",
    options: [
      {
        "title": "Maroon 5",
        "image_url": "https://hungryhenry.cn/musiclab/artist/10_logo.jpg"
      },
      {
        "title": "Taylor Swift",
        "image_url": "https://hungryhenry.cn/musiclab/artist/7_logo.jpg"
      },
      {
        "title": "OneRepublic",
        "image_url": "https://hungryhenry.cn/musiclab/artist/21_logo.jpg"
      },
      {
        "title": "Shawn Mendes",
        "image_url": "https://hungryhenry.cn/musiclab/artist/22_logo.jpg"
      }
    ],
    answerTime: 4
  )
]
};

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
              onPressed: () => jumpToResultPage(context, data),
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