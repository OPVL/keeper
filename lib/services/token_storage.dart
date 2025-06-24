import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/token.dart';
import 'service_factory.dart';

class TokenStorage {
  final String _tokensKey = 'api_tokens';
  
  Future<List<ApiToken>> getTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokensJson = prefs.getString(_tokensKey);
      
      if (tokensJson == null) return [];
      
      final List<dynamic> tokensList = jsonDecode(tokensJson);
      return tokensList.map((json) => ApiToken.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting tokens: $e');
      return [];
    }
  }
  
  Future<void> saveToken(ApiToken token) async {
    try {
      final tokens = await getTokens();
      final existingIndex = tokens.indexWhere((t) => t.id == token.id);
      
      if (existingIndex >= 0) {
        debugPrint('Updating existing token: ${token.name} with new value: ${token.token.substring(0, 5)}...');
        tokens[existingIndex] = token;
      } else {
        debugPrint('Adding new token: ${token.name}');
        tokens.add(token);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(tokens.map((t) => t.toJson()).toList());
      await prefs.setString(_tokensKey, jsonData);
      debugPrint('Token saved successfully');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }
  
  Future<void> deleteToken(String id) async {
    try {
      final tokens = await getTokens();
      tokens.removeWhere((token) => token.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tokensKey,
        jsonEncode(tokens.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }
  
  Future<List<ApiToken>> getTokensByService(String service) async {
    final tokens = await getTokens();
    return tokens.where((token) => token.service == service).toList();
  }
  
  Future<void> updateTokensFromRemote() async {
    try {
      final tokens = await getTokens();
      bool hasUpdates = false;
      
      for (int i = 0; i < tokens.length; i++) {
        final updatedToken = await ServiceFactory.updateTokenFromRemote(tokens[i]);
        if (updatedToken != null) {
          tokens[i] = updatedToken;
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _tokensKey,
          jsonEncode(tokens.map((t) => t.toJson()).toList()),
        );
        debugPrint('Tokens updated from remote services');
      }
    } catch (e) {
      debugPrint('Error updating tokens from remote: $e');
    }
  }
}