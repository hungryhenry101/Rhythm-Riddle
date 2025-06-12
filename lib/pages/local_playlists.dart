import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
class LocalPlaylistsPage extends StatefulWidget {
  @override
  _LocalPlaylistsPageState createState() => _LocalPlaylistsPageState();
}

class _LocalPlaylistsPageState extends State<LocalPlaylistsPage> {
  late Directory _documentsDirectory;
  late File _localPlaylistsJson;
  Directory? _tempDir;
  List? _localPlaylists;

  Future<void> _unzipCover() async{
    _tempDir = Directory((await getTemporaryDirectory()).path + '/rhythm_riddle/cover');
    if(!_tempDir!.existsSync()){
      _tempDir!.createSync(recursive: true);
    }
    final playlistDir = Directory('${_documentsDirectory.path}/playlists');
    for(final item in _localPlaylists!){
      final id = item['id'];
      final bytes = await File('${playlistDir.path}/$id.zip').readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final coverInZip = archive.firstWhere((file) => file.name == "cover.jpg");
      final coverBytes = coverInZip.content;
      //解压至tempdir
      final unzipCoverFile = File('${_tempDir!.path}/$id.jpg');
      if(!unzipCoverFile.existsSync()){
        unzipCoverFile.writeAsBytesSync(coverBytes);
      }
    }
  }
  
  @override 
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((directory) {
      _documentsDirectory = Directory(directory.path + '/rhythm_riddle');
      _localPlaylistsJson = File('${_documentsDirectory.path}/local_playlists.json');
      if(!_documentsDirectory.existsSync()){
        _documentsDirectory.createSync();
      }
      if (_localPlaylistsJson.existsSync()) {
        _localPlaylistsJson.readAsString().then((jsonString) {
          setState(() {
            _localPlaylists = json.decode(jsonString);
          });
          _unzipCover();
        }); 
      } else {
        _localPlaylistsJson.createSync();
        setState(() {
          _localPlaylists = [];
        });
        _localPlaylistsJson.writeAsStringSync("[]");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('本地歌单'),
      ),
      body: Center(
        child: _localPlaylists == null || (_tempDir == null && _localPlaylists != []) ? const CircularProgressIndicator() :
        Container(
          padding: const EdgeInsets.all(16.0),
          constraints: const BoxConstraints(maxWidth: 600),
          child: _localPlaylists!.isEmpty ? Center(child: Text('暂无歌单，去你喜欢的歌单下载吧')) : 
          Column(
            children: [
              Text("本地歌单（离线开玩）", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) { // <-- SEE HERE
                    return const Divider();
                  },
                  itemCount: _localPlaylists!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onLongPress: (){
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('删除歌单'),
                              content: Text('确定要删除${_localPlaylists![index]['title']}吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('删除'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onTap: (){
                        //难度选择提示框
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('选择歌曲难度'),
                              actions: [
                                Row(
                                  children:[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('取消', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamedAndRemoveUntil(
                                          "/OfflineGame", 
                                          (route) => false, 
                                          arguments: {
                                            "id": _localPlaylists![index]['id'], 
                                            "difficulty": 1,
                                            "title": _localPlaylists![index]['title'],
                                          }
                                        );
                                      },
                                      child: Text('简单'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamedAndRemoveUntil(
                                          "/OfflineGame", 
                                          (route) => false, 
                                          arguments: {
                                            "id": _localPlaylists![index]['id'], 
                                            "difficulty": 2,
                                            "title": _localPlaylists![index]['title'],
                                          }
                                        );
                                      },
                                      child: Text('中等'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamedAndRemoveUntil(
                                          "/OfflineGame", 
                                          (route) => false, 
                                          arguments: {
                                            "id": _localPlaylists![index]['id'], 
                                            "difficulty": 3,
                                            "title": _localPlaylists![index]['title'],
                                          }
                                        );
                                      },
                                      child: Text('困难'),
                                    ),
                                  ]
                                )
                              ],
                            );
                          }
                        );
                      },
                      child: ListTile(
                        leading: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(File("${_tempDir!.path}/${_localPlaylists![index]['id']}.jpg")),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          )
                        ),
                        
                        title: Text(_localPlaylists![index]['title']),
                        subtitle: Text(_localPlaylists![index]['count'].toString() + "首歌曲"),
                        hoverColor: Colors.grey,
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[600]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('删除歌单'),
                                  content: Text('确定要删除${_localPlaylists![index]['title']}吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('删除'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      )
                    );
                  }
                ),
              ),
            ],
          )
        )
      )
    );
  }
}