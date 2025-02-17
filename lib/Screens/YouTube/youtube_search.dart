import 'dart:ui';

import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/search_bar.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSearchPage extends StatefulWidget {
  final String query;
  const YouTubeSearchPage({Key? key, required this.query}) : super(key: key);
  @override
  _YouTubeSearchPageState createState() => _YouTubeSearchPageState();
}

class _YouTubeSearchPageState extends State<YouTubeSearchPage> {
  String query = '';
  bool status = false;
  List<Video> searchedList = [];
  bool fetched = false;
  bool done = true;
  bool liveSearch =
      Hive.box('settings').get('liveSearch', defaultValue: true) as bool;
  // List ytSearch =
  // Hive.box('settings').get('ytSearch', defaultValue: []) as List;
  // bool showHistory =
  // Hive.box('settings').get('showHistory', defaultValue: true) as bool;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.query;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      YouTubeServices()
          .fetchSearchResults(query == '' ? widget.query : query)
          .then((value) {
        setState(() {
          searchedList = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.transparent,
                body: SearchBar(
                  controller: _controller,
                  liveSearch: liveSearch,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  hintText: AppLocalizations.of(context)!.searchYt,
                  onSubmitted: (_query) async {
                    setState(() {
                      fetched = false;
                      query = _query;
                      status = false;
                      searchedList = [];
                    });
                  },
                  body: (!fetched)
                      ? SizedBox(
                          child: Center(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.width / 7,
                              width: MediaQuery.of(context).size.width / 7,
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : searchedList.isEmpty
                          ? emptyScreen(
                              context,
                              0,
                              ':( ',
                              100,
                              AppLocalizations.of(
                                context,
                              )!
                                  .sorry,
                              60,
                              AppLocalizations.of(
                                context,
                              )!
                                  .resultsNotFound,
                              20,
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  itemCount: searchedList.length,
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    80,
                                    15,
                                    0,
                                  ),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10.0,
                                      ),
                                      child: Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: GestureDetector(
                                            onTap: () async {
                                              setState(() {
                                                done = false;
                                              });
                                              final Map? response =
                                                  await YouTubeServices()
                                                      .formatVideo(
                                                video: searchedList[index],
                                                quality: Hive.box('settings')
                                                    .get(
                                                      'ytQuality',
                                                      defaultValue: 'High',
                                                    )
                                                    .toString(),
                                                // preferM4a: Hive.box(
                                                //         'settings')
                                                //     .get('preferM4a',
                                                //         defaultValue:
                                                //             true) as bool
                                              );
                                              setState(() {
                                                done = true;
                                              });
                                              response == null
                                                  ? ShowSnackBar().showSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .ytLiveAlert,
                                                    )
                                                  : Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        opaque: false,
                                                        pageBuilder:
                                                            (_, __, ___) =>
                                                                PlayScreen(
                                                          fromMiniplayer: false,
                                                          songsList: [response],
                                                          index: 0,
                                                          offline: false,
                                                          fromDownloads: false,
                                                          recommend: false,
                                                        ),
                                                      ),
                                                    );
                                            },
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      errorWidget:
                                                          (context, _, __) =>
                                                              Image(
                                                        fit: BoxFit.cover,
                                                        image: NetworkImage(
                                                          searchedList[index]
                                                              .thumbnails
                                                              .standardResUrl,
                                                        ),
                                                      ),
                                                      imageUrl:
                                                          searchedList[index]
                                                              .thumbnails
                                                              .maxResUrl,
                                                      placeholder:
                                                          (context, url) =>
                                                              const Image(
                                                        fit: BoxFit.cover,
                                                        image: AssetImage(
                                                          'assets/ytCover.png',
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: Card(
                                                        elevation: 0.0,
                                                        color: Colors.black54,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            6.0,
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4.5),
                                                          child: Text(
                                                            searchedList[index]
                                                                        .duration
                                                                        .toString() ==
                                                                    'null'
                                                                ? AppLocalizations
                                                                        .of(
                                                                    context,
                                                                  )!
                                                                    .live
                                                                : searchedList[
                                                                        index]
                                                                    .duration
                                                                    .toString()
                                                                    .split(
                                                                      '.',
                                                                    )[0]
                                                                    .replaceFirst(
                                                                      '0:0',
                                                                      '',
                                                                    ),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                    left: 15.0,
                                                  ),
                                                  title: Text(
                                                    searchedList[index].title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  // isThreeLine: true,
                                                  subtitle: Text(
                                                    searchedList[index].author,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    // '${searchedList[index]["channelName"]}'
                                                  ),
                                                  // leading: CircleAvatar(
                                                  //   maxRadius: 20,
                                                  //   backgroundImage: AssetImage(
                                                  //       'assets/artist.png'),
                                                  //   foregroundImage:
                                                  //       CachedNetworkImageProvider(
                                                  //           'https://yt3.ggpht.com/ytc/AKedOLS47SGZoq9qhTlM6ANNiXN5I3sUcV4_owFydPkU=s68-c-k-c0x00ffffff-no-rj'
                                                  //           // 'https://yt3.ggpht.com/ytc/${searchedList[index].channelId.value}'

                                                  //           // ["channelImage"],
                                                  //           ),
                                                  // ),
                                                  trailing:
                                                      YtSongTileTrailingMenu(
                                                    data: searchedList[index],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!done)
                                  Center(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width / 2,
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: Card(
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      7,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      7,
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                    strokeWidth: 5,
                                                  ),
                                                ),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .fetchingStream,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                ),
              ),
            ),
            MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
