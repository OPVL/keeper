import 'package:intl/intl.dart';

class TokenRepository {
  final String path;
  final String username;
  
  TokenRepository({
    required this.path,
    required this.username,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'username': username,
    };
  }
  
  factory TokenRepository.fromJson(Map<String, dynamic> json) {
    return TokenRepository(
      path: json['path'],
      username: json['username'],
    );
  }
}

class TokenRefresh {
  final DateTime timestamp;
  final String previousToken;
  
  TokenRefresh({
    required this.timestamp,
    required this.previousToken,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'previousToken': previousToken,
    };
  }
  
  factory TokenRefresh.fromJson(Map<String, dynamic> json) {
    return TokenRefresh(
      timestamp: DateTime.parse(json['timestamp']),
      previousToken: json['previousToken'],
    );
  }
  
  String get formattedTimestamp => DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
}

class ApiToken {
  final String id;
  final String name;
  final String token;
  final DateTime expiresAt;
  final String service;
  final List<TokenRepository> repositories;
  final List<TokenRefresh> refreshHistory;
  final DateTime? lastUsed;

  ApiToken({
    required this.id,
    required this.name,
    required this.token,
    required this.expiresAt,
    required this.service,
    this.repositories = const [],
    this.refreshHistory = const [],
    this.lastUsed,
  });

  bool get isValid => expiresAt.isAfter(DateTime.now());

  String get expiryFormatted => DateFormat('yyyy-MM-dd HH:mm').format(expiresAt);
  
  String get expiryDateOnly => DateFormat('MMM d, yyyy').format(expiresAt);
  
  String get lastUsedFormatted => lastUsed != null 
      ? DateFormat('yyyy-MM-dd HH:mm').format(lastUsed!) 
      : 'Never';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'service': service,
      'repositories': repositories.map((repo) => repo.toJson()).toList(),
      'refreshHistory': refreshHistory.map((refresh) => refresh.toJson()).toList(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory ApiToken.fromJson(Map<String, dynamic> json) {
    return ApiToken(
      id: json['id'],
      name: json['name'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expiresAt']),
      service: json['service'],
      repositories: json['repositories'] != null
          ? List<TokenRepository>.from(
              json['repositories'].map((x) => TokenRepository.fromJson(x)))
          : [],
      refreshHistory: json['refreshHistory'] != null
          ? List<TokenRefresh>.from(
              json['refreshHistory'].map((x) => TokenRefresh.fromJson(x)))
          : [],
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }
  
  ApiToken copyWith({
    String? id,
    String? name,
    String? token,
    DateTime? expiresAt,
    String? service,
    List<TokenRepository>? repositories,
    List<TokenRefresh>? refreshHistory,
    DateTime? lastUsed,
  }) {
    return ApiToken(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      service: service ?? this.service,
      repositories: repositories ?? this.repositories,
      refreshHistory: refreshHistory ?? this.refreshHistory,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
  
  @override
  String toString() {
    return 'ApiToken(id: $id, name: $name, token: ${token.substring(0, 5)}..., expiresAt: $expiryFormatted, service: $service)';
  }
}