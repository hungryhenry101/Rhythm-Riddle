import './quiz.dart';
import '/generated/app_localizations.dart';
import 'package:flutter/material.dart'; // Make sure to import this

class Result {
  final QuizType quizType;
  final List<String> correctAnswers;
  final int musicId;
  final String music;
  final int? albumId;
  final int? artistId;
  final String submission;
  final List<Map<String, String>>? options;
  final int answerTime;// Add this field

  Result({
    required this.quizType,
    required this.correctAnswers,
    required this.musicId,
    required this.music,
    this.albumId,
    this.artistId,
    required this.submission,
    this.options,
    required this.answerTime,// Add this to constructor
  });

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
      // Note: We don't include context in JSON as it's not serializable
    };
  }

  String getQuestion(BuildContext context) {
    final questionTexts = [
      AppLocalizations.of(context)!.chooseMusic,
      AppLocalizations.of(context)!.chooseArtist,
      AppLocalizations.of(context)!.chooseAlbum,
      AppLocalizations.of(context)!.chooseGenre,
      AppLocalizations.of(context)!.enterMusic,
      AppLocalizations.of(context)!.enterArtist,
      AppLocalizations.of(context)!.enterAlbum,
      AppLocalizations.of(context)!.enterGenre,
    ];
    
    if (quizType.index >= 0 && quizType.index < questionTexts.length) {
      return questionTexts[quizType.index];
    }
    return AppLocalizations.of(context)!.unknownError;
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