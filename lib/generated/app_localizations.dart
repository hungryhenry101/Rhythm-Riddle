import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Rhythm Riddle'**
  String get name;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Loggin In...'**
  String get loggingIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'No account? Click here to sign up!'**
  String get register;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'offline mode'**
  String get guest;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailOrName.
  ///
  /// In en, this message translates to:
  /// **'E-mail/Username'**
  String get emailOrName;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'incorrect'**
  String get incorrect;

  /// No description provided for @emptyemail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emptyemail;

  /// No description provided for @emptypassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get emptypassword;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Pls contact hungryhenry101@outlook.com'**
  String get unknownError;

  /// No description provided for @loginExpired.
  ///
  /// In en, this message translates to:
  /// **'login info expired, pls login again'**
  String get loginExpired;

  /// No description provided for @connectError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Pls try again later or use offline mode'**
  String get connectError;

  /// No description provided for @versionCheckError.
  ///
  /// In en, this message translates to:
  /// **'Cannot check version. Pls try again later or contact hungryhenry101@outlook.com'**
  String get versionCheckError;

  /// No description provided for @permissionError.
  ///
  /// In en, this message translates to:
  /// **'Lack of {permission}. Pls grant perm(s) manually'**
  String permissionError(Object permission);

  /// No description provided for @permissionExplain.
  ///
  /// In en, this message translates to:
  /// **'Pls grant notification permission to prevent the process from killing by system'**
  String get permissionExplain;

  /// No description provided for @storagePerm.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePerm;

  /// No description provided for @ntfPerm.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get ntfPerm;

  /// No description provided for @installPerm.
  ///
  /// In en, this message translates to:
  /// **'Install Packages Permission'**
  String get installPerm;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart the App After Granting'**
  String get restart;

  /// No description provided for @installManually.
  ///
  /// In en, this message translates to:
  /// **'Dload and Install by Browser'**
  String get installManually;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK👌'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @relogin.
  ///
  /// In en, this message translates to:
  /// **'Re-Login'**
  String get relogin;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @checkingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking updates...'**
  String get checkingUpdate;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Curr ver.: {version}, new ver. available: {latestVersion}'**
  String update(Object latestVersion, Object version);

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download Progress: '**
  String get downloadProgress;

  /// No description provided for @dlUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get dlUpdate;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date: {date}'**
  String releaseDate(Object date);

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}...'**
  String downloading(Object version);

  /// No description provided for @wearHeadphone.
  ///
  /// In en, this message translates to:
  /// **'Please wear your headphones for a better experience'**
  String get wearHeadphone;

  /// No description provided for @accountManage.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManage;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setting;

  /// No description provided for @localPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Local Playlists'**
  String get localPlaylists;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home🏠'**
  String get home;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @recm.
  ///
  /// In en, this message translates to:
  /// **'Recommend'**
  String get recm;

  /// No description provided for @hot.
  ///
  /// In en, this message translates to:
  /// **'Hot🔥'**
  String get hot;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search playlist, song and artist'**
  String get search;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @played.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get played;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get loginRequired;

  /// No description provided for @bug.
  ///
  /// In en, this message translates to:
  /// **'A bug appeared, pls report to hungryhenry101@outlook.com'**
  String get bug;

  /// No description provided for @singlePlayer.
  ///
  /// In en, this message translates to:
  /// **'Single Player'**
  String get singlePlayer;

  /// No description provided for @multiPlayer.
  ///
  /// In en, this message translates to:
  /// **'Multi Player (Coming Soon)'**
  String get multiPlayer;

  /// No description provided for @singlePlayerOptions.
  ///
  /// In en, this message translates to:
  /// **'Single Player Options'**
  String get singlePlayerOptions;

  /// No description provided for @multiPlayerOptions.
  ///
  /// In en, this message translates to:
  /// **'Multi Player Options'**
  String get multiPlayerOptions;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @createTime.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createTime;

  /// No description provided for @contains.
  ///
  /// In en, this message translates to:
  /// **'Contains {count} songs including {title} - {artist} and more'**
  String contains(Object artist, Object count, Object title);

  /// No description provided for @noDes.
  ///
  /// In en, this message translates to:
  /// **'No Description'**
  String get noDes;

  /// No description provided for @chooseDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Choose Difficulty'**
  String get chooseDifficulty;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @easyInfo.
  ///
  /// In en, this message translates to:
  /// **'Easy mode: 5 times mistake chances, 4 options to choose for Artist or Music title'**
  String get easyInfo;

  /// No description provided for @normalInfo.
  ///
  /// In en, this message translates to:
  /// **'Normal mode: 3 times mistake chances, 4 options to choose or fill in the blanks with hints for Artist or Music title or Album'**
  String get normalInfo;

  /// No description provided for @hardInfo.
  ///
  /// In en, this message translates to:
  /// **'Hard mode: 2 times mistake chances, fill in the blanks for Artist or Music title or Album'**
  String get hardInfo;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End👉'**
  String get end;

  /// No description provided for @chooseMusic.
  ///
  /// In en, this message translates to:
  /// **'Choose the music currently playing'**
  String get chooseMusic;

  /// No description provided for @chooseArtist.
  ///
  /// In en, this message translates to:
  /// **'Choose the artist of the playing music'**
  String get chooseArtist;

  /// No description provided for @chooseAlbum.
  ///
  /// In en, this message translates to:
  /// **'Choose the album of the playing music'**
  String get chooseAlbum;

  /// No description provided for @chooseGenre.
  ///
  /// In en, this message translates to:
  /// **'Choose the genre of the playing music'**
  String get chooseGenre;

  /// No description provided for @enterMusic.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the playing music'**
  String get enterMusic;

  /// No description provided for @enterArtist.
  ///
  /// In en, this message translates to:
  /// **'Enter the artist of the playing music'**
  String get enterArtist;

  /// No description provided for @enterAlbum.
  ///
  /// In en, this message translates to:
  /// **'Enter the album of the playing music'**
  String get enterAlbum;

  /// No description provided for @enterGenre.
  ///
  /// In en, this message translates to:
  /// **'Enter the genre of the playing music'**
  String get enterGenre;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tips: '**
  String get tip;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer: '**
  String get correctAnswer;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct✔'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong❌'**
  String get wrong;

  /// No description provided for @quizResult.
  ///
  /// In en, this message translates to:
  /// **'Result of {playlist}'**
  String quizResult(Object playlist);

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Answer Details'**
  String get details;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get pts;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'quizzes'**
  String get quizzes;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @answerTime.
  ///
  /// In en, this message translates to:
  /// **'Answer Time'**
  String get answerTime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
