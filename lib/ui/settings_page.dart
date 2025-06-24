import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/service_factory.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  late AppSettings _settings;
  final Map<String, TextEditingController> _controllers = {};
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settings = await _settingsService.getSettings();
      
      // Set username controller
      _usernameController.text = _settings.username;
      
      // Create controllers for each service
      for (final service in _settings.services) {
        _controllers[service.id] = TextEditingController(text: service.baseUrl);
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveServiceSettings(ServiceSettings service) async {
    try {
      await _settingsService.updateServiceSettings(service);
      ServiceFactory.clearCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }
  
  Future<void> _saveUsername() async {
    try {
      final updatedSettings = _settings.copyWith(username: _usernameController.text);
      await _settingsService.saveSettings(updatedSettings);
      _settings = updatedSettings;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving username: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Username section
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Git Username',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your Git username',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _saveUsername,
                        child: const Text('Save Username'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Services section
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._settings.services.map((service) => _buildServiceTile(service)),
              ],
            ),
    );
  }

  Widget _buildServiceTile(ServiceSettings service) {
    final controller = _controllers[service.id];
    if (controller == null) return const SizedBox.shrink();
    
    return ExpansionTile(
      title: Text(service.name),
      leading: Switch(
        value: service.enabled,
        onChanged: (value) async {
          final updatedService = service.copyWith(enabled: value);
          setState(() {
            final index = _settings.services.indexWhere((s) => s.id == service.id);
            if (index >= 0) {
              final updatedServices = List<ServiceSettings>.from(_settings.services);
              updatedServices[index] = updatedService;
              _settings = _settings.copyWith(services: updatedServices);
            }
          });
          await _saveServiceSettings(updatedService);
        },
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'e.g., https://gitlab.example.com',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final value = controller.text;
                  if (value != service.baseUrl) {
                    final updatedService = service.copyWith(baseUrl: value);
                    setState(() {
                      final index = _settings.services.indexWhere((s) => s.id == service.id);
                      if (index >= 0) {
                        final updatedServices = List<ServiceSettings>.from(_settings.services);
                        updatedServices[index] = updatedService;
                        _settings = _settings.copyWith(services: updatedServices);
                      }
                    });
                    await _saveServiceSettings(updatedService);
                  }
                },
                child: const Text('Save URL'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}