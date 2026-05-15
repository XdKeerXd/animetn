import "package:hive/hive.dart";

import "package:animetn/core/app/logging.dart";
import "package:animetn/core/commons/enums/hiveEnums.dart";
import "package:animetn/core/database/anilist/types.dart";

final String _boxName = HiveBox.Animetn.boxName;

class WatchlistManager {
  static Future<void> addToWatchlist({
    required int id,
    required String title,
    required String imageUrl,
    int? totalEpisodes,
    double? rating,
  }) async {
    try {
      var box = await Hive.openBox(_boxName);
      if (!box.isOpen) {
        box = await Hive.openBox(_boxName);
      }
      final List<dynamic> watchlist = List.castFrom(box.get('watchlist') ?? []);
      
      // Remove if it already exists to avoid duplicates
      watchlist.removeWhere((item) => item['id'] == id);
      
      watchlist.add({
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'totalEpisodes': totalEpisodes,
        'rating': rating,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      box.put('watchlist', watchlist);
      box.close();
      Logs.app.log("Added anime $id to local watchlist");
    } catch (err) {
      Logs.app.log("Error adding to watchlist: $err");
    }
  }

  static Future<void> removeFromWatchlist(int id) async {
    try {
      var box = await Hive.openBox(_boxName);
      if (!box.isOpen) {
        box = await Hive.openBox(_boxName);
      }
      final List<dynamic> watchlist = List.castFrom(box.get('watchlist') ?? []);
      
      watchlist.removeWhere((item) => item['id'] == id);
      
      box.put('watchlist', watchlist);
      box.close();
      Logs.app.log("Removed anime $id from local watchlist");
    } catch (err) {
      Logs.app.log("Error removing from watchlist: $err");
    }
  }

  static Future<bool> isInWatchlist(int id) async {
    try {
      var box = await Hive.openBox(_boxName);
      if (!box.isOpen) {
        box = await Hive.openBox(_boxName);
      }
      final List<dynamic> watchlist = List.castFrom(box.get('watchlist') ?? []);
      box.close();
      
      return watchlist.any((item) => item['id'] == id);
    } catch (err) {
      Logs.app.log("Error checking watchlist: $err");
      return false;
    }
  }

  static Future<List<UserAnimeListItem>> getWatchlist() async {
    try {
      final box = await Hive.openBox(_boxName);
      List<dynamic> watchlist = List.castFrom(box.get('watchlist') ?? []);
      
      final List<UserAnimeListItem> items = [];
      if (watchlist.isNotEmpty) {
        for (final e in watchlist.reversed) {
          items.add(UserAnimeListItem(
            id: e['id'],
            title: {'title': e['title']},
            coverImage: e['imageUrl'],
            watchProgress: 0,
            rating: e['rating'],
            episodes: e['totalEpisodes']
          ));
        }
      }
      box.close();
      return items;
    } catch (err) {
      Logs.app.log("Error getting watchlist: $err");
      return [];
    }
  }
}
