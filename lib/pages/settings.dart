import 'package:flutter/material.dart';
import '/generated/app_localizations.dart';

import 'package:settings_ui/settings_ui.dart';
import '../utils/preferences.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _darkMode;

  @override
  void initState() {
    super.initState();
    Preferences.getDarkMode().then((value){
      setState(() {
        _darkMode = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.setting),
      ),
      body: SettingsList(
        sections: [
          //外观设置
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.appearance),
            tiles: <SettingsTile>[
              //_darkmode: 2 = follow system, 1 = dark mode, 0 = light mode
              //follow system
              SettingsTile.switchTile(
                initialValue: _darkMode == 2, 
                onToggle: (value) {
                  setState(() {
                    _darkMode = value ? 2 : 0;
                  });
                  final themeMode = value ? ThemeMode.system : ThemeMode.light;
                  Provider.of<ThemeProvider>(context, listen: false).themeMode = themeMode;
                },
                leading: const Icon(Icons.brightness_auto),
                title: Text(AppLocalizations.of(context)!.followSystem),
                activeSwitchColor: Theme.of(context).colorScheme.primary
              ),

              SettingsTile.switchTile(
                enabled: _darkMode != 2,
                onToggle: (value) {
                  setState(() {
                    _darkMode = value ? 1 : 0;
                  });
                  final themeMode = value ? ThemeMode.dark : ThemeMode.light;
                  Provider.of<ThemeProvider>(context, listen: false).themeMode = themeMode;
                },
                initialValue: _darkMode == 1,
                leading: const Icon(Icons.dark_mode),
                title: Text(AppLocalizations.of(context)!.darkMode),
                activeSwitchColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

          //游戏设置
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.gameSettings),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                initialValue: false, 
                onToggle: (value) => print, 
                title: Text("game setting 1"),
                activeSwitchColor: Theme.of(context).colorScheme.primary
              )
            ],
          ),
        ],
      ),
    );
  }
}