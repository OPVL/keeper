import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  
  Future<AppSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson == null) {
        debugPrint('No settings found, using defaults');
        final defaults = AppSettings.defaults();
        await saveSettings(defaults);
        return defaults;
      }
      
      debugPrint('Loaded settings: $settingsJson');
      return AppSettings.fromJson(jsonDecode(settingsJson));
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return AppSettings.defaults();
    }
  }
  
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = settings.toJson();
      final jsonString = jsonEncode(json);
      await prefs.setString(_settingsKey, jsonString);
      debugPrint('Settings saved successfully: $jsonString');
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }
  
  Future<ServiceSettings?> getServiceSettings(String serviceId) async {
    final settings = await getSettings();
    try {
      return settings.services.firstWhere(
        (s) => s.id == serviceId,
      );
    } catch (e) {
      debugPrint('Service not found: $serviceId');
      return null;
    }
  }
  
  Future<void> updateServiceSettings(ServiceSettings service) async {
    final settings = await getSettings();
    final index = settings.services.indexWhere((s) => s.id == service.id);
    
    if (index >= 0) {
      final updatedServices = List<ServiceSettings>.from(settings.services);
      updatedServices[index] = service;
      final updatedSettings = settings.copyWith(services: updatedServices);
      debugPrint('Updating service ${service.id} with baseUrl: ${service.baseUrl}');
      await saveSettings(updatedSettings);
    } else {
      throw Exception('Service not found: ${service.id}');
    }
  }
  
  Future<void> toggleService(String serviceId, bool enabled) async {
    final settings = await getSettings();
    final index = settings.services.indexWhere((s) => s.id == serviceId);
    
    if (index >= 0) {
      final updatedServices = List<ServiceSettings>.from(settings.services);
      updatedServices[index] = updatedServices[index].copyWith(enabled: enabled);
      await saveSettings(settings.copyWith(services: updatedServices));
    } else {
      throw Exception('Service not found: $serviceId');
    }
  }
}