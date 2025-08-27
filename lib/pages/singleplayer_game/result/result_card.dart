import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '/models/result.dart';
import '/models/quiz.dart';
import '/generated/app_localizations.dart';
import '/utils/error_handler.dart';

class ResultCard extends StatefulWidget {
  final bool active;
  final Result result;
  final int index;

  const ResultCard({
    super.key,
    required this.result,
    required this.index,
    this.active = false,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  final Logger logger = Logger();
  final AudioPlayer _audioPlayer = AudioPlayer();
    
  //播放变化监测变量
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processSubscription;
  StreamSubscription? _sequenceSubscription;

  String get _durationTextUnSplited => _duration?.toString() ?? "";
  String get _positionTextUnSplited => _position?.toString() ?? "";
  String get _durationText => _durationTextUnSplited.substring(
    _durationTextUnSplited.indexOf(":")+1,
    _durationTextUnSplited.lastIndexOf(".")
  );
  String get _positionText => _positionTextUnSplited.substring(
    _positionTextUnSplited.indexOf(":")+1,
    _positionTextUnSplited.lastIndexOf(".")
  );

  bool _audioLoaded = false;
  bool _audioLoading = false;
  Future<void> _loadAudio() async {
    if (_audioLoaded) return;
    final musicUrl = "https://hungryhenry.cn/musiclab/music/${widget.result.musicId}.mp3";
    try {
      setState(() {
        _audioLoading = true;
      });
      await _audioPlayer.setUrl(musicUrl);
      setState(() {
        _audioLoading = false;
      });
      _audioLoaded = true;
      
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        setState(() {
          _duration = duration;
        });
      });
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });
      _sequenceSubscription = _audioPlayer.sequenceStateStream.listen((state) {
        if (state != null) {
          setState(() {});
        }
      });
    } catch (e) {
      if(!mounted) return;
      ErrorHandler(context).handle(e, HandleTypes.other);
    }
  }
  @override
  void didUpdateWidget(ResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(!widget.active && _audioPlayer.playing) {
      _audioPlayer.pause();
    } 
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _processSubscription?.cancel();
    _sequenceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if(widget.result.artistId != null){
      imageUrl = "https://hungryhenry.cn/musiclab/artist/${widget.result.artistId}_logo.jpg";
    }else if(widget.result.albumId != null){
      imageUrl = "https://hungryhenry.cn/musiclab/album/${widget.result.albumId}.jpg";
    }

    return Card(
      elevation: 5,
      shadowColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  onChanged: (value) {
                    final duration = _duration;
                    if (duration == null) {
                      return;
                    }
                    final position = value * duration.inMilliseconds;
                    _audioPlayer.seek(Duration(milliseconds: position.round()));
                    if (!_audioPlayer.playing) {
                      _audioPlayer.play();
                    }
                  },
                  value: (_position != null &&
                          _duration != null &&
                          _position!.inMilliseconds > 0 &&
                          _position!.inMilliseconds < _duration!.inMilliseconds)
                      ? _position!.inMilliseconds / _duration!.inMilliseconds
                      : 0.0,
                  inactiveColor: Colors.grey,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _position != null ? _positionText : '--:--',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 230,
                    child: Text(widget.result.music, textAlign: TextAlign.center,),
                  ),
                  Text(
                    _duration != null ? _durationText : '--:--',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${widget.index + 1}. ${widget.result.getQuestion(context)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _audioLoading ? const CircularProgressIndicator()
                      : IconButton(
                          icon: _audioPlayer.playing
                              ? const Icon(Icons.pause)
                              : _audioLoading
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.play_arrow),
                          onPressed: () async {
                            try {
                              if (_audioPlayer.playing) {
                                _audioPlayer.pause();
                              } else if (_audioLoaded){
                                await _audioPlayer.play();
                              } else{
                                await _loadAudio();
                                await _audioPlayer.play();
                              }
                            } catch (e) {
                              if(!mounted) return;
                              ErrorHandler(context).handle(e, HandleTypes.other);
                            }
                          },
                        )
                ],
              ),
              const SizedBox(height: 8),
              if (choosingTypes.contains(widget.result.quizType)) 
                Column(
                  children: [
                    ..._buildOptions(widget.result),
                    const SizedBox(height: 5),
                    Text("用时：${widget.result.answerTime}s", textAlign: TextAlign.center)
                  ],
                )
              else 
                _buildInputQuestion(widget.result),
            ]
          ),
        ),
      ),
    );
  }
}

Widget _buildInputQuestion(Result result) {
  final bool isCorrect = submissionCorrect(result);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("你的回答：",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isCorrect ? Colors.green.withValues(alpha: 0.7) : Colors.red.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(result.submission,style: const TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 12),
      if (!isCorrect) ...[
        Text("正确答案：",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(result.correctAnswers.join(", "),
              style: const TextStyle(fontSize: 16)),
        ),
      ],
      const SizedBox(height: 12),
      Text("回答用时：${result.answerTime}s"),
    ],
  );
}


List<Widget> _buildOptions(Result result) {
  return result.options!.map<Widget>((option) {
    final isCorrect = result.correctAnswers.contains(option["title"]);
    final isSelected = option["title"] == result.submission;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: isSelected
            ? (isCorrect
                ? const Icon(Icons.check, color: Colors.green)
                : const Icon(Icons.close, color: Colors.red))
            : null,
        title: Text(option["title"]!),
      ),
    );
  }).toList();
}