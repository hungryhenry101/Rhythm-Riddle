// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get name => 'Rhythm Riddle';

  @override
  String get login => 'Login';

  @override
  String get loggingIn => 'Loggin In...';

  @override
  String get rememberMe => 'Remember me in 7 days';

  @override
  String get loginSuccess => 'Login Success';

  @override
  String get or => 'or';

  @override
  String get register => 'No account? Click here to sign up!';

  @override
  String get guest => 'offline mode';

  @override
  String get logout => 'Logout';

  @override
  String get password => 'Password';

  @override
  String get emailOrName => 'E-mail/Username';

  @override
  String get incorrect => 'incorrect';

  @override
  String get emptyemail => 'Please enter your email';

  @override
  String get emptypassword => 'Please enter your password';

  @override
  String get unknownError =>
      'Unknown error, please contact hungryhenry101@outlook.com';

  @override
  String get loginExpired => 'Login session expired, please login again';

  @override
  String get loginFailed => 'Login failed, please try again';

  @override
  String get connectError =>
      'Cannot connect to server. Pls try again later or use offline mode';

  @override
  String get versionCheckError =>
      'Cannot check version. Pls try again later or contact hungryhenry101@outlook.com';

  @override
  String permissionError(Object permission) {
    return 'Lack of $permission. Pls grant perm(s) manually';
  }

  @override
  String get permissionExplain =>
      'Pls grant notification permission to prevent the process from killing by system';

  @override
  String get storagePerm => 'Storage Permission';

  @override
  String get ntfPerm => 'Notification Permission';

  @override
  String get installPerm => 'Install Packages Permission';

  @override
  String get restart => 'Restart the App After Granting';

  @override
  String get installManually => 'Dload and Install by Browser';

  @override
  String get ok => 'OK👌';

  @override
  String get cancel => 'Cancel';

  @override
  String get relogin => 'Re-Login';

  @override
  String get retry => 'Retry';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading...';

  @override
  String get checkingUpdate => 'Checking updates...';

  @override
  String update(Object latestVersion, Object version) {
    return 'Curr ver.: $version, new ver. available: $latestVersion';
  }

  @override
  String get downloadProgress => 'Download Progress: ';

  @override
  String get dlUpdate => 'Update Now';

  @override
  String releaseDate(Object date) {
    return 'Release Date: $date';
  }

  @override
  String downloading(Object version) {
    return 'Downloading $version...';
  }

  @override
  String get wearHeadphone =>
      'Please wear your headphones for a better experience';

  @override
  String get accountManage => 'Account Management';

  @override
  String get history => 'History';

  @override
  String get setting => 'Settings';

  @override
  String get localPlaylists => 'Local Playlists';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get home => 'Home🏠';

  @override
  String get me => 'Me';

  @override
  String get rank => 'Rank';

  @override
  String get recm => 'Recommend';

  @override
  String get hot => 'Hot🔥';

  @override
  String get sort => 'Sort';

  @override
  String get search => 'Search playlist, song and artist';

  @override
  String get songs => 'Songs';

  @override
  String get played => 'Played';

  @override
  String get likes => 'Likes';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get download => 'Download';

  @override
  String get loginRequired => 'Please login first';

  @override
  String get bug => 'A bug appeared, pls report to hungryhenry101@outlook.com';

  @override
  String get singlePlayer => 'Single Player';

  @override
  String get multiPlayer => 'Multi Player (Coming Soon)';

  @override
  String get singlePlayerOptions => 'Single Player Options';

  @override
  String get multiPlayerOptions => 'Multi Player Options';

  @override
  String get creator => 'Creator';

  @override
  String get createTime => 'Created at';

  @override
  String contains(Object artist, Object count, Object title) {
    return 'Contains $count songs including $title - $artist and more';
  }

  @override
  String get noDes => 'No Description';

  @override
  String get chooseDifficulty => 'Choose Difficulty';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get normal => 'Normal';

  @override
  String get hard => 'Hard';

  @override
  String get custom => 'Custom';

  @override
  String get easyInfo =>
      'Easy mode: 5 times mistake chances, 4 options to choose for Artist or Music title';

  @override
  String get normalInfo =>
      'Normal mode: 3 times mistake chances, 4 options to choose or fill in the blanks with hints for Artist or Music title or Album';

  @override
  String get hardInfo =>
      'Hard mode: 2 times mistake chances, fill in the blanks for Artist or Music title or Album';

  @override
  String get start => 'Start';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String get end => 'End👉';

  @override
  String get chooseMusic => 'Choose the music currently playing';

  @override
  String get chooseArtist => 'Choose the artist of the playing music';

  @override
  String get chooseAlbum => 'Choose the album of the playing music';

  @override
  String get chooseGenre => 'Choose the genre of the playing music';

  @override
  String get enterMusic => 'Enter the name of the playing music';

  @override
  String get enterArtist => 'Enter the artist of the playing music';

  @override
  String get enterAlbum => 'Enter the album of the playing music';

  @override
  String get enterGenre => 'Enter the genre of the playing music';

  @override
  String get tip => 'Tips: ';

  @override
  String get correctAnswer => 'Correct Answer: ';

  @override
  String get correct => 'Correct✔';

  @override
  String get wrong => 'Wrong❌';

  @override
  String quizResult(Object playlist) {
    return 'Result of $playlist';
  }

  @override
  String get details => 'Answer Details';

  @override
  String get pts => 'points';

  @override
  String get quizzes => 'quizzes';

  @override
  String get answer => 'Answer';

  @override
  String get answerTime => 'Answer Time';
}
