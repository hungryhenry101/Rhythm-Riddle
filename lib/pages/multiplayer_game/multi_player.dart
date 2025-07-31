import 'package:flutter/material.dart';
import '/generated/app_localizations.dart';
import 'package:http/http.dart' as http;

class MultiPlayer extends StatefulWidget {
  const MultiPlayer({Key? key}) : super(key: key);

  @override
  State<MultiPlayer> createState() => _MultiPlayerState();
}

class _MultiPlayerState extends State<MultiPlayer> {
  int playlistId = 0;
  String playlistTitle = '';
  String createTime = '';
  String createdBy = '';
  String musicTitle = '';
  String artist = '';
  int musicCount = 0;
  String? description;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final Map args = ModalRoute.of(context)?.settings.arguments as Map;
      setState(() {
        playlistId = args["id"];
        playlistTitle = args["title"];
        createTime = args["createTime"];
        createdBy = args["createdBy"];
        musicTitle = args["musicTitle"];
        artist = args["artist"];
        description = args["description"];
        musicCount = args["count"];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${AppLocalizations.of(context)!.multiPlayer}: $playlistTitle")),
      body: Center(
        //输出歌单所有信息
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(playlistTitle),
            Text(createTime),
            Text(createdBy),
            Text(musicTitle),
            Text(artist),
            Text(description ?? ''),
            Text(musicCount.toString()),
          ]
        )
      )
    );
  }
}