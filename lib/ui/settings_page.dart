import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/service_factory.dart';
import '../services/theme_service.dart' as app_theme;
import 'common/ui_components.dart';

class SettingsPage extends StatefulWidget {
  final app_theme.ThemeMode currentThemeMode;
  final app_theme.ColorPalette currentPalette;
  final Function(app_theme.ThemeMode)? onThemeChanged;
  final Function(app_theme.ColorPalette)? onPaletteChanged;

  const SettingsPage({
    super.key,
    this.currentThemeMode = app_theme.ThemeMode.system,
    this.currentPalette = app_theme.ColorPalette.default_,
    this.onThemeChanged,
    this.onPaletteChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  late AppSettings _settings;
  final Map<String, TextEditingController> _controllers = {};
  app_theme.ThemeMode _selectedThemeMode = app_theme.ThemeMode.system;
  app_theme.ColorPalette _selectedPalette = app_theme.ColorPalette.default_;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
    _selectedPalette = widget.currentPalette;
    _loadSettings();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settings = await _settingsService.getSettings();

      // Set username controller
      // _usernameController.text = _settings.username;

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
      showAppNotification(context, 'Settings saved');
    } catch (e) {
      showAppNotification(context, 'Error saving settings: $e', isError: true);
    }
  }

  void _changeTheme(app_theme.ThemeMode mode) {
    setState(() {
      _selectedThemeMode = mode;
    });

    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(mode);
    }
  }

  void _changePalette(app_theme.ColorPalette palette) {
    setState(() {
      _selectedPalette = palette;
    });

    if (widget.onPaletteChanged != null) {
      widget.onPaletteChanged!(palette);
    }
  }

  Color _getPaletteColor(app_theme.ColorPalette palette) {
    switch (palette) {
      case app_theme.ColorPalette.default_:
        return const Color(0xFF2979FF);
      case app_theme.ColorPalette.solarizedDark:
        return const Color(0xFF268BD2);
      case app_theme.ColorPalette.solarizedLight:
        return const Color(0xFF268BD2);
      case app_theme.ColorPalette.monokai:
        return const Color(0xFFA6E22E);
      case app_theme.ColorPalette.dracula:
        return const Color(0xFF50FA7B);
      case app_theme.ColorPalette.nord:
        return const Color(0xFF88C0D0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Settings',
        showBackButton: true,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Theme section
                SectionCard(
                  title: 'Theme',
                  children: [
                    ListTile(
                      title: const Text('Light'),
                      leading: const Icon(Icons.light_mode),
                      trailing: Radio<app_theme.ThemeMode>(
                        value: app_theme.ThemeMode.light,
                        groupValue: _selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) {
                            _changeTheme(value);
                          }
                        },
                      ),
                      onTap: () => _changeTheme(app_theme.ThemeMode.light),
                    ),
                    ListTile(
                      title: const Text('Dark'),
                      leading: const Icon(Icons.dark_mode),
                      trailing: Radio<app_theme.ThemeMode>(
                        value: app_theme.ThemeMode.dark,
                        groupValue: _selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) {
                            _changeTheme(value);
                          }
                        },
                      ),
                      onTap: () => _changeTheme(app_theme.ThemeMode.dark),
                    ),
                    ListTile(
                      title: const Text('System'),
                      leading: const Icon(Icons.brightness_auto),
                      trailing: Radio<app_theme.ThemeMode>(
                        value: app_theme.ThemeMode.system,
                        groupValue: _selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) {
                            _changeTheme(value);
                          }
                        },
                      ),
                      onTap: () => _changeTheme(app_theme.ThemeMode.system),
                    ),
                  ],
                ),

                // Color Palette section
                SectionCard(
                  title: 'Color Palette',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app_theme.ColorPalette.values.map((palette) {
                        final isSelected = _selectedPalette == palette;
                        return InkWell(
                          onTap: () => _changePalette(palette),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getPaletteColor(palette).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getPaletteColor(palette),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 20)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  palette.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Services section
                SectionCard(
                  title: 'Services',
                  children: _settings.services
                      .map((service) => _buildServiceTile(service))
                      .toList(),
                ),

                // Services section
                SectionCard(
                  title: 'Services',
                  children: _settings.services
                      .map((service) => _buildServiceTile(service))
                      .toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildServiceTile(ServiceSettings service) {
    final urlController = _controllers[service.id];
    if (urlController == null) return const SizedBox.shrink();

    // Create a username controller for this service
    final usernameController = TextEditingController(text: service.username);

    return ExpansionTile(
      title: Text(service.name),
      subtitle: service.username.isNotEmpty
          ? Text('Username: ${service.username}',
              style: TextStyle(fontSize: 12))
          : null,
      leading: Switch(
        value: service.enabled,
        onChanged: (value) async {
          final updatedService = service.copyWith(enabled: value);
          setState(() {
            final index =
                _settings.services.indexWhere((s) => s.id == service.id);
            if (index >= 0) {
              final updatedServices =
                  List<ServiceSettings>.from(_settings.services);
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
              const SizedBox(height: 8),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'e.g., https://gitlab.example.com',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: '${service.name} Username',
                  hintText: 'Enter your username for ${service.name}',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final urlValue = urlController.text;
                  final usernameValue = usernameController.text;

                  if (urlValue != service.baseUrl ||
                      usernameValue != service.username) {
                    final updatedService = service.copyWith(
                      baseUrl: urlValue,
                      username: usernameValue,
                    );

                    setState(() {
                      final index = _settings.services
                          .indexWhere((s) => s.id == service.id);
                      if (index >= 0) {
                        final updatedServices =
                            List<ServiceSettings>.from(_settings.services);
                        updatedServices[index] = updatedService;
                        _settings =
                            _settings.copyWith(services: updatedServices);
                      }
                    });

                    await _saveServiceSettings(updatedService);
                  }
                },
                child: const Text('Save Settings'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
