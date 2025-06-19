// TODO Implement this library.
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String baseUrl = 'https://rest-api-berita.vercel.app/api/v1';

  Future<Map<String, dynamic>> fetchArticles({int page = 1, int limit = 10, String? category}) async {
    final url = Uri.parse('$baseUrl/news?page=$page&limit=$limit${category != null ? '&category=$category' : ''}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load articles');
    }
  }

  Future<Map<String, dynamic>> fetchTrendingArticles() async {
    final url = Uri.parse('$baseUrl/news/trending?limit=5');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trending articles');
    }
  }

  Future<Map<String, dynamic>> createArticle(Map<String, dynamic> articleData, String token) async {
    final url = Uri.parse('$baseUrl/news');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(articleData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create article');
    }
  }

  Future<Map<String, dynamic>> updateArticle(String id, Map<String, dynamic> articleData, String token) async {
    final url = Uri.parse('$baseUrl/news/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(articleData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update article');
    }
  }

  Future<bool> deleteArticle(String id, String token) async {
    final url = Uri.parse('$baseUrl/news/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getUserArticles(String token) async {
    final url = Uri.parse('$baseUrl/news/user/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user articles');
    }
  }
}