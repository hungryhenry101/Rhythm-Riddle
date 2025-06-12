import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '/generated/l10n.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:just_audio/just_audio.dart';

class SinglePlayerGameResult extends StatefulWidget {
  @override
  State<SinglePlayerGameResult> createState() => _SinglePlayerGameResultState();
}

class _SinglePlayerGameResultState extends State<SinglePlayerGameResult> {
  //用户信息
  static const storage = FlutterSecureStorage();
  String? _uid;
  String? _password;

  //传入参数
  List _resultList = [];
  int? _playlistId;
  String? _playlistTitle;
  int? _difficulty;

  Logger logger = Logger();

  //api返回数据
  Map? _responseData;
  int? _score;
  int? _likes;

  //本地计算数据
  int _answerTime = 0;
  int? _quizCount;
  int _correctCount = 0;
  bool _liked = false;

  //播放器
  final _audioPlayer = AudioPlayer();
  //播放变化监测变量
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processSubscription;
  StreamSubscription? _sequenceSubscription;

  String? _source;
  ProcessingState _processingState = ProcessingState.idle;
  bool get _loading => _processingState != ProcessingState.ready;
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

  Future<void> _postResult() async {
    try{
      final response = await http.post(
        Uri.parse('http://hungryhenry.xyz/api/result.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'player_id': _uid,
          'password': _password,
          'playlist_id': _playlistId.toString(),
          'score': _score,
          'quiz_count': _quizCount,
          'correct_count': _correctCount,
          'answer_time': _answerTime,
          'difficulty': _difficulty
        })
      ).timeout(const Duration(seconds:7));
      if(response.statusCode != 200){
        logger.e(response.statusCode);
        logger.e(response.body);
      }else{
        _likes = int.parse(response.headers['likes'] ?? "0");
        _liked = response.headers['liked'] == "1";
        logger.i("成功上传结果");
        logger.i(response.body);
      }
    }catch(e){
      if(e is TimeoutException && mounted && _score == null){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(context: context, builder: (context){
            return AlertDialog(
              content: Text(S.current.connectError),
              actions: [
                TextButton(onPressed: () {
                  Navigator.of(context).pop();
                }, child: Text(S.current.ok)),
              ],
            );
          });
        });
      }else{
        logger.e(_responseData);
        logger.e(e);
        if(mounted && _score == null){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(context: context, builder: (context){
              return AlertDialog(
                content: Text(S.current.unknownError),
                actions: [
                  TextButton(onPressed: () {Navigator.of(context).pop();}, 
                  child: Text(S.current.back))
                ],
              );
            });
          });
        }
      }
    }
  }

  Future<void> _like () async {
    try{
      if(_liked){
        setState(() {
          _liked = false;
          _likes == null ? _likes = 0 : _likes = _likes! - 1;
        });
        final response = await http.post(
          Uri.parse('http://hungryhenry.xyz/api/interact.php'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'player_id': _uid,
            'password': _password,
            'playlist_id': _playlistId,
            'action': 'unlike',
          })
        ).timeout(const Duration(seconds:12));
        if(response.statusCode != 200){
          setState(() {
            _likes = _likes! + 1;
            _liked = true;
          });
          logger.e(response.statusCode);
          logger.e(response.body);
        }else{
          logger.i("成功取消点赞");
          logger.d(response.body);
        }
      }else{
        setState(() {
          _liked = true;
          _likes == null ? _likes = 1 : _likes = _likes! + 1;
        });
        final response = await http.post(
          Uri.parse('http://hungryhenry.xyz/api/interact.php'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'player_id': _uid,
            'password': _password,
            'playlist_id': _playlistId,
            'action': 'like',
          })
        ).timeout(const Duration(seconds:12));
        if(response.statusCode != 200){
          setState(() {
            _likes = _likes! - 1;
            _liked = false;
          });
          logger.e(response.statusCode.toString() + response.body);
        }else{
          logger.i("成功点赞");
          logger.d(response.body);
        }
      }
    }catch(e){
      setState(() {
        _liked ? _liked = false : _liked = true;
        _liked ? _likes = _likes! + 1 : _likes = _likes! - 1;
      });
      if(e is TimeoutException){
        showDialog(context: context, builder:(context) {
          return AlertDialog(
            content: Text(S.current.connectError),
            actions: [
              TextButton(onPressed: () {
                Navigator.of(context).pop();
              }, child: Text(S.current.ok)),
            ],
          );
        });
      }else{
        logger.e(e);
        if(mounted){
          showDialog(context: context, builder: (context){
            return AlertDialog(
              content: Text(S.current.unknownError),
              actions: [
                TextButton(onPressed: () {Navigator.of(context).pop();}, 
                child: Text(S.current.back))
              ],
            );
          });
        }
      }
    }
  }

  void _computeCorrectCount() {
    int key = 0;
    for (var item in _resultList) {
      final submitText = item['submitText']?.toString().toLowerCase() ?? '';
      final answer = item['answer']?.toString().toLowerCase();
      final answerList = (item['answerList'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];

      // 判断逻辑
      bool isCorrect;
      if (item['options'] != null) {
        // 存在选项的情况：submitText 必须完全匹配 answer
        isCorrect = submitText == answer?.toLowerCase();
      } else {
        if (answer != null) {
          // 直接对比答案（不区分大小写）
          isCorrect = submitText == answer;
        } else {
          // 对比答案列表（不区分大小写）
          isCorrect = answerList.contains(submitText);
        }
      }

      if (isCorrect){
        _correctCount = _correctCount + 1;
        _resultList[key]['correct'] = true;
      }else{
        _resultList[key]['correct'] = false;
      }
      key++;
    }
  }

  @override
  void initState() {
    super.initState();

    //延迟执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        _uid = await storage.read(key: 'uid');
        _password = await storage.read(key: 'password');
        
        if(mounted){
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          if (args != null) {
            setState(() {
              _resultList = args['resultList'];
              _playlistId = args['playlistId'];
              _playlistTitle = args['playlistTitle'];
              _difficulty = args['difficulty'];
            });
            for(var item in _resultList) {
              _answerTime += (item["answerTime"] ?? "0") as int;
            }
            _quizCount = _resultList.length;
            _computeCorrectCount();
            _score = (_correctCount / _quizCount! * 10).round();

            if(_uid != null && _password != null){
              _postResult(); //上传结果
            }else{
              logger.i("未登录，无法上传结果");
            }
          }

          //状态更新
          _audioPlayer.playbackEventStream.listen((event) {}, onError: (error) {
            logger.e(error);
          });
          _durationSubscription = _audioPlayer.durationStream.listen((duration){
            if(mounted){setState(() => _duration = duration);}
          });

          _positionSubscription = _audioPlayer.positionStream.listen((position){
            if(mounted){setState(() => _position = position);}
          });

          _processSubscription =_audioPlayer.processingStateStream.listen((processingState){
            if(mounted){setState(() => _processingState = processingState);}
          });

          _audioPlayer.sequenceStateStream.listen((sequenceState){
            if (sequenceState != null) {
              final currentSource = sequenceState.currentSource;
              if (currentSource is UriAudioSource) {
                _source = currentSource.uri.toString();
              }
            }
          });
        }
      });
    });
  }
  
  @override
  void dispose() { //释放资源内存
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _processSubscription?.cancel();
    _sequenceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.quizResult(_playlistTitle ?? '')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _playlistId != null ? Image.network(
                "http://hungryhenry.xyz/musiclab/playlist/$_playlistId.jpg",
                width: MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ?
                MediaQuery.of(context).size.height * 0.45 : MediaQuery.of(context).size.width * 0.5,
              ) : const CircularProgressIndicator(),
              
              const SizedBox(height: 16),
              // 星星
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  double starValue = (_score != null ? _score! / 2 : 0.0) - index;
                  return _buildStar(starValue);
                }),
              ),
              const SizedBox(height: 16),
              // 分数
              Text(
                "${_score != null ? _score!.toStringAsFixed(1) : " - "} / 10.0 ${S.current.pts}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "$_correctCount / $_quizCount ${S.current.quizzes}",
                style: TextStyle(fontSize: 18, color: Colors.grey[800]),
              ),

              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 点赞
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            _like();
                          },
                          icon: Icon(Icons.thumb_up, color: _liked ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight),
                        ),
                        Text(_likes != null ? _likes.toString() : '0'), // 点赞数量
                      ],
                    ),
                    // 评论
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            // 评论逻辑
                          },
                          icon: Icon(Icons.comment, color: Theme.of(context).primaryColor)
                        ),
                        Text('5'), // 评论数量
                      ],
                    ),
                    // 分享
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            // 分享逻辑
                          },
                          icon: Icon(Icons.share, color: Theme.of(context).primaryColor)
                        ),
                        Text('7'), // 分享数量
                      ],
                    ),
                  ],
                ),
              ),
          
              const SizedBox(height: 16),
              Text(
                S.current.details,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),
              // 详细信息
              Wrap(
                spacing: 16.0, // Horizontal spacing between cards
                runSpacing: 16.0, // Vertical spacing between rows
                alignment: WrapAlignment.center,
                children:[
                  for (var item in _resultList)
                    SizedBox(
                      width:340,
                      height: 360,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ListView(
                            children: [
                              if(_audioPlayer.playing && _source ==
                              "http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3")...
                              [
                                //进度条
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
                                      if(!_audioPlayer.playing){
                                        _audioPlayer.play();
                                      }
                                    },
                                    value: (_position != null &&
                                            _duration != null &&
                                            _position!.inMilliseconds > 0 &&
                                            _position!.inMilliseconds < _duration!.inMilliseconds)
                                        ? _position!.inMilliseconds / _duration!.inMilliseconds
                                        : 0.0,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _position != null ? _positionText : '',
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _duration != null ? _durationText : '',
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                  ],
                                )
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: Text( //题目
                                      "${int.parse(item.key) + 1}. ${item['quizType'] == 0 ? S.current.chooseMusic
                                          : item['quizType'] == 1 ? S.current.chooseArtist
                                          : item['quizType'] == 2 ? S.current.chooseAlbum
                                          : item['quizType'] == 3 ? S.current.chooseGenre
                                          : item['quizType'] == 4 ? S.current.enterMusic
                                          : item['quizType'] == 5 ? S.current.enterArtist
                                          : item['quizType'] == 6 ? S.current.enterAlbum
                                          : item['quizType'] == 7 ? S.current.enterGenre
                                          : "WTF??HOW??"}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          
                                  //播放按钮
                                  _loading && _source == 
                                  "http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3" ? 
                                  const CircularProgressIndicator() :
                                  IconButton(
                                    icon: _source == null || !_audioPlayer.playing ? (
                                      const Icon(Icons.play_arrow)
                                    ):(
                                      _source == 
                                      "http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3") ? 
                                        const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                                    onPressed: () async{
                                      try{
                                        if(!_audioPlayer.playing){
                                          if(_source == null || 
                                            _source != 
                                              "http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3")
                                          {
                                            await _audioPlayer.stop();
                                            await _audioPlayer.setUrl("http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3");
                                            _audioPlayer.play();
                                          }else{
                                            _audioPlayer.play();
                                          }
                                        }else{
                                          if(_source == 
                                          "http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3")
                                          {
                                            await _audioPlayer.pause();
                                          } else{
                                            await _audioPlayer.setUrl("http://hungryhenry.xyz/musiclab/music/${item['musicId']}.mp3");
                                            _audioPlayer.play();
                                          }
                                        }
                                      }catch(e){
                                        if(e is TimeoutException && mounted){
                                          showDialog(context: context, builder: (context){
                                            return AlertDialog(
                                              content: Text(S.current.connectError),
                                              actions: [
                                                TextButton(onPressed: () { Navigator.pop(context);
                                                }, child: Text(S.current.back)),
                                              ],
                                            );
                                          });
                                        }else{
                                          logger.e(e);
                                          if(mounted){
                                            showDialog(context: context, builder: (context){
                                              return AlertDialog(
                                                  content: Text(S.current.unknownError),
                                                  actions: [
                                                    TextButton(onPressed: () { 
                                                      Navigator.of(context).pushNamedAndRemoveUntil('/home', arguments: _playlistId, (route) => false);
                                                      Navigator.of(context).pushNamed('/PlaylistInfo', arguments: _playlistId);
                                                    }, child: Text(S.current.back)),
                                                  ],
                                              );
                                            });
                                          }
                                        }
                                      }
                                    }
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              if(item['options'] != null)...[
                                for (var option in item['options'])...[
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: (option) == item['answer']
                                            ? Colors.green : Colors.red,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: (option) == item['submitText']
                                          ? option == item["answer"] 
                                          ? const Icon(Icons.check, color: Colors.green)
                                          : const Icon(Icons.close, color: Colors.red) : null,
                                      title: Text((option)),
                                    ),
                                  )
                                ],
                                const SizedBox(height: 5),
                                Text("用时：${item['answerTime']}s", textAlign: TextAlign.center)
                              ]else ...[
                                ListTile(
                                  trailing: _resultList[item.key]['correct'] ? 
                                  const Icon(Icons.check, color: Colors.green) : 
                                  const Icon(Icons.close, color: Colors.red),
                                  title: Text("输入："+item['submitText']),
                                ),
                                ListTile(
                                  title: Text("答案：${item['answer'] ?? item['answerList'].join(", ")}"
                                  ),
                                ),
                                ListTile(
                                  title: Text("回答用时：${item['answerTime']}s"),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                ]
              ),
              const SizedBox(height: 16),
              // 返回按钮
              ElevatedButton(
                child: Text(S.current.back),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', arguments: _playlistId, (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStar(double value) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        const Icon(
          Icons.star_border, // 背景未选中的星星
          size: 40,
          color: Colors.grey,
        ),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: value > 1
                ? 1
                : value > 0
                    ? value
                    : 0,
            child: const Icon(
              Icons.star, // 前景已选中的星星
              size: 40,
              color: Colors.amber,
            ),
          ),
        ),
      ],
    );
  }
}