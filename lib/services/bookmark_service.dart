import 'dart:convert';
import 'package:http/http.dart' as http;

class BookmarkService {
  static const String baseUrl = 'https://rest-api-berita.vercel.app/api/v1';

  Future<void> saveBookmark(String articleId, String token) async {
    final url = Uri.parse('$baseUrl/news/$articleId/bookmark');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save bookmark');
    }
  }

  Future<void> removeBookmark(String articleId, String token) async {
    final url = Uri.parse('$baseUrl/news/$articleId/bookmark');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove bookmark');
    }
  }

  Future<List<dynamic>> getSavedArticles(String token) async {
    final url = Uri.parse('$baseUrl/news/bookmarks/list');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data']['articles'];
    } else {
      throw Exception('Failed to get saved articles');
    }
  }

  Future<bool> isArticleBookmarked(String articleId, String token) async {
    final url = Uri.parse('$baseUrl/news/$articleId/bookmark');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data']['isSaved'] ?? false;
    } else {
      // Jika artikel tidak ditemukan atau error lain, anggap tidak di-bookmark
      return false;
    }
  }
}