import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '/generated/l10n.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:just_audio/just_audio.dart';
import '/models/result.dart';
import './result_card.dart';

class SinglePlayerGameResult extends StatefulWidget {
  @override
  State<SinglePlayerGameResult> createState() => _SinglePlayerGameResultState();
}

class _SinglePlayerGameResultState extends State<SinglePlayerGameResult> {
  int _currentPage = 0;
  //用户信息
  static const storage = FlutterSecureStorage();
  String? _uid;
  String? _password;

  //传入参数
  List<Result> _resultList = [];
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

  Future<void> _postResult() async {
    try{
      final response = await http.post(
        Uri.parse('https://hungryhenry.cn/api/result.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'player_id': _uid,
          'password': _password,
          'playlist_id': _playlistId,
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
          Uri.parse('https://hungryhenry.cn/api/interact.php'),
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
          Uri.parse('https://hungryhenry.cn/api/interact.php'),
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
    for (var item in _resultList) {
      if (submissionCorrect(item)){
        _correctCount++;
      }
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
              _answerTime += item.answerTime;
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
        }
      });
    });
  }
  
  @override
  void dispose() { //释放资源内存
    _audioPlayer.dispose();
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
                "https://hungryhenry.cn/musiclab/playlist/$_playlistId.jpg",
                width: MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ?
                MediaQuery.of(context).size.height * 0.45 : MediaQuery.of(context).size.width * 0.5,
              ) : const CircularProgressIndicator(),

              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  double starValue = (_score != null ? _score! / 2 : 0.0) - index;
                  return _buildStar(starValue);
                }),
              ),
              const SizedBox(height: 5),

              Text(
                "$_correctCount / $_quizCount ${S.current.quizzes}",
                style: TextStyle(fontSize: 18),
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
              // 详细信息（左右滑动切换卡片，仅当前卡片加载音频）
              SizedBox(
                height: 380,
                child: PageView.builder(
                  itemCount: _resultList.length,
                  controller: PageController(initialPage: _currentPage, viewportFraction: 0.95),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _resultList[index];
                    return Center(
                      child: SizedBox(
                        width: 340,
                        height: 360,
                        child: ResultCard(
                          result: item,
                          index: index,
                          active: index == _currentPage,
                        ),
                      ),
                    );
                  },
                ),
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
                ? 1 : value > 0
                  ? value : 0,
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