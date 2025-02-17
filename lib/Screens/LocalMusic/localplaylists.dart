import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalPlaylistScreen extends StatefulWidget {
  @override
  _LocalPlaylistScreenState createState() => _LocalPlaylistScreenState();
}

class _LocalPlaylistScreenState extends State<LocalPlaylistScreen> {
  List<PlaylistModel> playlistDetails = [];
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!fetched) {
      offlineAudioQuery.getPlaylists().then((value) {
        setState(() {
          fetched = true;
          playlistDetails = value;
        });
      });
    }

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  AppLocalizations.of(context)!.playlists,
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.createPlaylist),
                      leading: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        await showTextInputDialog(
                          context: context,
                          title:
                              AppLocalizations.of(context)!.createNewPlaylist,
                          initialText: '',
                          keyboardType: TextInputType.name,
                          onSubmitted: (String value) async {
                            if (value.trim() != '') {
                              Navigator.pop(context);
                              await offlineAudioQuery.createPlaylist(
                                name: value,
                              );
                              offlineAudioQuery.getPlaylists().then((value) {
                                playlistDetails = value;
                                setState(() {});
                              });
                            }
                          },
                        );
                        setState(() {});
                      },
                    ),
                    if (playlistDetails.isEmpty)
                      const SizedBox()
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: playlistDetails.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7.0),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: QueryArtworkWidget(
                                id: playlistDetails[index].id,
                                type: ArtworkType.PLAYLIST,
                                keepOldArtwork: true,
                                artworkBorder: BorderRadius.circular(7.0),
                                nullArtworkWidget: ClipRRect(
                                  borderRadius: BorderRadius.circular(7.0),
                                  child: const Image(
                                    fit: BoxFit.cover,
                                    height: 50.0,
                                    width: 50.0,
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              playlistDetails[index].playlist,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${playlistDetails[index].numOfSongs} Songs',
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert_rounded),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15.0),
                                ),
                              ),
                              onSelected: (int? value) async {
                                if (value == 0) {
                                  if (await offlineAudioQuery.removePlaylist(
                                    playlistId: playlistDetails[index].id,
                                  )) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      '${AppLocalizations.of(context)!.deleted} ${playlistDetails[index].playlist}',
                                    );
                                    playlistDetails.removeAt(index);
                                    setState(() {});
                                  } else {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      AppLocalizations.of(context)!
                                          .failedDelete,
                                    );
                                  }
                                }
                                // if (value == 3) {
                                //   TextInputDialog().showTextInputDialog(
                                //       context: context,
                                //       keyboardType: TextInputType.text,
                                //       title: AppLocalizations.of(context)!
                                //           .rename,
                                //       initialText:
                                //           playlistDetails[index].playlist,
                                //       onSubmitted: (value) async {
                                //         Navigator.pop(context);
                                //         await offlineAudioQuery
                                //             .renamePlaylist(
                                //                 playlistId:
                                //                     playlistDetails[index].id,
                                //                 newName: value);
                                //         offlineAudioQuery
                                //             .getPlaylists()
                                //             .then((value) {
                                //           playlistDetails = value;
                                //           setState(() {});
                                //         });
                                //       });
                                // }
                              },
                              itemBuilder: (context) => [
                                // PopupMenuItem(
                                //   value: 3,
                                //   child: Row(
                                //     children: [
                                //       const Icon(Icons.edit_rounded),
                                //       const SizedBox(width: 10.0),
                                //       Text(AppLocalizations.of(context)!
                                //           .rename),
                                //     ],
                                //   ),
                                // ),
                                PopupMenuItem(
                                  value: 0,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_rounded),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        AppLocalizations.of(context)!.delete,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final songs =
                                  await offlineAudioQuery.getPlaylistSongs(
                                playlistDetails[index].id,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DownloadedSongs(
                                    title: playlistDetails[index].playlist,
                                    cachedSongs: songs,
                                    playlistId: playlistDetails[index].id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                  ],
                ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
