import 'dart:async';

import '/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import '/models/quiz.dart';
import '/models/result.dart';
import '/utils/error_handler.dart';
import '/widgets/correctness_overlay.dart';

class SinglePlayerGame extends StatefulWidget {
  const SinglePlayerGame({super.key});

  @override
  State<SinglePlayerGame> createState() => _SinglePlayerGameState();
}

class _SinglePlayerGameState extends State<SinglePlayerGame> {
  /// VARIABLES
  //数据传入存储
  int _playlistId = 0;
  String _playlistTitle = '';
  String? _description;
  int _difficulty = 0;

  int _currentQuiz = -1; //题目计数器
  final List<Result> _resultList = []; //结果存储
  final TextEditingController _controller = TextEditingController();

  //音频&题目显示计时
  int _countdown = 0;
  bool _canShowQuiz = false;

  List<Quiz> _quizzes = []; //存储api获取的题目

  String? _selectedOption; //选项
  String? _submittedOption; //提交的选项

  Logger logger = Logger(); //日志

  //答题时间
  int _answerTime = 0;
  int _currentAnswerTime = 0;

  //提示音
  final _assistAudio = AudioPlayer();

  //歌曲播放准备
  final _audioPlayer = AudioPlayer();
  int _played = 0;
  int _audioPlayingTime = 0;

  // CorrectnessOverlay
  bool _showOverlay = false;

  //播放变化监测变量
  ProcessingState _processingState = ProcessingState.idle;
  bool get _prepareFinished => _processingState == ProcessingState.ready;

  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  String get _durationTextUnSplited => _duration?.toString() ?? "";
  String get _positionTextUnSplited => _position?.toString() ?? "";
  String get _durationText => _durationTextUnSplited.substring(
      _durationTextUnSplited.indexOf(":") + 1,
      _durationTextUnSplited.lastIndexOf("."));
  String get _positionText => _positionTextUnSplited.substring(
      _positionTextUnSplited.indexOf(":") + 1,
      _positionTextUnSplited.lastIndexOf("."));

  /// FUNCTIONS
  Future<void> _wrongTune() async {
    await _assistAudio.setAsset("assets/sounds/wrong.mp3");
    await _assistAudio.play();
    logger.i("wrong tune played");
  }

  Future<void> _correctTune() async {
    await _assistAudio.setAsset("assets/sounds/correct.mp3");
    await _assistAudio.play();
    logger.i("correct tune played");
  }

  Future<void> _prepareAudio() async {
    logger.i("preparing audio");
    try {
      int musicId = _quizzes[_played].musicId;
      await _audioPlayer
          .setUrl("https://hungryhenry.cn/musiclab/music/$musicId.mp3")
          .timeout(const Duration(seconds: 15));
      await _audioPlayer.seek(Duration(
          seconds: _quizzes[_played].startAt)); // 跳到 startAt
      logger.i(
          "seeked to ${_quizzes[_played].startAt} seconds");
    } catch (e) {
      if(!mounted) return;
      ErrorHandler(context).handleGameError(e, () {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', arguments: _playlistId, (route) => false);
        Navigator.of(context)
            .pushNamed('/PlaylistInfo', arguments: _playlistId);
      });
    }
  }

