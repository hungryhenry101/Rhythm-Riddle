import './quiz.dart';
import 'package:rhythm_riddle/generated/l10n.dart';

class Result {
  final QuizType quizType;
  final List<String> correctAnswers;
  final int musicId;
  final int? albumId;
  final int? artistId;
  final String submission;
  final List<Map<String, String>>? options;
  final int answerTime;

  Result(
    {required this.quizType,
    required this.correctAnswers,
    required this.musicId,
    this.albumId,
    this.artistId,
    required this.submission,
    this.options,
    required this.answerTime});

  //toJson
  Map<String, dynamic> toJson() {
    return {
      'quizType': quizType.index,
      'correctAnswers': correctAnswers,
      'musicId': musicId,
      'albumId': albumId,
      'artistId': artistId,
      'submission': submission,
      'options': options,
      'answerTime': answerTime
    };
  }

  static final Map<int, String Function(Result)> _questionResolvers = {
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

bool submissionCorrect(Result result){
  List<String> correctAnswers = [];
  for(var item in result.correctAnswers){
    correctAnswers.add(item.toLowerCase());
  }
  if(correctAnswers.contains(result.submission.toLowerCase())){
    return true;
  }else{
    return false;
  }
}