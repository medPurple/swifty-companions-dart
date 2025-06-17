import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenService {
  final storage = FlutterSecureStorage();

  // Sauvegarde à la fois l'access token et le refresh token
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await clearTokens();
      await storage.write(key: 'accessToken', value: accessToken);
      await storage.write(key: 'refreshToken', value: refreshToken);
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Récupère l'access token
  Future<String?> getAccessToken() async {
    try {
      return await storage.read(key: 'accessToken');
    } catch (e) {
      print('Error retrieving access token: $e');
      return null;
    }
  }

  // Récupère le refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await storage.read(key: 'refreshToken');
    } catch (e) {
      print('Error retrieving refresh token: $e');
      return null;
    }
  }

  // Met à jour uniquement l'access token (quand on refresh)
  Future<void> updateAccessToken(String accessToken) async {
    try {
      await storage.write(key: 'accessToken', value: accessToken);
    } catch (e) {
      print('Error updating access token: $e');
    }
  }

  // Supprime tous les tokens
  Future<void> clearTokens() async {
    try {
      await storage.delete(key: 'accessToken');
      await storage.delete(key: 'refreshToken');
    } catch (e) {
      print('Error deleting tokens: $e');
    }
  }

  // Méthodes de compatibilité pour l'ancien code
  @Deprecated('Use saveTokens instead')
  Future<void> saveToken(String token) async {
    await storage.write(key: 'accessToken', value: token);
  }

  @Deprecated('Use getAccessToken instead')
  Future<String?> getToken() async {
    return await getAccessToken();
  }

  @Deprecated('Use clearTokens instead')
  Future<void> clearToken() async {
    await clearTokens();
  }
}