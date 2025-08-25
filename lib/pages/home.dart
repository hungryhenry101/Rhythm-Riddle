import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '/generated/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

const storage = FlutterSecureStorage();

class Home extends StatefulWidget{
  const Home({super.key});
  @override
  State createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Logger logger = Logger();
  int _currentPageIndex = 0;
  List<dynamic> _playlists = [];
  String? _uid;
  bool _isLogin = false;
  bool _isLoading = true;
  bool _loadingTimeOut = false;

  void showDialogFunction(String title) async {
    await showDialog(context: context, builder: (context){
      return AlertDialog(
          content: Text(title),
          actions: [
              TextButton(onPressed: () {Navigator.of(context).pop(false);}, child: Text(AppLocalizations.of(context)!.ok)),
          ],
      );
    });
  }

  Future<void> getData() async {
    _uid = await storage.read(key:'uid');
    final String? loggedIn = await storage.read(key:'logged-in');
    if(_uid != null && loggedIn == 'true' && mounted){
      setState(() {
        _isLogin = true;
      });
    }

    _isLoading = true;
    _loadingTimeOut = false;

    try{
      final response = await Dio().post(
        'https://hungryhenry.cn/api/get_playlist.php',
        options: Options(headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        })
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200 && mounted) {
        setState((){
          _playlists = response.data['data'];
          if(_playlists.length > 5){
            _playlists = _playlists.sublist(0, 5);
          }
          _isLoading = false;
        });
      }else {
        // 错误
        if(mounted){
          setState((){
            _playlists = [{"id": 0, "title": "error"}];
          });
          logger.i(response.data);
        }
      }
    }catch (e){
      showDialogFunction(AppLocalizations.of(context)!.connectError);
      setState(() {
        _loadingTimeOut = true;
        _isLoading = false;
      });
    }
  }
  
  Future<void> logout(BuildContext context) async {
    final token = await storage.read(key: 'token');
    try{
      Response response = await Dio().post(
        'https://hungryhenry.cn/api/logout.php',
        options: Options(headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token}'
        }),
        data: jsonEncode({
          'uid': _uid,
        })
      );
      if(response.statusCode == 200){
        await storage.delete(key: 'token');
        await storage.delete(key: 'uid');
        if(!context.mounted) return;
        Navigator.pushNamed(context, '/login');
      }else{
        throw Exception('logout failed');
      }
    }catch (e){
      if(e is TimeoutException){
        showDialogFunction(AppLocalizations.of(context)!.connectError);
      } else if(e is DioException){
        if(e.response != null){
          logger.e('Dio error!');
          logger.e('STATUS: ${e.response?.statusCode}');
          logger.e('DATA: ${e.response?.data}');
          logger.e('HEADERS: ${e.response?.headers}');
          showDialogFunction(AppLocalizations.of(context)!.unknownError);
        }else{
          // Something happened in setting up or sending the request that triggered an Error
          logger.e('Error sending request!');
          logger.e(e.message);
          showDialogFunction(AppLocalizations.of(context)!.connectError);
        }
      }
      await storage.delete(key: 'token');
      await storage.delete(key: 'uid');
      if(!context.mounted) return;
      Navigator.pushNamed(context, '/login');
    }
  }

  Widget _buildHome(){
    return RefreshIndicator(
      onRefresh: getData,
      color: const Color(0xFF009688),
      backgroundColor: const Color(0xFFE0F2F1),
      child: ListView(children:[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SafeArea(
                    child: GestureDetector(
                      onTap: () {Navigator.of(context).pushNamed('/search');},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.search,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if(Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh), 
                                color: Colors.grey, 
                                onPressed: (){
                                  getData();
                                },
                              )
                            ]
                          ],
                        ),
                      ),
                    )
                  ),
                  const SizedBox(height: 30),
      
                  // 推荐
                  SizedBox(
                    height: 170, // 固定推荐部分的高度
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.recm,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('更多 =>', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if(_isLoading) ...[
                          const Center(child: CircularProgressIndicator()),
                        ] else if(_loadingTimeOut) ...[
                          Center(
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: (){
                                    getData();
                                  }, 
                                  icon: const Icon(Icons.refresh),
                                ),
                                Text(AppLocalizations.of(context)!.retry),
                              ]
                            ),
                          ),
                        ]else...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              _playlists.length > 4 && (Platform.isAndroid || Platform.isIOS) ? 4 : _playlists.length, (index) {
                              return SizedBox(
                                width: 80,
                                height: 120,
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          '/PlaylistInfo',
                                          arguments: _playlists[index]['id']
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(0),
                                        ),
                                        fixedSize: const Size(70, 70),
                                        padding: const EdgeInsets.all(0),
                                      ),
                                      child: SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: Image.network(
                                          "https://hungryhenry.cn/musiclab/playlist/${_playlists[index]['id']}.jpg",
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            } else {
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null ? 
                                                  loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : 1,
                                                ),
                                              );
                                            }
                                          },
                                          errorBuilder: (BuildContext context,
                                              Object exception, StackTrace? stackTrace) {
                                                debugPrint(exception.toString());
                                            return const Icon(Icons.image,
                                                color: Colors.grey);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Expanded(
                                      child: Text(_playlists[index]['title'],
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    )
                                  ],
                                ),
                              );
                            }),  
                          ),
                        ]
                      ],
                    ),
                  ),
      
                  const SizedBox(height: 20),
      
                  // 热门
                  SizedBox(
                    height: 150, // 固定热门部分的高度
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.hot,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('更多 =>', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                                const SizedBox(height: 5),
                                const Text('blah'),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
      
                  const SizedBox(height: 20),
      
                  // 分类
                  SizedBox(
                    height: 150, // 固定分类部分的高度
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.sort,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('更多 =>', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                                const SizedBox(height: 5),
                                const Text('blah'),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAccount() {
    return SingleChildScrollView(
      child: Center(
        child:Container(
          padding: const EdgeInsets.all(16.0),
          width:700,
          child:Column(
            children: [
              Center(
                child: _isLogin ? CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(
                    "https://hungryhenry.cn/blog/usr/uploads/avatar/$_uid.png",
                  )             
                ) : ElevatedButton(
                  child: const Text('登录'),
                  onPressed: () => Navigator.of(context).pushNamed('/login')
                ),
              ),
              const SizedBox(height: 20),
              ListTileTheme(
                data: const ListTileThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))
                  ),
                ),
                child: Column(
                  children:[
                    //account manage
                    ListTile(
                      leading: const Icon(Icons.person),
                      enabled: _isLogin,
                      title: Text(
                        AppLocalizations.of(context)!.accountManage,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: (){
                        print("accountManage");
                      },
                    ),
                    const Divider(
                      height: 1, // 高度为1，紧凑的效果
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),

                    //history
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        AppLocalizations.of(context)!.history,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: (){
                        print("history");
                      },
                    ),

                    //my playlists
                    const Divider(
                      height: 1,
                      thickness: 1, 
                      indent: 16,
                      endIndent: 16,
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add_check),
                      title: Text(
                        AppLocalizations.of(context)!.localPlaylists,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded), 
                      onTap: (){
                        Navigator.of(context).pushNamed('/localPlaylists');
                      },
                    ),
                    
                    const Divider(
                      height: 1,
                      thickness: 1, 
                      indent: 16,
                      endIndent: 16,
                    ),

                    //settings
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: Text(
                        AppLocalizations.of(context)!.setting,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: (){
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),

                    //logout button
                    const Divider(
                      height: 1,
                      thickness: 1, 
                      indent: 16,
                      endIndent: 16,
                    ), 
                    ListTile(
                      leading: const Icon(Icons.logout),
                      enabled: _isLogin,
                      title: Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      onTap: (){
                        logout(context);
                      },
                    ),
                  ]
                )
              )
            ],
          )
        )
      ) 
    );
  }

  @override
  void initState(){
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),

      //navbar
      bottomNavigationBar:NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: const Icon(Icons.sports_esports),
            icon: const Icon(Icons.sports_esports_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.workspace_premium),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: AppLocalizations.of(context)!.rank,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.account_box),
            icon: const Icon(Icons.account_box_outlined),
            label: AppLocalizations.of(context)!.me,
          ),
        ]
      ),

      body: <Widget>[
        _buildHome(),
        /// Rank Page
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              "开发中，敬请期待",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)
            )
          )
        ),
        _buildAccount()
      ][_currentPageIndex]
    );
  }
  String _getAppBarTitle(){
    switch (_currentPageIndex) {
    case 0:
      return AppLocalizations.of(context)!.home;
    case 1:
      return AppLocalizations.of(context)!.rank;
    case 2:
      return AppLocalizations.of(context)!.me;
    default:
      return AppLocalizations.of(context)!.home;
    }
  }
}