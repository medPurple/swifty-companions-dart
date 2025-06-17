import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'token_service.dart';
import 'env.dart';

class AuthService {
  String? error;
  bool loading = false;
  String? accessToken;
  String? refreshToken;

  Future<void> startAuth() async {
    final authUrl = '$AUTH_URL?client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&response_type=code&scope=public';
    final uri = Uri.parse(authUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      error = 'Redirection URL failed';
      print(error);
    }
  }

  Future<String?> exchangeCodeForToken(String code) async {
    loading = true;
    try {
      final response = await http.post(
        Uri.parse(TOKEN_URL),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': CLIENT_ID,
          'client_secret': CLIENT_SECRET,
          'code': code,
          'redirect_uri': REDIRECT_URI,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        accessToken = data['access_token'];
        refreshToken = data['refresh_token'];
        return accessToken;
      } else {
        error = 'Token exchange failed';
        print(response.body);
      }
    } catch (e) {
      error = 'Exchange failed: $e';
    } finally {
      loading = false;
    }
    return null;
  }

  Future<String?> refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse(TOKEN_URL),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': CLIENT_ID,
          'client_secret': CLIENT_SECRET,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        refreshToken = data['refresh_token'];
        return data['access_token'];
      } else {
        error = 'Refresh failed';
      }
    } catch (e) {
      error = 'Refresh error: $e';
    }
    return null;
  }

  String? extractCodeFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters['code'];
  }

  Future<Map<String, dynamic>?> searchUser(String token, String login) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.intra.42.fr/v2/users/$login'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        final newToken = await refreshAccessToken();
        if (newToken != null) {
          await TokenService().clearToken();
          await TokenService().saveToken(newToken);
          return await searchUser(newToken, login);
        }
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }
}
