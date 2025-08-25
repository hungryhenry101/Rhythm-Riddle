// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get name => '这歌我熟';

  @override
  String get login => '登录';

  @override
  String get loggingIn => '登录中...';

  @override
  String get rememberMe => '7天内自动登录';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get or => '或';

  @override
  String get register => '没有账号? 点此注册!';

  @override
  String get guest => '免登录进入';

  @override
  String get logout => '退出登录';

  @override
  String get password => '密码';

  @override
  String get emailOrName => '邮箱/用户名';

  @override
  String get incorrect => '错误';

  @override
  String get emptyemail => '请输入邮箱';

  @override
  String get emptypassword => '请输入密码';

  @override
  String get unknownError => '未知错误，请重试或联系hungryhenry101@outlook.com';

  @override
  String get loginExpired => '登录已过期，请重新登录';

  @override
  String get loginFailed => '登录失败，请重试';

  @override
  String get connectError => '无法连接至服务器，请稍后再试或使用本地歌单游玩';

  @override
  String get versionCheckError => '版本检查失败，请稍后再试或联系hungryhenry101@outlook.com';

  @override
  String permissionError(Object permission) {
    return '缺少$permission，请手动授予权限';
  }

  @override
  String get permissionExplain => '请授予通知权限，以防止软件更新时被系统结束进程';

  @override
  String get storagePerm => '文件读写权限';

  @override
  String get ntfPerm => '通知权限';

  @override
  String get installPerm => '安装应用权限';

  @override
  String get restart => '授权后请重启软件';

  @override
  String get installManually => '手动下载安装';

  @override
  String get ok => '确定👌';

  @override
  String get cancel => '取消';

  @override
  String get relogin => '重新登录';

  @override
  String get retry => '重试';

  @override
  String get backToHome => '返回主页';

  @override
  String get back => '返回';

  @override
  String get loading => '加载中...';

  @override
  String get checkingUpdate => '检查更新中...';

  @override
  String update(Object latestVersion, Object version) {
    return '当前版本：$version，有新版本：$latestVersion';
  }

  @override
  String get downloadProgress => '下载进度：';

  @override
  String get dlUpdate => '立即下载';

  @override
  String releaseDate(Object date) {
    return '发布日期：$date';
  }

  @override
  String downloading(Object version) {
    return '正在下载$version...';
  }

  @override
  String get wearHeadphone => '请佩戴耳机以获得最佳体验';

  @override
  String get accountManage => '账户管理';

  @override
  String get history => '历史记录';

  @override
  String get setting => '设置';

  @override
  String get localPlaylists => '本地歌单';

  @override
  String get appearance => '外观';

  @override
  String get language => '语言';

  @override
  String get darkMode => '深色模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get gameSettings => '游戏设置';

  @override
  String get home => '主页';

  @override
  String get me => '我';

  @override
  String get rank => '排行榜';

  @override
  String get recm => '推荐';

  @override
  String get hot => '热门🔥';

  @override
  String get sort => '分类';

  @override
  String get search => '搜索歌单、歌曲或歌手';

  @override
  String get songs => '歌曲';

  @override
  String get played => '玩过';

  @override
  String get likes => '赞';

  @override
  String get downloaded => '已下载';

  @override
  String get download => '下载';

  @override
  String get loginRequired => '请先登录';

  @override
  String get bug => '游戏出现BUG了，请反馈给hungryhenry101@outlook.com';

  @override
  String get singlePlayer => '单人模式';

  @override
  String get multiPlayer => '多人模式（敬请期待）';

  @override
  String get singlePlayerOptions => '单人模式选项';

  @override
  String get multiPlayerOptions => '多人模式选项';

  @override
  String get creator => '创建者';

  @override
  String get createTime => '创建时间';

  @override
  String contains(Object artist, Object count, Object title) {
    return '包含 $title - $artist 等 $count 首歌曲';
  }

  @override
  String get noDes => '暂无简介';

  @override
  String get chooseDifficulty => '选择难度';

  @override
  String get difficulty => '难度';

  @override
  String get easy => '简单';

  @override
  String get normal => '普通';

  @override
  String get hard => '困难';

  @override
  String get custom => '自定义';

  @override
  String get easyInfo => '简单模式：5次失误机会，曲名或歌手4选1';

  @override
  String get normalInfo => '普通模式：3次失误机会，曲名或歌手或专辑 4选1或有提示的填空';

  @override
  String get hardInfo => '困难模式：2次失误机会，曲名或歌手或专辑填空';

  @override
  String get start => '开始游戏';

  @override
  String get submit => '提交';

  @override
  String get next => '下一题';

  @override
  String get end => '结束👉';

  @override
  String get chooseMusic => '选择当前播放的歌曲名';

  @override
  String get chooseArtist => '选择当前播放歌曲的歌手';

  @override
  String get chooseAlbum => '选择当前播放的所属专辑';

  @override
  String get chooseGenre => '选择当前播放的所属流派';

  @override
  String get enterMusic => '填写当前播放的歌曲名';

  @override
  String get enterArtist => '填写当前播放的歌曲的歌手';

  @override
  String get enterAlbum => '填写当前播放的所属专辑';

  @override
  String get enterGenre => '填写当前播放的所属流派';

  @override
  String get tip => '提示: ';

  @override
  String get correctAnswer => '正确答案: ';

  @override
  String get correct => '正确✔';

  @override
  String get wrong => '错误❌';

  @override
  String quizResult(Object playlist) {
    return '$playlist 的答题结果';
  }

  @override
  String get details => '答题细节';

  @override
  String get pts => '分';

  @override
  String get quizzes => '题';

  @override
  String get answer => '回答';

  @override
  String get answerTime => '回答用时';
}
