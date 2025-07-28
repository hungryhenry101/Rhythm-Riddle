import 'dart:async';
import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = true;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    search("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        title: Container(
          padding: EdgeInsets.only(
            right: MediaQuery.of(context).size.width > 600 ? 35 : 15,
            left: 13,
          ),
          height: 38,
          alignment: Alignment.center,
          child: TextField(
            controller: _controller, // 关联控制器
            decoration: InputDecoration(
              hintText: S.current.search,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: TextButton(
                onPressed: () {
                  String searchQuery = _controller.text; // 获取输入内容
                  search(searchQuery);
                },
                child: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (value) {
              search(value);
            },
          ),
        ),
      ),
      body: Center(
        child: isLoading ? const CircularProgressIndicator() : Column(
          children:[
            Text("Load"),
            Text("finished")
          ]
        )
      ),
    );
  }

  Future<void> search(String query) async {
    try{
      final response = await http.post(
        Uri.parse('https://hungryhenry.cn/api/search_playlist.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'query': query,
        })
      ).timeout(const Duration(seconds:7));
      isLoading = false;
    }catch(e){
      logger.e("load error: $e");
      if(e is TimeoutException && mounted){
        await showDialog(context: context, builder: (context){
          return AlertDialog(
            content: Text(S.current.connectError),
            actions: [
              TextButton(onPressed: () {Navigator.pushNamed(context, '/search');}, child: Text(S.current.retry)),
              TextButton(onPressed: () {Navigator.pushNamed(context, '/home');}, child: Text(S.current.backToHome)),
            ],
          );
        });
      }else{
        if(mounted){
          await showDialog(context: context, builder: (context){
            return AlertDialog(
              content: Text(S.current.unknownError),
              actions: [
                TextButton(onPressed: () {Navigator.pushNamed(context, '/search');}, child: Text(S.current.retry)),
                TextButton(onPressed: () {Navigator.of(context).pop(false);}, child: Text(S.current.backToHome)),
              ],
            );
          });
        }
      }
    }
    
    setState(() {
      searchResults.add(query); // 将搜索查询添加到数组中
    });
  }
}
