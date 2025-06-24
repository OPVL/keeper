import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/token.dart';

class GitLabTokenInfo {
  final int id;
  final String name;
  final bool revoked;
  final DateTime createdAt;
  final String description;
  final List<String> scopes;
  final int userId;
  final DateTime? lastUsedAt;
  final bool active;
  final DateTime expiresAt;
  final String? token;

  GitLabTokenInfo({
    required this.id,
    required this.name,
    required this.revoked,
    required this.createdAt,
    required this.description,
    required this.scopes,
    required this.userId,
    this.lastUsedAt,
    required this.active,
    required this.expiresAt,
    this.token,
  });

  factory GitLabTokenInfo.fromJson(Map<String, dynamic> json) {
    return GitLabTokenInfo(
      id: json['id'],
      name: json['name'],
      revoked: json['revoked'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'] ?? '',
      scopes: List<String>.from(json['scopes']),
      userId: json['user_id'],
      lastUsedAt: json['last_used_at'] != null ? DateTime.parse(json['last_used_at']) : null,
      active: json['active'],
      expiresAt: DateTime.parse(json['expires_at']),
      token: json['token'],
    );
  }
}

class GitLabService {
  final String baseUrl;
  late final String apiUrl;

  GitLabService({required this.baseUrl}) {
    apiUrl = '$baseUrl/api/v4';
    debugPrint('GitLab service initialized with base URL: $baseUrl');
    debugPrint('API URL: $apiUrl');
  }

  Future<bool> validateToken(String token) async {
    if (token.trim().isEmpty) {
      debugPrint('Token is empty');
      return false;
    }

    try {
      debugPrint('Validating GitLab token with URL: $apiUrl/user');
      
      final response = await http.get(
        Uri.parse('$apiUrl/user'),
        headers: {'PRIVATE-TOKEN': token},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Response status: ${response.statusCode}');
      
      if (response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 100 
            ? '${response.body.substring(0, 100)}...' 
            : response.body;
        debugPrint('Response body preview: $bodyPreview');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
  }

  Future<GitLabTokenInfo?> getTokenInfo(String token) async {
    try {
      debugPrint('Getting token info from: $apiUrl/personal_access_tokens/self');
      
      final response = await http.get(
        Uri.parse('$apiUrl/personal_access_tokens/self'),
        headers: {'PRIVATE-TOKEN': token},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Token info status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Token info retrieved successfully');
        return GitLabTokenInfo.fromJson(data);
      }
      
      debugPrint('Failed to get token info: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting token info: $e');
      return null;
    }
  }

  Future<ApiToken?> updateTokenFromRemote(ApiToken token) async {
    try {
      final tokenInfo = await getTokenInfo(token.token);
      if (tokenInfo == null) return null;
      
      return ApiToken(
        id: token.id,
        name: tokenInfo.name,
        token: token.token,
        expiresAt: tokenInfo.expiresAt,
        service: token.service,
      );
    } catch (e) {
      debugPrint('Error updating token from remote: $e');
      return null;
    }
  }
  
  Future<ApiToken?> refreshToken(ApiToken token) async {
    try {
      debugPrint('Refreshing token: ${token.name}');
      
      final response = await http.post(
        Uri.parse('$apiUrl/personal_access_tokens/self/rotate'),
        headers: {'PRIVATE-TOKEN': token.token},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Token refresh status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Token refreshed successfully');
        
        final tokenInfo = GitLabTokenInfo.fromJson(data);
        
        if (tokenInfo.token != null) {
          return ApiToken(
            id: token.id,
            name: tokenInfo.name,
            token: tokenInfo.token!,
            expiresAt: tokenInfo.expiresAt,
            service: token.service,
          );
        }
      }
      
      debugPrint('Failed to refresh token: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  String getTokenCreationUrl() {
    return '$baseUrl/-/profile/personal_access_tokens';
  }
}