import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final storage = FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    try {
      await clearToken();
      await storage.write(key: 'userToken', value: token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await storage.read(key: 'userToken');
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await storage.delete(key: 'userToken');
    } catch (e) {
      print('Error deleting token: $e');
    }
  }
}