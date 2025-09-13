import 'dart:async';
import 'package:flutter/material.dart';
import '/generated/app_localizations.dart';

class SinglePlayer extends StatefulWidget {
  const SinglePlayer({super.key});

  @override
  State<SinglePlayer> createState() => _SinglePlayerState();
}

class _SinglePlayerState extends State<SinglePlayer> {
  int playlistId = 0;
  String playlistTitle = '';
  String createTime = '';
  String createdBy = '';
  String? description;

  int selectedDifficulty = 1;

  Widget _largeScreen() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left Column
        Column(
          children: [
            // Playlist Image
            playlistId == 0
                ? const Center(child: CircularProgressIndicator())
                : Image.network(
                    "https://hungryhenry.cn/musiclab/playlist/$playlistId.jpg",
                    width: 350,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 8),
            // Date and Username
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(createTime, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                Text(createdBy, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              playlistTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Description
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                description ?? AppLocalizations.of(context)!.noDes,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        // Right Column - Difficulty
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.chooseDifficulty,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                //简单
                onTap: () {
                  setState(() {
                    selectedDifficulty = 1;
                  });
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedDifficulty == 1
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.easy,
                      style: TextStyle(
                        color: selectedDifficulty == 1
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDifficulty = 2; //普通
                  });
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedDifficulty == 2
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.normal,
                      style: TextStyle(
                        color: selectedDifficulty == 2
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                //困难
                onTap: () {
                  setState(() {
                    selectedDifficulty = 3;
                  });
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedDifficulty == 3
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.hard,
                      style: TextStyle(
                        color: selectedDifficulty == 3
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                //自定义
                onTap: () {
                  setState(() {
                    selectedDifficulty = 4;
                  });
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedDifficulty == 4
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.custom,
                      style: TextStyle(
                        color: selectedDifficulty == 4
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              )
            ]),
            const SizedBox(height: 20),
            if (selectedDifficulty != 4) ...[
              Text(
                selectedDifficulty == 1
                    ? AppLocalizations.of(context)!.easyInfo
                    : selectedDifficulty == 2
                        ? AppLocalizations.of(context)!.normalInfo
                        : AppLocalizations.of(context)!.hardInfo,
                style: const TextStyle(fontSize: 18),
                softWrap: true,
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/SinglePlayerGame',
                        arguments: {
                          "id": playlistId,
                          "title": playlistTitle,
                          "description": description,
                          "difficulty": selectedDifficulty
                        });
                  },
                  child: Text(AppLocalizations.of(context)!.start))
            ] else ...[
              //blahblah
            ],
          ],
        ),
      ],
    );
  }

  Widget _smallScreen() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Upper row - Playlist Info
          Column(
            children: [
              // Playlist Image
              playlistId == 0
                  ? const Center(child: CircularProgressIndicator())
                  : Image.network(
                      "https://hungryhenry.cn/musiclab/playlist/$playlistId.jpg",
                      width: MediaQuery.of(context).size.width <
                              MediaQuery.of(context).size.height * 0.3
                          ? MediaQuery.of(context).size.width
                          : MediaQuery.of(context).size.height * 0.4,
                      fit: BoxFit.cover,
                    ),
              const SizedBox(height: 8),
              if (description != null) ...[
                Text(
                  description!,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                playlistTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Lower row - Difficulty
          Text(AppLocalizations.of(context)!.chooseDifficulty,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedDifficulty = 1;
                });
              },
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedDifficulty == 1
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(color: Colors.grey),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.easy,
                    style: TextStyle(
                      color:
                          selectedDifficulty == 1 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedDifficulty = 2;
                });
              },
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedDifficulty == 2
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.normal,
                    style: TextStyle(
                      color:
                          selectedDifficulty == 2 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedDifficulty = 3;
                });
              },
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedDifficulty == 3
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.hard,
                    style: TextStyle(
                      color:
                          selectedDifficulty == 3 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // setState(() {
                //   selectedDifficulty = 4;
                // });
              },
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: //selectedDifficulty == 4 ? Theme.of(context).primaryColor :
                      Colors.grey[600],
                  border: Border.all(color: Colors.grey),
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.custom,
                    style: const TextStyle(
                      color: //selectedDifficulty == 4 ? Colors.white :
                          Colors.black,
                    ),
                  ),
                ),
              ),
            )
          ]),
          const SizedBox(height: 20),
          if (selectedDifficulty != 4) ...[
            Text(
              selectedDifficulty == 1
                  ? AppLocalizations.of(context)!.easyInfo
                  : selectedDifficulty == 2
                      ? AppLocalizations.of(context)!.normalInfo
                      : AppLocalizations.of(context)!.hardInfo,
              style: const TextStyle(fontSize: 18),
              softWrap: true,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/SinglePlayerGame', arguments: {
                    "id": playlistId,
                    "title": playlistTitle,
                    "description": description,
                    "difficulty": selectedDifficulty
                  });
                },
                child: Text(AppLocalizations.of(context)!.start))
          ] else ...[
            //blahblah
          ],
        ],
      ),
    );
  }

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
        description = args["description"];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("${AppLocalizations.of(context)!.singlePlayerOptions}: $playlistTitle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MediaQuery.of(context).size.width > 800
            ? _largeScreen()
            : _smallScreen(),
      ),
    );
  }
}
