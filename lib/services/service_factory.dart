import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings.dart';
import '../models/token.dart';
import 'gitlab_service.dart';
import 'settings_service.dart';
import 'git_service.dart';

enum ServiceType {
  gitlab,
  // Add more services here in the future
}

class ServiceFactory {
  static final SettingsService _settingsService = SettingsService();
  static final Map<String, dynamic> _serviceInstances = {};
  
  static Future<List<ServiceSettings>> getEnabledServices() async {
    final settings = await _settingsService.getSettings();
    return settings.services.where((s) => s.enabled).toList();
  }
  
  static Future<dynamic> getService(ServiceType type) async {
    final serviceId = type.toString().split('.').last;
    
    // Return cached instance if available
    if (_serviceInstances.containsKey(serviceId)) {
      debugPrint('Using cached service instance for $serviceId');
      return _serviceInstances[serviceId];
    }
    
    try {
      // Get service settings
      final serviceSettings = await _settingsService.getServiceSettings(serviceId);
      
      if (serviceSettings == null) {
        throw Exception('Service not found: $serviceId');
      }
      
      if (!serviceSettings.enabled) {
        throw Exception('Service is disabled: $serviceId');
      }
      
      debugPrint('Creating service instance for $serviceId with baseUrl: ${serviceSettings.baseUrl}');
      
      // Create service instance based on type
      switch (type) {
        case ServiceType.gitlab:
          final service = GitLabService(baseUrl: serviceSettings.baseUrl);
          _serviceInstances[serviceId] = service;
          return service;
        default:
          throw Exception('Service not supported: $serviceId');
      }
    } catch (e) {
      debugPrint('Error getting service: $e');
      rethrow;
    }
  }
  
  static Future<void> openTokenCreationPage(ServiceType type) async {
    try {
      final service = await getService(type);
      String url;
      
      switch (type) {
        case ServiceType.gitlab:
          url = (service as GitLabService).getTokenCreationUrl();
          break;
        default:
          throw Exception('Service not supported');
      }
      
      debugPrint('Opening token creation URL: $url');
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $url');
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      rethrow;
    }
  }
  
  static Future<bool> validateToken(ServiceType type, String token) async {
    debugPrint('Validating token for service: ${type.toString()}');
    
    if (token.trim().isEmpty) {
      debugPrint('Token is empty, validation failed');
      return false;
    }
    
    try {
      final service = await getService(type);
      
      switch (type) {
        case ServiceType.gitlab:
          final result = await (service as GitLabService).validateToken(token);
          debugPrint('GitLab token validation result: $result');
          return result;
        default:
          debugPrint('Service not supported: ${type.toString()}');
          throw Exception('Service not supported');
      }
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
  }
  
  static Future<ApiToken?> updateTokenFromRemote(ApiToken token) async {
    try {
      final serviceType = ServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == token.service,
        orElse: () => throw Exception('Service not found: ${token.service}'),
      );
      
      final service = await getService(serviceType);
      
      switch (serviceType) {
        case ServiceType.gitlab:
          return await (service as GitLabService).updateTokenFromRemote(token);
        default:
          throw Exception('Service not supported');
      }
    } catch (e) {
      debugPrint('Error updating token from remote: $e');
      return null;
    }
  }
  
  static Future<ApiToken?> refreshToken(ApiToken token) async {
    try {
      debugPrint('Refreshing token: ${token.name}');
      
      final serviceType = ServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == token.service,
        orElse: () => throw Exception('Service not found: ${token.service}'),
      );
      
      final service = await getService(serviceType);
      
      switch (serviceType) {
        case ServiceType.gitlab:
          final refreshedToken = await (service as GitLabService).refreshToken(token);
          
          if (refreshedToken != null) {
            // Add refresh history
            final refreshHistory = List<TokenRefresh>.from(token.refreshHistory);
            refreshHistory.insert(0, TokenRefresh(
              timestamp: DateTime.now(),
              previousToken: token.token,
            ));
            
            // Update repositories with new token
            for (final repo in token.repositories) {
              await GitService.updateGitConfig(
                repo.path,
                repo.username,
                refreshedToken.token,
              );
            }
            
            // Return updated token with history
            return refreshedToken.copyWith(
              refreshHistory: refreshHistory,
              lastUsed: DateTime.now(),
            );
          }
          return null;
        default:
          throw Exception('Service not supported for token refresh');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }
  
  static String getServiceName(ServiceType type) {
    return type.toString().split('.').last;
  }
  
  // Clear cached service instances when settings change
  static void clearCache() {
    debugPrint('Clearing service instance cache');
    _serviceInstances.clear();
  }
}