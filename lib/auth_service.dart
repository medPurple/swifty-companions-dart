import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'token_service.dart';
import 'env.dart';

class AuthService {
  String? error;
  bool loading = false;
  final TokenService _tokenService = TokenService();

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
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        
        // Sauvegarder les deux tokens
        await _tokenService.saveTokens(accessToken, refreshToken);
        
        return accessToken;
      } else {
        error = 'Token exchange failed';
        print('Exchange error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      error = 'Exchange failed: $e';
      print('Exchange exception: $e');
    } finally {
      loading = false;
    }
    return null;
  }

  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        error = 'No refresh token available';
        return null;
      }

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
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token']; // Peut être null selon l'API
        
        // Mettre à jour l'access token
        await _tokenService.updateAccessToken(newAccessToken);
        
        // Si un nouveau refresh token est fourni, le sauvegarder
        if (newRefreshToken != null) {
          await _tokenService.saveTokens(newAccessToken, newRefreshToken);
        }
        
        return newAccessToken;
      } else {
        error = 'Refresh failed: ${response.statusCode}';
        print('Refresh error: ${response.body}');
        
        // Si le refresh token est invalide, nettoyer les tokens
        if (response.statusCode == 400 || response.statusCode == 401) {
          await _tokenService.clearTokens();
        }
      }
    } catch (e) {
      error = 'Refresh error: $e';
      print('Refresh exception: $e');
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
        // Token expiré, tenter de le rafraîchir
        print('Token expired, attempting refresh...');
        final newToken = await refreshAccessToken();
        if (newToken != null) {
          // Réessayer avec le nouveau token
          return await searchUser(newToken, login);
        } else {
          // Le refresh a échoué, l'utilisateur doit se reconnecter
          error = 'Authentication required';
          await _tokenService.clearTokens();
        }
      } else {
        error = 'Search failed: ${response.statusCode}';
        print('Search error: ${response.body}');
      }
    } catch (e) {
      error = 'Error fetching user: $e';
      print('Search exception: $e');
    }
    return null;
  }

  // Méthode pour vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final accessToken = await _tokenService.getAccessToken();
    return accessToken != null;
  }

  // Méthode pour déconnecter l'utilisateur
  Future<void> logout() async {
    await _tokenService.clearTokens();
  }
}