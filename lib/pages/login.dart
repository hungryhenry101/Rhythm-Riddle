import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:rhythm_riddle/utils/error_handler.dart';

import '/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/update.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  String _errorMessage = '';
  String _loginText = "";
  Logger logger = Logger();

  String? _currentVersion;
  String? _latestVersion;
  String? _changelog;
  String? _date;
  bool _force = false;

  int _progress = 0;
  double _speed = 0.0;
  final CancelToken _cancelToken = CancelToken();
  DateTime? _startTime;

  bool _showHeadphoneWidget = false; // 控制过场动画是否显示
  late AnimationController _headphoneSceneController;
  late Animation<Offset> _slideAnimation;

  final _audioPlayer = AudioPlayer();

  Future<bool> _checkUpdate() async {
    try {
      Response res = await Dio().get(
        'https://hungryhenry.cn/rhythm_riddle/versions.json',
        options: Options(
          headers: {
            'Content-Type': 'application/json;charset=utf-8',
          },
        ),
      );
      if (res.statusCode == 200) {
        Map data = res.data;
        _latestVersion = data['latest']['version'];
        logger.i("latest v.: $_latestVersion");

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        _currentVersion = packageInfo.version;

        if (isUpdateAvailable(_currentVersion!, _latestVersion!)) {
          if (!mounted) return true;
          setState(() {
            _changelog = data['latest']['changlog'];
            _date = data['latest']['date'];
            if (data['latest']['force'] == true) {
              _force = true;
            }
          });
          return true;
        } else {
          return false;
        }
      } else {
        logger.e("version check error: ${res.statusCode} ${res.data}");
        return false;
      }
    } catch (e) {
      if(e is DioException && e.response != null){
        logger.e("version check error: ${e.message}, ${e.response}");
      }else{
        logger.e("version check error: $e");
      }
      return false;
    }
  }

  Future<void> _downloadUpdate() async {
    if (await checkPermission(Permission.storage)) {
      final Directory tempDir = await path_provider.getTemporaryDirectory();
      String? savePath;
      String url = "";

      if (Platform.isAndroid) {
        savePath = "${tempDir.path}/Rhythm-Riddle_$_latestVersion.apk";
        url =
            "https://hungryhenry.cn/rhythm_riddle/rhythm_riddle_android_latest.apk";

        if (await checkPermission(Permission.notification) == false) {
          if (mounted) {
            Fluttertoast.showToast(msg: AppLocalizations.of(context)!.permissionExplain);
          }
        }
        await NotificationService.init();
      } else if (Platform.isWindows) {
        savePath = "${tempDir.path}/Rhythm-Riddle_$_latestVersion.exe";
        url =
            "https://hungryhenry.cn/rhythm_riddle/rhythm_riddle_windows_latest.exe";
      } else {
        if (!mounted) return;
        ErrorHandler(context).unknownErrorDialog();
      }

      logger.i("savePath: $savePath");
      if (savePath != null && url != "") {
        try {
          await Dio().download(url, savePath, cancelToken: _cancelToken,
              onReceiveProgress: (received, total) {
            _startTime ??= DateTime.now(); // 如果starttime为null，则赋值为当前时间 :))))真高级
            Duration diff = DateTime.now().difference(_startTime!);

            if (mounted) {
              setState(() {
                _progress = ((received / total) * 100).toInt();
                if (received > 0 && total > 0 && diff.inSeconds > 0) {
                  _speed = (received / 1024 / 1024) / diff.inSeconds; // mb/s
                }
              });
            } else {
              _progress = ((received / total) * 100).toInt();
              if (received > 0 && total > 0 && diff.inSeconds > 0) {
                _speed = (received / 1024 / 1024) / diff.inSeconds;
              }
            }

            NotificationService.showProgressNotification(
                id: 1,
                title: AppLocalizations.of(context)!.dlUpdate,
                body:
                    "${AppLocalizations.of(context)!.downloading(_latestVersion!)} | ${_speed.toStringAsFixed(1)}mb/s",
                progress: _progress);
          });
          if (Platform.isAndroid) {
            if (await checkPermission(Permission.requestInstallPackages) ==
                false) {
              logger.e("request install packages permission error");
              if (mounted) {
                setState(() {
                  _loginText = AppLocalizations.of(context)!.restart;
                });
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text(
                            AppLocalizations.of(context)!.permissionError(AppLocalizations.of(context)!.installPerm)),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                if (await checkPermission(
                                        Permission.requestInstallPackages) ==
                                    false) {
                                  Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)!.permissionError(
                                          AppLocalizations.of(context)!.installPerm));
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login', (route) => false);
                                }
                              },
                              child: Text(AppLocalizations.of(context)!.retry)),
                          TextButton(
                              onPressed: () {
                                _launchInBrowser(Uri(
                                    scheme: "https",
                                    host: "hungryhenry.cn",
                                    path: "/rhythm_riddle/"));
                              },
                              child: Text(AppLocalizations.of(context)!.installManually))
                        ],
                      );
                    });
              }
            } else {
              //安装apk
              int? installCode = await AndroidPackageInstaller.installApk(
                  apkFilePath: savePath);
              if (installCode != 0) {
                logger.e("install apk error");
                if (mounted) {
                  ErrorHandler(context).unknownErrorDialog();
                }
              }
            }
          } else {
            //win
            Process process = await Process.start(savePath, [],
                mode: ProcessStartMode.detached);
            logger.i("start process: $process");
            exit(0);
          }
        } catch (e) {
          ErrorHandler(context).handle(e, HandleTypes.update);
        }finally{
          NotificationService.cancelNotification(1);          
        }
      } else {
        logger.e('savePath or url is null');
        if (mounted) {
          ErrorHandler(context).unknownErrorDialog();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loginText = AppLocalizations.of(context)!.restart;
        });
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text(AppLocalizations.of(context)!.permissionError(AppLocalizations.of(context)!.storagePerm)),
                actions: [
                  TextButton(
                      onPressed: () async {
                        Navigator.of(context).pushNamed('/login');
                      },
                      child: Text(AppLocalizations.of(context)!.retry)),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        openAppSettings();
                      },
                      child: Text(AppLocalizations.of(context)!.ok))
                ],
              );
            });
      }
    }
  }

  Future<void> _playAndNavigate() async {
    try {
      setState(() {
        _showHeadphoneWidget = true;
        _headphoneSceneController.forward();
      });
      await _audioPlayer.setAsset('assets/sounds/loginToHome.mp3');
      await _audioPlayer.play();
    } catch (e) {
      ErrorHandler(context).handle(e, HandleTypes.auth);
    }finally{
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  Future<void> _login(String username, String password, bool remember,BuildContext context) async {
    setState(() {
      _errorMessage = "";
    });
    _formKey.currentState?.validate();
    logger.i("_login with username: $username, remember: $remember");
    if (_formKey.currentState?.validate() != true 
        || username.isEmpty 
        || password.isEmpty 
        || !mounted){
      return;
    } 
    setState(() {
      _loginText = AppLocalizations.of(context)!.loggingIn;
    });
    try {
      final response = await Dio().post(
        'https://hungryhenry.cn/api/login.php',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'username': username,
          'password': password,
          'remember': remember ? '1' : '0',
        })).timeout(const Duration(seconds: 12));

      if (!mounted){
        _loginText = AppLocalizations.of(context)!.login;
        return;
      }

      if (response.statusCode == 200) {
        // LET'S GOOOOOO
        setState(() {
          _loginText = AppLocalizations.of(context)!.loginSuccess;
        });
        await storage.write(key: 'logged-in', value: "true");
        await storage.write(
            key: 'uid',
            value: response.data['data']['uid'].toString());
        await storage.write(
            key: 'username',
            value: response.data['data']['username']);
        await storage.write(
          key: 'token',
          value: response.data['data']['token'],
        );

        logger.i("navigating");
        _playAndNavigate();
      } else {
        logger.e("login error: ${response.statusCode} ${response.data}");
        if(!mounted) return;
        setState(() {
          _loginText = AppLocalizations.of(context)!.login; 
        });
        ErrorHandler(context).unknownErrorDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginText = AppLocalizations.of(context)!.login;
      });
      ErrorHandler(context).handle(
        e, 
        HandleTypes.auth, 
        authFailedHandler: (){
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.emailOrName +
              AppLocalizations.of(context)!.or +
              AppLocalizations.of(context)!.password +
              AppLocalizations.of(context)!.incorrect;
          });
          _formKey.currentState?.validate();
        }
      );
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        ) &&
        mounted) {
      ErrorHandler(context).unknownErrorDialog();
    }
  }

  Future<void> loginUsingToken() async {
    String? userId = await storage.read(key: 'uid');
    String? token = await storage.read(key: 'token');
    logger.i("userId: $userId, token: $token");
    if(token == null || userId == null) return;
    if (mounted) {
      setState(() {
        _loginText = AppLocalizations.of(context)!.loggingIn;
      });
      try{
        final response = await Dio().post(
          'https://hungryhenry.cn/api/refresh-token.php',
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          }),
          data: {'user_id': userId},
        );
        if(response.statusCode == 200){
          logger.i(response.data.runtimeType);
          await storage.write(key: 'logged-in', value: "true");
          await storage.write(key: 'token', value: response.data['data']['token']);
          setState(() {
            _loginText = AppLocalizations.of(context)!.loginSuccess;
          });
          _playAndNavigate();
        }else{
          if(!mounted) return;
          setState(() {
            _loginText = AppLocalizations.of(context)!.login;
          });
          ErrorHandler(context).unknownErrorDialog();
        }
      }catch(e){
        if (!mounted) return;
        setState(() {
          _loginText = AppLocalizations.of(context)!.login;
        });
        ErrorHandler(context).handle(
          e, 
          HandleTypes.auth,
          tokenExpiredFunction: () async {
            await storage.delete(key: 'token');
            final String? username = await storage.read(key: 'username');
            _emailController.text = username ?? '';
          }
        );
      }
    }
  }

  Widget _buildLoginPage() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Form(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25, bottom: 20),
              child: Text(
                _loginText,
                style: const TextStyle(fontSize: 42),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    // Email TextField
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.emailOrName,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context)!.emptyemail;
                        }
                        if (_errorMessage.isNotEmpty) {
                          return _errorMessage;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password TextField
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context)!.emptypassword;
                        }
                        if (_errorMessage.isNotEmpty) {
                          return _errorMessage;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Remember me checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text(
                          AppLocalizations.of(context)!.rememberMe,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    //register button
                    TextButton(
                        onPressed: () => setState(() {
                              _launchInBrowser(Uri(
                                  scheme: 'https',
                                  host: 'blog.hungryhenry.cn',
                                  path: '/admin/'));
                            }),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color.fromARGB(0, 0, 0, 0)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.register,
                          style: const TextStyle(fontSize: 14),
                        )),

                    // 登录按钮
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_loginText != AppLocalizations.of(context)!.loggingIn) {
                            FocusScopeNode currentFocus =
                                FocusScope.of(context);

                            /// 键盘是否回收
                            if (!currentFocus.hasPrimaryFocus &&
                                currentFocus.focusedChild != null) {
                              FocusManager.instance.primaryFocus!.unfocus();
                            }

                            _login(
                              _emailController.text, 
                              _passwordController.text, 
                              _rememberMe,
                              context
                            );
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.login),
                      )
                    ),

                    Text(
                      AppLocalizations.of(context)!.or,
                      style: const TextStyle(fontSize: 12),
                    ),

                    // 免登录进入
                    SizedBox(
                        child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            const Color.fromARGB(166, 151, 151, 151)),
                      ),
                      onPressed: () async {
                        _playAndNavigate();
                      },
                      child: Text(
                        AppLocalizations.of(context)!.guest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadPage() {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: min(500, MediaQuery.of(context).size.width - 20)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          AppLocalizations.of(context)!.downloading(_latestVersion!),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _progress / 100,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              "$_progress%",
            ),
            const Spacer(),
            Text(
              "${_speed.toStringAsFixed(1)}mb/s",
            )
          ],
        ),
        const SizedBox(height: 20),
        TextButton(
          child: Text(_startTime == null
              ? "${AppLocalizations.of(context)!.cancel}ing..."
              : AppLocalizations.of(context)!.cancel),
          onPressed: () {
            if (_startTime != null) {
              setState(() {
                _startTime = null;
                _progress = 0;
                _speed = 0.0;
                _loginText = AppLocalizations.of(context)!.login;
              });
              _cancelToken.cancel();
            }
          },
        )
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    _headphoneSceneController = AnimationController(
      duration: const Duration(seconds: 2), // 动画持续时间
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1), // 从屏幕底部进入
      end: Offset(0, 0), // 最终到达原位置
    ).animate(CurvedAnimation(
      parent: _headphoneSceneController,
      curve: Curves.easeOut, // 缓和效果
    ));
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(!_initialized){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        storage.write(key: 'logged-in', value: "false");
        setState(() {
          _loginText = AppLocalizations.of(context)!.checkingUpdate;
          _initialized = true;
        });
        _checkUpdate().then((needUpdate) {
          if (needUpdate && mounted) {
            showDialog(
                context: context,
                barrierDismissible: false, // 禁止点击对话框外部关闭
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0), // 圆角样式
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.update(_currentVersion!, _latestVersion!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              (_changelog ?? "") +
                                  "\n" +
                                  AppLocalizations.of(context)!.releaseDate(_date!),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (!_force) ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // 关闭对话框
                                loginUsingToken();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16.0,
                                ),
                              ),
                            )
                          ],
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loginText = AppLocalizations.of(context)!.downloading(_latestVersion!);
                              });
                              // 执行更新逻辑
                              Navigator.of(context).pop();
                              _downloadUpdate();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // 突出显示立即更新按钮
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.dlUpdate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                });
          } else if (!needUpdate && mounted) {
            setState(() {
              _loginText = AppLocalizations.of(context)!.login;
            });
            loginUsingToken();
          }
        }).catchError((e) {
          ErrorHandler(context).unknownErrorDialog();
        });
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _headphoneSceneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          //main page
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child:
                  _startTime == null ? _buildLoginPage() : _buildDownloadPage(),
            ),
          ),

          // headphone widget
          if (_showHeadphoneWidget)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones,
                          color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.wearHeadphone,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
