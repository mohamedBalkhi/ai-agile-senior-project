import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/decoded_token.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String key, String token) async {
    try {
      await _storage.write(key: key, value: token);
      if (key == 'access_token') {
        try {
          final decodedToken = DecodedToken.fromJwt(token);
          await saveDecodedToken(decodedToken);
        } catch (e) {
          developer.log('Error decoding token: $e', name: 'SecureStorage');
        }
      }
    } catch (e) {
      developer.log('Error saving token: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  static Future<void> saveDecodedToken(DecodedToken decodedToken) async {
    try {
      await _storage.write(
        key: 'decoded_token',
        value: json.encode(decodedToken.toJson()),
      );
    } catch (e) {
      developer.log('Error saving decoded token: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  static Future<String?> getToken(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      developer.log('Error getting token: $e', name: 'SecureStorage');
      return null;
    }
  }

  static Future<DecodedToken?> getDecodedToken() async {
    try {
      final decodedTokenJson = await _storage.read(key: 'decoded_token');
      if (decodedTokenJson != null) {
        return DecodedToken.fromJson(json.decode(decodedTokenJson));
      }
      return null;
    } catch (e) {
      developer.log('Error getting decoded token: $e', name: 'SecureStorage');
      return null;
    }
  }

  static Future<void> deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
      if (key == 'access_token') {
        await _storage.delete(key: 'decoded_token');
      }
    } catch (e) {
      developer.log('Error deleting token: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  static Future<void> deleteAllTokens() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      developer.log('Error deleting all tokens: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  static Future<bool> isTokenExpired() async {
    try {
      final decodedToken = await getDecodedToken();
      if (decodedToken == null) return true;
      
      return decodedToken.isExpired;
    } catch (e) {
      developer.log('Error checking token expiration: $e', name: 'SecureStorage');
      return true;
    }
  }
}
