import 'dart:io';

import 'package:animetn/core/app/runtimeDatas.dart';
import 'package:animetn/core/data/watchlist.dart';
import 'package:animetn/core/database/anilist/types.dart';
import 'package:animetn/ui/models/widgets/cards.dart';
import 'package:flutter/material.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  List<UserAnimeListItem> watchlist = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    final list = await WatchlistManager.getWatchlist();
    setState(() {
      watchlist = list;
      isLoading = false;
    });
  }

  String getTitle(Map<String, String?> titles) {
    final preferNativeTitle = currentUserSettings?.nativeTitle ?? false;
    final defaultTitle = titles['english'] ?? titles['romaji'] ?? '';
    return preferNativeTitle ? titles['native'] ?? defaultTitle : defaultTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                "My Watchlist",
                style: TextStyle(
                  color: appTheme.textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: appTheme.accentColor))
                  : watchlist.isEmpty
                      ? Center(
                          child: Text(
                            "Nothing in your watchlist yet!",
                            style: TextStyle(
                              color: appTheme.textSubColor,
                              fontFamily: "NunitoSans",
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadWatchlist,
                          child: GridView.builder(
                            padding: EdgeInsets.all(15).copyWith(bottom: 100),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: Platform.isAndroid ? 140 : 180,
                                mainAxisExtent: Platform.isAndroid ? 220 : 265,
                                childAspectRatio: 120 / 220,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10),
                            itemCount: watchlist.length,
                            itemBuilder: (context, index) {
                              final item = watchlist[index];
                              return Cards.animeCard(
                                item.id,
                                getTitle(item.title),
                                item.coverImage,
                                rating: item.rating,
                                isMobile: Platform.isAndroid || Platform.isIOS,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
