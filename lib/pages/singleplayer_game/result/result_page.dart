import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rhythm_riddle/utils/error_handler.dart';
import '/generated/app_localizations.dart';
import 'package:dio/dio.dart';
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
  String? _token;

  //传入参数
  List<Result> _resultList = [];
  int? _playlistId;
  String? _playlistTitle;
  int? _difficulty;

  Logger logger = Logger();

  //api返回数据
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
      final response = await Dio().post(
        'https://hungryhenry.cn/api/result.php',
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }),
        data: jsonEncode({
          'player_id': _uid,
          'token': _token,
          'playlist_id': _playlistId,
          'score': _score,
          'quiz_count': _quizCount,
          'correct_count': _correctCount,
          'answer_time': _answerTime,
          'difficulty': _difficulty
        })
      ).timeout(const Duration(seconds:7));
      if(response.statusCode != 200){
        throw Exception("上传结果失败: " + response.data);
      }else{
        _likes = int.parse(response.data['likes'] ?? "0");
        _liked = response.data['liked'] == "1";
        logger.i("成功上传结果");
        logger.i(response.data);
      }
    }catch(e){
      if(!mounted) return;
      ErrorHandler(context).handle(e, HandleTypes.other);
    }
  }

  Future<void> _like () async {
    if(_token == null || _uid == null){
      showDialog(context: context, builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context)!.loginRequired),
          actions: [
            TextButton(onPressed: () {
              Navigator.of(context).pop();
            }, child: Text(AppLocalizations.of(context)!.ok)),
          ],
        );
      });
      return;
    }
    try{
      if(_liked){
        setState(() {
          _liked = false;
          _likes == null ? _likes = 0 : _likes = _likes! - 1;
        });
        final response = await Dio().post(
          'https://hungryhenry.cn/api/interact.php',
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }),
          data: jsonEncode({
            'player_id': _uid,
            'token': _token,
            'playlist_id': _playlistId,
            'action': 'unlike',
          })
        ).timeout(const Duration(seconds:12));
        if(response.statusCode != 200){
          setState(() {
            _likes = _likes! + 1;
            _liked = true;
          });
          throw Exception("取消点赞失败: " + response.data);
        }else{
          logger.i("成功取消点赞");
          logger.d(response.data);
        }
      }else{
        setState(() {
          _liked = true;
          _likes == null ? _likes = 1 : _likes = _likes! + 1;
        });
        final response = await Dio().post(
          'https://hungryhenry.cn/api/interact.php',
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }),
          data: jsonEncode({
            'player_id': _uid,
            'token': _token,
            'playlist_id': _playlistId,
            'action': 'like',
          })
        ).timeout(const Duration(seconds:12));
        if(response.statusCode != 200){
          setState(() {
            _likes = _likes! - 1;
            _liked = false;
          });
          throw Exception("点赞失败: " + response.data);
        }else{
          logger.i("成功点赞");
          logger.d(response.data);
        }
      }
    }catch(e){
      if(!mounted) return;
      setState(() {
        _liked ? _liked = false : _liked = true;
        _liked ? _likes = _likes! + 1 : _likes = _likes! - 1;
      });
      ErrorHandler(context).handle(e, HandleTypes.other);
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
        _token = await storage.read(key: 'token');
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

            if(_uid != null && _token != null){
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
        title: Text(AppLocalizations.of(context)!.quizResult(_playlistTitle ?? '')),
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
                "$_correctCount / $_quizCount ${AppLocalizations.of(context)!.quizzes}",
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
                AppLocalizations.of(context)!.details,
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
                        height: 380,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ResultCard(
                                result: item,
                                index: index,
                                active: index == _currentPage,
                              ),
                            ),
                            // 右边
                            if (index < _resultList.length - 1)
                              Positioned(
                                right: -10,
                                bottom: 20,
                                child: const RingConnector(),
                              ),
                            // 左边
                            if (index > 0)
                              Positioned(
                                left: -10,
                                bottom: 20,
                                child: const RingConnector(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 返回按钮
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.back),
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