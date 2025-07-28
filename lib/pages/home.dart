import 'dart:io';

import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const storage = FlutterSecureStorage();

class Home extends StatefulWidget{
  const Home({super.key});
  @override
  State createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentPageIndex = 0;
  List<dynamic> _playlists = [];
  String? _uid = '';
  String? _username = '';
  String? _password = '';
  String? _mail = '';
  bool _isLogin = false;
  bool _isLoading = true;
  bool _loadingTimeOut = false;

  void showDialogFunction(String title) async {
    await showDialog(context: context, builder: (context){
      return AlertDialog(
          content: Text(title),
          actions: [
              TextButton(onPressed: () {Navigator.of(context).pop(false);}, child: Text(S.current.ok)),
          ],
      );
    });
  }

  Future<void> getData() async {
    _uid = await storage.read(key:'uid');
    _username = await storage.read(key:'username');
    _password = await storage.read(key:'password');
    _mail = await storage.read(key:'mail');
    if(_uid != null && _username != null && _password != null && _mail != null && mounted){
      setState(() {
        _isLogin = true;
      });
    }

    _isLoading = true;
    _loadingTimeOut = false;

    try{
      final response = await http.post(
        Uri.parse('https://hungryhenry.cn/api/get_playlist.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        }
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200 && mounted) {
        setState((){
          _playlists = jsonDecode(response.body)['data'];
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
          print(response.body);
        }
      }
    }catch (e){
      showDialogFunction(S.current.connectError);
      setState(() {
        _loadingTimeOut = true;
        _isLoading = false;
      });
    }
  }
  
  Future<void> logout(BuildContext context) async {
    await storage.delete(key: 'username');
    await storage.delete(key: 'password');
    await storage.delete(key: 'mail');
    await storage.delete(key: 'uid');
    if(!context.mounted) return;
    Navigator.pushNamed(context, '/login');
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
                              S.current.search,
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
                            Text(S.current.recm,
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
                                Text(S.current.retry),
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
                            Text(S.current.hot,
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
                            Text(S.current.sort,
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
                        S.current.accountManage,
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
                        S.current.history,
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
                        S.current.localPlaylists,
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
                        S.current.setting,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: (){
                        Navigator.of(context).pushNamed('/settings');
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
            label: S.current.home,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.workspace_premium),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: S.current.rank,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.account_box),
            icon: const Icon(Icons.account_box_outlined),
            label: S.current.me,
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
      return S.current.home;
    case 1:
      return S.current.rank;
    case 2:
      return S.current.me;
    default:
      return S.current.home;
    }
  }
}