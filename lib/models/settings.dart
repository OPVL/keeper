class ServiceSettings {
  final String id;
  final String name;
  final String baseUrl;
  final bool enabled;
  final String username;

  ServiceSettings({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.enabled = true,
    this.username = '',
  });

  ServiceSettings copyWith({
    String? name,
    String? baseUrl,
    bool? enabled,
    String? username,
  }) {
    return ServiceSettings(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'enabled': enabled,
      'username': username,
    };
  }

  factory ServiceSettings.fromJson(Map<String, dynamic> json) {
    return ServiceSettings(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      enabled: json['enabled'] ?? true,
      username: json['username'] ?? '',
    );
  }
}

class AppSettings {
  final List<ServiceSettings> services;

  AppSettings({
    required this.services,
  });

  AppSettings copyWith({
    List<ServiceSettings>? services,
  }) {
    return AppSettings(
      services: services ?? this.services,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'services': services.map((s) => s.toJson()).toList(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      services: (json['services'] as List?)
              ?.map((s) => ServiceSettings.fromJson(s))
              .toList() ??
          [],
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
    );
  }
}
