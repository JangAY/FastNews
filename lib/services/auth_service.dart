import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://rest-api-berita.vercel.app/api/v1';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String title,
    required String avatar,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'title': title,
        'avatar': avatar,
      }),
    );

    final responseBody = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseBody['success']) {
        // Simpan token dan data pengguna setelah registrasi berhasil
        await saveToken(responseBody['data']['token']);
        await saveUserData(responseBody['data']['user']);
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to register');
      }
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to register');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
      if (responseBody['success']) {
        // Simpan token dan data pengguna setelah login berhasil
        await saveToken(responseBody['data']['token']);
        await saveUserData(responseBody['data']['user']);
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to login');
      }
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to login');
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}