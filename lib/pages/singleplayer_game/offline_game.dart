import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '/generated/l10n.dart';
import 'package:flutter/material.dart';

import '/utils/get_quiz.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

class OfflineGame extends StatefulWidget {
  @override
  _OfflineGameState createState() => _OfflineGameState();
}

class _OfflineGameState extends State<OfflineGame> {
  String? _getQuizError;
  bool _initialized = false;

  int _playlistId = 0;
  String _playlistTitle = "";
  String? _description;
  int _difficulty = -1;

  int _currentQuiz = -1;
  bool _canShowQuiz = false;
  Map<String, dynamic> _quizzes = {};
  Directory? _tempDir;

  final List _resultList = []; //结果存储
  final TextEditingController _controller = TextEditingController();

  String? _selectedOption; //选项
  String? _submittedOption; //提交的选项

  Logger logger = Logger(); //日志

  int _countdown = 0;
  //答题时间
  int _answerTime = 0;
  int _currentAnswerTime = 0;

  //提示音
  final _assistAudio = AudioPlayer();

  //歌曲播放准备
  final _audioPlayer = AudioPlayer();
  int _played = 0;
  int _audioPlayingTime = 0;

  //播放变化监测变量
  ProcessingState _processingState = ProcessingState.idle;
  bool get _prepareFinished => _processingState == ProcessingState.ready;

  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  String get _durationTextUnSplited => _duration?.toString() ?? "";
  String get _positionTextUnSplited => _position?.toString() ?? "";
  String get _durationText => _durationTextUnSplited != ""
      ? _durationTextUnSplited.substring(
          _durationTextUnSplited.indexOf(":") + 1,
          _durationTextUnSplited.lastIndexOf("."))
      : "";
  String get _positionText => _positionTextUnSplited != ""
      ? _positionTextUnSplited.substring(
          _positionTextUnSplited.indexOf(":") + 1,
          _positionTextUnSplited.lastIndexOf("."))
      : "";

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
      int id = _quizzes[_played.toString()]['music_id'] ??
          _quizzes[_played.toString()]['id'];
      await _audioPlayer.setFilePath(_tempDir!.path + "/music/$id.mp3",
          initialPosition:
              Duration(seconds: _quizzes[_played.toString()]['start_at']));
      logger.i(
          "seek finished ${_quizzes[_played.toString()]['start_at']} seconds");
    } catch (e) {
      if (e is TimeoutException) {
        logger.log(Level.error, "prepare audio timeout: $e");
        if (mounted) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(S.current.connectError),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              arguments: _playlistId,
                              (route) => false);
                          Navigator.of(context).pushNamed('/PlaylistInfo',
                              arguments: _playlistId);
                        },
                        child: Text(S.current.back)),
                  ],
                );
              });
        }
      } else {
        logger.log(Level.error, "prepare audio error: $e");
        if (mounted) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(S.current.unknownError),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              arguments: _playlistId,
                              (route) => false);
                          Navigator.of(context).pushNamed('/PlaylistInfo',
                              arguments: _playlistId);
                        },
                        child: Text(S.current.back)),
                  ],
                );
              });
        }
      }
    }
  }

  //倒计时
  void _startAudioCountdown() {
    logger.i("starting countdown");
    setState(() {
      _countdown = 3; // 初始化倒计时
      _canShowQuiz = false;
      _answerTime =
          _quizzes[(_currentQuiz + 1).toString()]["answer_time"]; // 答题时间
      _audioPlayingTime = _quizzes[(_currentQuiz + 1).toString()]
          ["music_playing_time"]; // 音频播放时间
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

  //答题倒计时
  void _answerTimeCountdown() {
    if (!mounted) return;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentAnswerTime == 0 || _submittedOption != null) {
        timer.cancel();
        if (_currentAnswerTime == 0 && mounted) {
          setState(() {
            _submittedOption = "bruhtimeout";
            _resultList.add({
              "quizType": _quizzes[_currentQuiz.toString()]["quizType"],
              "answer": _quizzes[_currentQuiz.toString()]["answer"],
              "musicId": _quizzes[_currentQuiz.toString()]["music_id"] ??
                  _quizzes[_currentQuiz.toString()]["id"],
              "submitText": "bruhtimeout",
              "options": _quizzes[_currentQuiz.toString()]["options"],
              "answerTime": _answerTime
            });
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

  Widget _showQuiz(Map quizInfo, int difficulty) {
    int quizType = quizInfo["quizType"]; //题目类型
    bool true4SelectFalse4Enter =
        quizType == 0 || quizType == 1 || quizType == 2 || quizType == 3;

    String answer = quizInfo['answer']; //正确答案
    List? answerList;

    List? options; //选项list
    String? tip;
    if (true4SelectFalse4Enter) {
      options = quizInfo["options"];
    } else {
      tip = quizInfo["tip"];
    }

    String question = "";
    String musicInfo = "";

    switch (quizType) {
      case 0: //选择歌曲
        question = S.current.chooseMusic;
        musicInfo = quizInfo["answer"] + " - " + quizInfo["artist"];
        break;
      case 1: //选择歌手
        question = S.current.chooseArtist;
        musicInfo = quizInfo["music"] + " - " + quizInfo["answer"];
        break;
      case 2: //选择专辑
        question = S.current.chooseAlbum;
        musicInfo = quizInfo["music"] + " - " + quizInfo["album_artist"];
        break;
      case 3: //选择流派
        question = S.current.chooseGenre;
        musicInfo = quizInfo["music"] + " - " + quizInfo["artist"];
        break;
      case 4: //填写歌曲
        question = S.current.enterMusic;
        musicInfo = quizInfo["answer"] + " - " + quizInfo["artist"];
        break;
      case 5: //填写歌手
        question = S.current.enterArtist;
        musicInfo = quizInfo["music"] + " - " + quizInfo["answer"];
        break;
      case 6: //填写专辑
        question = S.current.enterAlbum;
        musicInfo = quizInfo["answer"] + " - " + quizInfo["artist"];
        break;
      case 7: //填写流派
        question = S.current.enterGenre;
        musicInfo = quizInfo["music"] + " - " + quizInfo["artist"];
        break;
      default:
        S.current.unknownError;
        break;
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width > 800
          ? MediaQuery.of(context).size.width * 0.7 - 350
          : MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Text("${_currentQuiz + 1}/${_quizzes.length}"),
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
            children: true4SelectFalse4Enter
                ? [
                    //选择
                    for (int index = 0; index < options!.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _submittedOption == null
                                  ? Colors.transparent
                                  : (options[index]) == answer
                                      ? Colors.green
                                      : answerList != null
                                          ? answerList
                                                  .contains((options[index]))
                                              ? Colors.green
                                              : Colors.red
                                          : Colors.red,
                              width: 1,
                            ),
                          ),
                          title: Text(options[index]),
                          leading: Radio<String>(
                            value: options[index],
                            fillColor: WidgetStateProperty.all(
                                _submittedOption == null
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey),
                            overlayColor: WidgetStateProperty.all(
                                _submittedOption == null
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.08)
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
                                _resultList.add({
                                  "quizType": quizInfo['quizType'],
                                  "answer":
                                      answer.contains(",") ? null : answer,
                                  "answerList":
                                      answerList, //will be null if it's a choice question
                                  "submitText": _submittedOption,
                                  "musicId":
                                      quizInfo['music_id'] ?? quizInfo['id'],
                                  "options":
                                      options, //will be null if it's a fill-in-the-blank
                                  "answerTime": _answerTime - _currentAnswerTime
                                });
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
                      Text(S.current.tip),
                      Text(tip!,
                          style:
                              const TextStyle(letterSpacing: 2, fontSize: 18))
                    ] else ...[
                      Text(S.current.correctAnswer),
                      Text(answerList != null ? answerList.join(", ") : answer,
                          style:
                              const TextStyle(letterSpacing: 2, fontSize: 18)),
                      const SizedBox(height: 10),
                      Image.file(
                          quizType == 4
                              ? File(_tempDir!.path +
                                  "/album/${quizInfo['album_id']}.jpg")
                              : quizType == 5
                                  ? File(_tempDir!.path +
                                      "/artist/${quizInfo['id']}_logo.jpg")
                                  : quizType == 6
                                      ? File(_tempDir!.path +
                                          "/album/${quizInfo['id']}.jpg")
                                      : File(_tempDir!.path +
                                          "/album/${quizInfo['album_id']}.jpg"),
                          width: 150,
                          height: 150, errorBuilder: (BuildContext context,
                              Object exception, StackTrace? stackTrace) {
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
              onPressed: () {
                logger
                    .i("submitted with ${_selectedOption ?? _controller.text}");
                setState(() {
                  _submittedOption = _selectedOption ?? _controller.text;
                  _resultList.add({
                    "quizType": quizInfo['quizType'],
                    "answer": answer.contains(",") ? null : answer,
                    "answerList":
                        answerList, //will be null if it's a choice question
                    "submitText": _submittedOption,
                    "musicId": quizInfo['music_id'] ?? quizInfo['id'],
                    "options":
                        options, //will be null if it's a fill-in-the-blank
                    "answerTime": _answerTime - _currentAnswerTime
                  });
                  _currentAnswerTime = _answerTime;
                });

                //提示音
                if (_submittedOption == "bruhtimeout") {
                  _wrongTune();
                }
                if (answerList != null) {
                  if (answerList.any((item) =>
                      item.toLowerCase() == _submittedOption!.toLowerCase())) {
                    _correctTune();
                  } else {
                    _wrongTune();
                  }
                } else {
                  if (_submittedOption!.toLowerCase() == answer.toLowerCase()) {
                    _correctTune();
                  } else {
                    _wrongTune();
                  }
                }
                Future.delayed(
                    const Duration(seconds: 1), () => _audioPlayer.play());
              },
              child: Text(S.current.submit),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _submittedOption == "bruhtimeout"
                ? const Text("时间到")
                : _submittedOption!.toLowerCase() == answer.toLowerCase()
                    ? Text(S.current.correct,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green))
                    : answerList != null
                        ? answerList.any((item) =>
                                item.toLowerCase() ==
                                _submittedOption!.toLowerCase())
                            ? Text(S.current.correct,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green))
                            : Text(S.current.wrong,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red))
                        : Text(S.current.wrong,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
            const SizedBox(height: 10),
            if (_currentQuiz + 1 == _quizzes.length) ...[
              //结束
              ElevatedButton(
                onPressed: () {
                  _audioPlayer.stop();
                  logger.i(_resultList);
                  Navigator.pushReplacementNamed(
                      context, "/SinglePlayerGameResult",
                      arguments: {
                        "quizType": quizInfo['quizType'],
                        "playlistId": _playlistId,
                        "playlistTitle": _playlistTitle,
                        "difficulty": _difficulty,
                        "resultList": _resultList
                      });
                },
                child: Text(S.current.end),
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
                child: Text(S.current.next),
              ),
            ],
            if (_submittedOption != null) ...[
              Text(musicInfo),
              //播放控制
              Row(
                children: [
                  //播放/暂停按钮
                  IconButton(
                    onPressed: () {
                      _audioPlayer.playing
                          ? _audioPlayer.pause()
                          : _audioPlayer.play();
                    },
                    icon: _audioPlayer.playing
                        ? const Icon(Icons.pause)
                        : _audioPlayer.processingState != ProcessingState.ready
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
                : Image.file(File(_tempDir!.path + "/cover.jpg"),
                    width: MediaQuery.of(context).size.width * 0.3,
                    fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(_playlistTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
                "${S.current.difficulty}: ${_difficulty == 1 ? S.current.easy : _difficulty == 2 ? S.current.normal : _difficulty == 3 ? S.current.hard : S.current.custom}",
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
              if (_currentQuiz != -1 &&
                  _canShowQuiz &&
                  _quizzes[_currentQuiz.toString()] != null) ...[
                _showQuiz(_quizzes[_currentQuiz.toString()], _difficulty)
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
              "${S.current.difficulty}: ${_difficulty == 1 ? S.current.easy : _difficulty == 2 ? S.current.normal : _difficulty == 3 ? S.current.hard : S.current.custom}",
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
                    Image.file(File(_tempDir!.path + "/cover.jpg"),
                        width: 150, height: 150)
                  ],
                ],
              ),
              if (_currentQuiz != -1 &&
                  _canShowQuiz &&
                  _quizzes[_currentQuiz.toString()] != null) ...[
                _showQuiz(_quizzes[_currentQuiz.toString()], _difficulty)
              ],
            ],
          )
        ],
      ),
    );
  }

  Future<void> _init() async {
    _tempDir =
        Directory((await getTemporaryDirectory()).path + "/rhythm_riddle");
    logger.i(_tempDir!.path);
    if (!_tempDir!.existsSync()) {
      _tempDir!.create();
    }

    //获取题目
    _quizzes = await getQuiz(_playlistId, _difficulty, _tempDir!);
    if (_quizzes["error"] != null) {
      logger.e(_quizzes["error"]);
      _getQuizError = _quizzes["error"];
    }
    setState(() {
      _initialized = true;
    });
    print(_quizzes);
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized(); // 确保绑定已初始化
    Future.microtask(() {
      //获取传入参数
      final Map args = ModalRoute.of(context)?.settings.arguments as Map;
      setState(() {
        _playlistId = args["id"];
        _difficulty = args["difficulty"];
        _playlistTitle = args["title"];
      });
      _init();
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
        mounted &&
        _getQuizError == null) {
      _startAudioCountdown();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("${S.current.singlePlayer}: $_playlistTitle"),
      ),
      body: _getQuizError != null
          ? Center(child: Text("error❌: $_getQuizError!"))
          : !_initialized
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: MediaQuery.of(context).size.width > 800
                        ? _largeScreen()
                        : _smallScreen(),
                  )),
    );
  }
}
