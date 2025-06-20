import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkService {
  static const String _bookmarksKey = 'saved_bookmarks';

  static Future<void> saveBookmark({
    required String articleId,
    required String title,
    required String imageUrl,
    required String category,
    required String date,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    
    // Check if already bookmarked
    if (!bookmarks.any((item) => item['articleId'] == articleId)) {
      bookmarks.add({
        'articleId': articleId,
        'title': title,
        'imageUrl': imageUrl,
        'category': category,
        'date': date,
        'description': description,
      });
      await prefs.setString(_bookmarksKey, json.encode(bookmarks));
    }
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey);
    if (bookmarksJson != null) {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  static Future<void> removeBookmark(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((item) => item['articleId'] == articleId);
    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  static Future<bool> isArticleBookmarked(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey);
    if (bookmarksJson != null) {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded.any((item) => item['articleId'] == articleId);
    }
    return false;
  }
}