  //倒计时
  void _startAudioCountdown() {
    logger.i("starting countdown");
    setState(() {
      _countdown = 3; // 初始化倒计时
      _canShowQuiz = false;
      _answerTime =
          _quizzes[_currentQuiz + 1].answerTime; // 答题时间
      _audioPlayingTime = _quizzes[_currentQuiz + 1].musicPlayingTime; // 音频播放时间
      _currentAnswerTime = _answerTime;
    });

    //提前加载音频
    _prepareAudio();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_countdown > 1) {
          setState(() {
            _countdown--; // 每秒减少1
          });
        } else {
          setState(() {
            _currentQuiz = ++_currentQuiz;
            _countdown = 0;
          });
          _playAndDelayAndPause(); // 开始播放
          timer.cancel(); // 停止计时器

          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _canShowQuiz = true;
            });
          });
        }
      }
    });
  }

  //获取题目
  Future<void> _getQuiz(int playlistId, int difficulty) async {
    try {
      final response = await Dio().get(
        "https://hungryhenry.cn/api/getQuiz.php?id=$playlistId&difficulty=$difficulty",
        options: Options(headers: {"Content-Type": "application/json"}),
      ).timeout(const Duration(seconds: 7));
      if (!mounted) return;
      if (response.statusCode == 200) {
        logger.i(_quizzes.runtimeType);
        setState(() {
          _quizzes = list2QuizList(response.data, context);
        });
      } else {
        throw Exception("Get quiz error: " + response.data);
      }
    } catch (e) {
      if(!mounted) return;
      ErrorHandler(context).handleGameError(e, () {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', arguments: _playlistId, (route) => false);
        Navigator.of(context)
            .pushNamed('/PlaylistInfo', arguments: _playlistId);
      }, (){
        Navigator.of(context).popAndPushNamed('/SinglePlayerGame', arguments: {
          playlistId,
          _playlistTitle,
          _description,
          difficulty
        });
      });
    }
  }

  //答题倒计时
  void _answerTimeCountdown() {
    if (!mounted) return;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentAnswerTime == 0 || _submittedOption != null) {
        timer.cancel();
        if (_currentAnswerTime == 0 && mounted) {
          // 时间到
          setState(() {
            _submittedOption = "";
            _resultList.add(
              Result(
                quizType: _quizzes[_currentQuiz].quizType,
                correctAnswers: _quizzes[_currentQuiz].getAnswer(),
                musicId: _quizzes[_currentQuiz].musicId,
                music: _quizzes[_currentQuiz].music,
                artistId: _quizzes[_currentQuiz].artistId,
                albumId: _quizzes[_currentQuiz].albumId,
                submission: _submittedOption!,
                options: _quizzes[_currentQuiz].options,
                answerTime: _answerTime,
              )
            );
          });
          if (!_audioPlayer.playing) {
            _audioPlayer.play();
          }
        }
      } else {
        if (mounted && _prepareFinished) {
          setState(() {
            _currentAnswerTime--; // 每秒减少1
          });
        }
      }
    });
  }

  Future<void> _playAndDelayAndPause() async {
    //如果没有准备好播放，等待直到准备好
    while (_processingState != ProcessingState.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _audioPlayer.play();
    _played++;
    _answerTimeCountdown();
    await Future.delayed(Duration(seconds: _audioPlayingTime), () {
      if (_submittedOption == null && mounted) {
        _audioPlayer.pause();
      }
    });
  }

  //给答案挖空
  String? replaceWithBlanks(String answer, List<int> blanks) {
    // 按位置插入空格
    if (blanks.isEmpty) return null;
    for (int i = 0; i < blanks.length; i++) {
      int position = blanks[i]; // 转换为 0-based index
      if (position >= 0 && position < answer.length) {
        answer = answer.substring(0, position) +
            '_' +
            answer.substring(position + 1);
      }
    }
    return answer;
  }

  //显示题目
  Widget _showQuiz(Quiz quiz, int difficulty) {
    QuizType quizType = quiz.quizType; //题目类型

    List<String> answerList = quiz.getAnswer();
    answerList.removeWhere((item) => item == "欧美" || item == "华语");

    bool isChoosing = choosingTypes.contains(quizType); //是否是选择题
    bool haveSubtitle = false;
    bool haveImage = false;
    if(quiz.options != null && quiz.options!.first.containsKey("subtitle")){
      haveSubtitle = true;
    }
    if(quiz.options != null && quiz.options!.first.containsKey("image_url")){
      haveImage = true;
    }
    String? tip;
    if (!isChoosing) {
      if (quiz.blanks == null) {
        tip = quiz.tip;
      } else {
        tip = replaceWithBlanks(answerList[0], quiz.blanks!); // 有blank 的一定只有一个 实数根（bushi
      }
    }

    String question = "";
    String musicInfo = "";

    question = quiz.getQuestion(context);
    musicInfo = quiz.music + " - " + quiz.artists.join(", ");

    return SizedBox(
      width: MediaQuery.of(context).size.width > 800
          ? MediaQuery.of(context).size.width * 0.7 - 350
          : MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Text("${_currentQuiz + 1}/${_quizzes.length - 1}"),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //题目
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8 - 55),
                child: Text(
                  question,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),

              if (_submittedOption == null) ...[
                //倒计时
                Container(
                  padding: !_prepareFinished
                      ? const EdgeInsets.all(8.0)
                      : const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentAnswerTime < 6 &&
                            _currentAnswerTime != 0 &&
                            !_prepareFinished
                        ? Colors.yellow
                        : Colors.grey[300],
                  ),
                  child: !_prepareFinished
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          _currentAnswerTime.toString(),
                          style: _currentAnswerTime < 6 && !_prepareFinished
                              ? const TextStyle(
                                  color: Colors.red,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                )
                              : const TextStyle(fontSize: 24),
                        ),
                ),
              ]
            ],
          ),
          Column(
            mainAxisAlignment: MediaQuery.of(context).size.width > 800
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: isChoosing
                ? [
                    //选择
                    for (int index = 0; index < quiz.options!.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _submittedOption == null ? Colors.transparent
                                : answerList.contains(quiz.options![index]['title'])
                                  ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          title: Text(quiz.options![index]['title']!),
                          subtitle: Column(
                            children: [
                              if(_submittedOption != null && haveSubtitle)...[
                                Text(quiz.options![index]['subtitle']!)
                              ],
                              if(_submittedOption != null && haveImage)...[
                                Image.network(
                                  quiz.options![index]["image_url"]!,
                                  width: 75, 
                                  height: 75, 
                                  loadingBuilder:(
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent?
                                    loadingProgress
                                  ) {
                                    if (loadingProgress == null) {
                                      return child;
                                    } else {
                                      return SizedBox(
                                        height: 75,
                                        width: 75,
                                        child: Center(
                                          child:
                                              CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : 1,
                                          ),
                                        ),
                                      );
                                    }
                                  }, errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                    logger.w("error loading image ${quiz.options![index]['image_url']}");
                                    logger.e(exception);
                                    return const Icon(Icons.image,
                                        color: Colors.grey);
                                  })
                              ]
                            ],
                          ),
                          leading: Radio<String>(
                            value: quiz.options![index]["title"]!,
                            fillColor: WidgetStateProperty.all(
                                _submittedOption == null
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey),
                            overlayColor: WidgetStateProperty.all(
                                _submittedOption == null
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.08)
                                    : Colors.transparent),
                            groupValue: _selectedOption,
                            mouseCursor: _submittedOption == null
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic, //鼠标样式
                            onChanged: (String? value) {
                              if (_submittedOption == null && mounted) {
                                setState(() {
                                  _selectedOption = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                  ]
                : [
                    //填写
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            enabled: _submittedOption == null,
                            controller: _controller,
                            onSubmitted: (value) {
                              setState(() {
                                _submittedOption = value;
                                _resultList.add(Result(
                                  quizType: quiz.quizType,
                                  correctAnswers: answerList,
                                  musicId: quiz.musicId,
                                  music: quiz.music,
                                  albumId: quiz.albumId,
                                  artistId: quiz.artistId,
                                  submission: _submittedOption!,
                                  options: quiz.options,
                                  answerTime: _answerTime - _currentAnswerTime
                                ));
                                _currentAnswerTime = _answerTime;
                              });
                              if (!_audioPlayer.playing) {
                                _audioPlayer.play();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_submittedOption == null) ...[
                      Text(AppLocalizations.of(context)!.tip),
                      Text(tip ?? "",
                          style:
                              const TextStyle(letterSpacing: 2, fontSize: 18))
                    ] else ...[
                      Text(AppLocalizations.of(context)!.correctAnswer),
                      Text(answerList.join(", "),
                          style:
                              const TextStyle(letterSpacing: 2, fontSize: 18)),
                      const SizedBox(height: 10),
                      Image.network(
                          quizType == QuizType.enterMusic
                              ? "https://hungryhenry.cn/musiclab/album/${quiz.albumId}.jpg"
                              : quizType == QuizType.enterArtist
                                  ? "https://hungryhenry.cn/musiclab/artist/${quiz.artistId}_logo.jpg"
                                  : quizType == QuizType.enterAlbum
                                      ? "https://hungryhenry.cn/musiclab/album/${quiz.albumId}.jpg"
                                      : "https://hungryhenry.cn/musiclab/album/${quiz.albumId}.jpg",
                          width: 150,
                          height: 150, loadingBuilder: (BuildContext context,
                              Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return SizedBox(
                            height: 150,
                            width: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : 1,
                              ),
                            ),
                          );
                        }
                      }, errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                        return const SizedBox(
                          height: 150,
                          width: 150,
                          child: Center(
                              child: Icon(Icons.image, color: Colors.grey)),
                        );
                      })
                    ]
                  ],
          ),
          if (_submittedOption == null) ...[
            //提交按钮
            ElevatedButton(
              onPressed: () async {
                logger.i("submitted with ${_selectedOption ?? _controller.text}");
                setState(() {
                  _submittedOption = _selectedOption ?? _controller.text;
                  _resultList.add(Result(
                    quizType: quiz.quizType,
                    correctAnswers: answerList,
                    musicId: quiz.musicId,
                    music: quiz.music,
                    artistId: quiz.artistId,
                    albumId: quiz.albumId,
                    submission: _submittedOption!,
                    options: quiz.options,
                    answerTime: _answerTime - _currentAnswerTime
                  ));
                  _currentAnswerTime = _answerTime;
                });

                //提示音
                if (_submittedOption == "") {
                  setState(() {
                    _showOverlay = true;
                  });
                  if(_audioPlayer.playing){
                    await _audioPlayer.pause();
                  }
                  await _wrongTune();
                  _audioPlayer.play();
                }
                if (answerList.any((item) =>
                    item.toLowerCase() == _submittedOption!.toLowerCase())) {
                  setState(() {
                    _showOverlay = true;
                  });
                  _correctTune();
                } else { 
                  setState(() {
                    _showOverlay = true;
                  });
                  if(_audioPlayer.playing){
                    await _audioPlayer.pause();
                  }
                  await _wrongTune();
                  _audioPlayer.play();
                }
                Future.delayed(
                    const Duration(seconds: 1), () => _audioPlayer.play());
              },
              child: Text(AppLocalizations.of(context)!.submit),
            ),
          ] else ...[
            if (_showOverlay)...[
              const SizedBox(height: 10),
              _submittedOption == ""
                ? CorrectnessOverlay(
                  type: OverlayType.timeout,
                  onFinish: ()=> setState(()=>_showOverlay = false),
                )
                : answerList.any((item) => item.toLowerCase() == _submittedOption!.toLowerCase())
                  ? CorrectnessOverlay(
                    type: OverlayType.correct,
                    onFinish: ()=> setState(()=>_showOverlay = false),
                  )
                  : CorrectnessOverlay(
                    type: OverlayType.wrong,
                    onFinish: ()=> setState(()=>_showOverlay = false),
                  ),
            ],
            const SizedBox(height: 10),
            if (_currentQuiz + 2 == _quizzes.length) ...[
              //结束
              ElevatedButton(
                onPressed: () {
                  _audioPlayer.stop();
                  final args = {
                    "playlistId": _playlistId,
                    "playlistTitle": _playlistTitle,
                    "difficulty": _difficulty,
                    "resultList": _resultList
                  };
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/SinglePlayerGameResult', (route) => false,
                      arguments: args);
                  logger.i(_resultList.map((e) => e.toJson()).toList());
                },
                child: Text(AppLocalizations.of(context)!.end),
              )
            ] else ...[
              //下一题
              ElevatedButton(
                onPressed: () async {
                  if (_audioPlayer.playing) {
                    while (_audioPlayer.volume > 0.05) {
                      await _audioPlayer.setVolume(_audioPlayer.volume - 0.07);
                      await Future.delayed(const Duration(milliseconds: 80));
                    }
                    await _audioPlayer.stop();
                    _audioPlayer.setVolume(1.0);
                  }
                  setState(() {
                    _submittedOption = null;
                    _selectedOption = null;
                    _controller.text = "";
                    _startAudioCountdown();
                  });
                },
                child: Text(AppLocalizations.of(context)!.next),
              ),
            ],
            if (_submittedOption != null && _showOverlay == false) ...[
              Text(musicInfo),
              //播放控制
              Row(
                children: [
                  //播放/暂停按钮
                  IconButton(
                    onPressed: () {
                      if(_audioPlayer.processingState != ProcessingState.completed 
                      && _audioPlayer.processingState != ProcessingState.idle){
                        _audioPlayer.playing
                          ? _audioPlayer.pause()
                          : _audioPlayer.play();
                        }
                    },
                    icon: _audioPlayer.playing
                        ? const Icon(Icons.pause)
                        : _audioPlayer.processingState != ProcessingState.ready
                        && _audioPlayer.processingState != ProcessingState.completed
                        && _audioPlayer.processingState != ProcessingState.idle
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.play_arrow),
                  ),
                  //进度条
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        onChanged: (value) {
                          final duration = _duration;
                          if (duration == null) {
                            return;
                          }
                          final position = value * duration.inMilliseconds;
                          _audioPlayer
                              .seek(Duration(milliseconds: position.round()));
                          if (!_audioPlayer.playing) {
                            _audioPlayer.play();
                          }
                        },
                        value: (_position != null &&
                                _duration != null &&
                                _position!.inMilliseconds > 0 &&
                                _position!.inMilliseconds <
                                    _duration!.inMilliseconds)
                            ? _position!.inMilliseconds /
                                _duration!.inMilliseconds
                            : 0.0,
                      ),
                    ),
                  ),
                  //进度
                  Text(
                    _position != null
                        ? '$_positionText / $_durationText'
                        : _duration != null
                            ? _durationText
                            : '',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ]
          ]
        ],
      ),
    );
  }

  Widget _largeScreen() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          children: [
            _playlistId == 0
                ? const Center(child: CircularProgressIndicator())
                : Image.network(
                    "https://hungryhenry.cn/musiclab/playlist/$_playlistId.jpg",
                    width: MediaQuery.of(context).size.width * 0.3,
                    fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(_playlistTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_description != null) ...[
              Text(_description ?? "No description",
                  style: const TextStyle(fontSize: 18), softWrap: true),
              const SizedBox(height: 14)
            ],
            Text(
                "${AppLocalizations.of(context)!.difficulty}: ${_difficulty == 1 ? AppLocalizations.of(context)!.easy : _difficulty == 2 ? AppLocalizations.of(context)!.normal : _difficulty == 3 ? AppLocalizations.of(context)!.hard : AppLocalizations.of(context)!.custom}",
                style: const TextStyle(fontSize: 18),
                softWrap: true),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _quizzes.isEmpty
                  ? const CircularProgressIndicator()
                  : //加载
                  AnimatedSwitcher(
                      //动画
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: _countdown > 0
                          ? Container(
                              key: ValueKey<int>(_countdown), // 使用倒计时数字作为key
                              padding:
                                  const EdgeInsets.all(24), // 调整内边距来增加背景的大小
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_countdown',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
              const SizedBox(height: 20),
              if (_currentQuiz != -1 && _canShowQuiz) ...[
                _showQuiz(_quizzes[_currentQuiz], _difficulty)
              ],
            ],
          ),
        )
      ],
    );
  }

  Widget _smallScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(_playlistTitle,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
              "${AppLocalizations.of(context)!.difficulty}: ${_difficulty == 1 ? AppLocalizations.of(context)!.easy : _difficulty == 2 ? AppLocalizations.of(context)!.normal : _difficulty == 3 ? AppLocalizations.of(context)!.hard : AppLocalizations.of(context)!.custom}",
              style: const TextStyle(fontSize: 16),
              softWrap: true),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  _quizzes.isEmpty
                      ? const CircularProgressIndicator()
                      : //加载
                      AnimatedSwitcher(
                          //动画
                          duration: const Duration(milliseconds: 800),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          },
                          child: _countdown > 0
                              ? Container(
                                  key:
                                      ValueKey<int>(_countdown), // 使用倒计时数字作为key
                                  padding:
                                      const EdgeInsets.all(24), // 调整内边距来增加背景的大小
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_countdown',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                  const SizedBox(height: 20),
                  if (_countdown > 0) ...[
                    Image.network(
                        "https://hungryhenry.cn/musiclab/playlist/$_playlistId.jpg",
                        width: 150,
                        height: 150)
                  ],
                ],
              ),
              if (_currentQuiz != -1 && _canShowQuiz) ...[
                _showQuiz(_quizzes[_currentQuiz], _difficulty)
              ],
            ],
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized(); // 确保绑定已初始化
    Future.microtask(() {
      //获取传入参数
      final Map args = ModalRoute.of(context)?.settings.arguments as Map;
      setState(() {
        _playlistId = args["id"];
        _playlistTitle = args["title"];
        _description = args["description"];
        _difficulty = args["difficulty"];
      });

      //获取题目
      _getQuiz(_playlistId, _difficulty);
    });

    //audioplayer状态更新
    _audioPlayer.playbackEventStream.listen((event) {}, onError: (error) {
      logger.e(error);
    });
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.processingStateStream.listen((processingState) {
      if (mounted) {
        setState(() => _processingState = processingState);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _assistAudio.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizzes.isNotEmpty &&
        _currentQuiz == -1 &&
        _countdown == 0 &&
        mounted) {
      _startAudioCountdown();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("${AppLocalizations.of(context)!.singlePlayer}: $_playlistTitle"),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: MediaQuery.of(context).size.width > 800
                ? _largeScreen()
                : _smallScreen(),
          )),
    );
  }
}
