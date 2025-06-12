import '../generated/l10n.dart';

enum QuizType {
  chooseMusic,
  chooseArtist,
  chooseAlbum,
  chooseGenre,
  enterMusic,
  enterArtist,
  enterAlbum,
  enterGenre
}

final List<QuizType> choosingTypes = [
  QuizType.chooseMusic,
  QuizType.chooseArtist,
  QuizType.chooseAlbum,
  QuizType.chooseGenre
];

List<Quiz> list2QuizList(List<dynamic> jsonList) {
  List<Quiz> quizList = [];
  for (var json in jsonList) {
    quizList.add(Quiz.fromJson(json));
  }
  return quizList;
}

class Quiz {
  // 关于歌曲
  final QuizType quizType;
  final int musicId;
  final String music;
  final int? artistId;
  final List<String> artists;
  final String? artist;
  final int? albumId;
  final String? album;
  final List<int>? genreId;
  final List<String>? genre;

  // 关于答题
  final int startAt;
  final int musicPlayingTime;
  final int answerTime;
  final List<Map<String, String>>? options;
  final List<int>? blanks;
  final String? tip;

  Quiz(
      {required this.quizType,
      required this.musicId,
      required this.music,
      this.artistId,
      required this.artists,
      this.artist,
      this.albumId,
      this.album,
      this.genreId,
      this.genre,
      required this.startAt,
      required this.musicPlayingTime,
      required this.answerTime,
      this.options,
      this.blanks,
      this.tip});
  
  factory Quiz.fromJson(Map<String, dynamic> json) {
    try {
      List<Map<String, String>>? options;
      if (json["options"]!= null) {
        List<Map> tempOptions = List<Map>.from(json["options"]);
        options = tempOptions.map((e) => Map<String, String>.from(e)).toList();
      }
      return Quiz(
          quizType: QuizType.values[json["quiz_type"]],
          musicId: json["music_id"],
          music: json["music"],
          artistId: json["artist_id"],
          artists: List<String>.from(json["artists"]),
          artist: json["artist"],
          albumId: json["album_id"],
          album: json["album"],
          genreId: json["genre_id"] == null ? null : List<int>.from(json["genre_id"]),
          genre: json["genre"] == null ? null : List<String>.from(json["genre"]),
          startAt: json["start_at"],
          musicPlayingTime: json["music_playing_time"],
          answerTime: json["answer_time"],
          options: options,
          blanks: json["blanks"] == null ? null : List<int>.from(json["blanks"]),
          tip: json["tip"]);
    } catch(e, stackTrace) {
      throw Exception("Error parsing Quiz from json: $json\n$e\n$stackTrace");
    }
  }


  // 获取答案
  static final Map<int, List<String>? Function(Quiz)> _answerResolvers = {
    0: (q) => [q.music],
    1: (q) => q.artists,
    2: (q) => [q.album!],
    3: (q) => q.genre,
    4: (q) => [q.music],
    5: (q) => q.artists,
    6: (q) => [q.album!],
    7: (q) => q.genre
  };
  List<String> getAnswer(){
    final resolver = _answerResolvers[quizType.index];
    if (resolver == null) {
      throw Exception("Unsupported quiz type: $quizType");
    }else{
      return resolver(this)!;
    }
  }

  static final Map<int, String Function(Quiz)> _questionResolvers = {
    0: (q) => S.current.chooseMusic,
    1: (q) => S.current.chooseArtist,
    2: (q) => S.current.chooseAlbum,
    3: (q) => S.current.chooseGenre,
    4: (q) => S.current.enterMusic,
    5: (q) => S.current.enterArtist,
    6: (q) => S.current.enterAlbum,
    7: (q) => S.current.enterGenre
  };
  String getQuestion(){
    final resolver = _questionResolvers[quizType.index];
    if (resolver == null) {
      return S.current.unknownError;
    }else{
      return resolver(this);
    }
  }
}