class ServiceSettings {
  final String id;
  final String name;
  final String baseUrl;
  final bool enabled;

  ServiceSettings({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.enabled = true,
  });

  ServiceSettings copyWith({
    String? name,
    String? baseUrl,
    bool? enabled,
  }) {
    return ServiceSettings(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'enabled': enabled,
    };
  }

  factory ServiceSettings.fromJson(Map<String, dynamic> json) {
    return ServiceSettings(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      enabled: json['enabled'] ?? true,
    );
  }
}

class AppSettings {
  final List<ServiceSettings> services;
  final String username;

  AppSettings({
    required this.services,
    this.username = '',
  });

  AppSettings copyWith({
    List<ServiceSettings>? services,
    String? username,
  }) {
    return AppSettings(
      services: services ?? this.services,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'services': services.map((s) => s.toJson()).toList(),
      'username': username,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      services: (json['services'] as List?)
              ?.map((s) => ServiceSettings.fromJson(s))
              .toList() ??
          [],
      username: json['username'] ?? '',
    );
  }

  factory AppSettings.defaults() {
    return AppSettings(
      services: [
        ServiceSettings(
          id: 'gitlab',
          name: 'GitLab',
          baseUrl: 'https://gitlab.com',
        ),
      ],
      username: '',
    );
  }
}