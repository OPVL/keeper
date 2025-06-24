import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/service_factory.dart';
import '../services/theme_service.dart' as app_theme;
import '../services/token_storage.dart';
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
  late final String _appVersion;
  late final String _buildNumber;
  late final String _platformInfo;
  late final String _dartVersion;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.currentThemeMode;
    _selectedPalette = widget.currentPalette;
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.operatingSystem;
      final version = Platform.version;

      setState(() {
        _appVersion = packageInfo.version;
        _dartVersion = version;
        _buildNumber = packageInfo.buildNumber;
        _platformInfo = '$platform (${Platform.operatingSystemVersion})';
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
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

      // Remove duplicate services
      final uniqueServices = <String>{};
      _settings = _settings.copyWith(
        services: _settings.services.where((service) {
          final isUnique = !uniqueServices.contains(service.id);
          uniqueServices.add(service.id);
          return isUnique;
        }).toList(),
      );

      // Save the deduplicated settings
      await _settingsService.saveSettings(_settings);

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
      case app_theme.ColorPalette.solarized:
        return const Color(0xFF268BD2);
      case app_theme.ColorPalette.monokai:
        return const Color(0xFFA6E22E);
      case app_theme.ColorPalette.dracula:
        return const Color(0xFF50FA7B);
      case app_theme.ColorPalette.nord:
        return const Color(0xFF88C0D0);
    }
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete all tokens, settings, and preferences. '
            'This action cannot be undone.\n\n'
            'Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset settings to defaults
      _settings = AppSettings.defaults();
      await _settingsService.saveSettings(_settings);

      // Clear token storage
      final tokenStorage = TokenStorage();
      await tokenStorage.clearAllTokens();

      // Reset theme
      if (widget.onThemeChanged != null) {
        widget.onThemeChanged!(app_theme.ThemeMode.system);
      }

      // Reset palette
      if (widget.onPaletteChanged != null) {
        widget.onPaletteChanged!(app_theme.ColorPalette.default_);
      }

      // Reload settings
      await _loadSettings();

      Navigator.of(context).pop();
      showAppNotification(context, 'All data has been cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      showAppNotification(context, 'Error clearing data: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                      contentPadding: EdgeInsets.zero,
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
                      contentPadding: EdgeInsets.zero,
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
                      contentPadding: EdgeInsets.zero,
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

                // Author section
                SectionCard(
                  title: 'About',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person),
                      title: const Text('Author'),
                      subtitle: const Text('OPVL'),
                      onTap: () => _launchUrl('https://github.com/OPVL'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code),
                      title: const Text('Source Code'),
                      subtitle: const Text('GitHub Repository'),
                      onTap: () => _launchUrl('https://github.com/OPVL/keeper'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.coffee),
                      title: const Text('Support Development'),
                      subtitle: const Text('Buy me a coffee on Ko-fi'),
                      onTap: () =>
                          _launchUrl('https://ko-fi.com/opvlmakesthings'),
                    ),
                    Divider(
                      color: Theme.of(context).dividerColor,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Version'),
                      subtitle: Text('v$_appVersion ($_buildNumber)'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.devices),
                      title: const Text('Platform'),
                      subtitle: Text(_platformInfo),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code),
                      title: const Text('Dart Version'),
                      subtitle: Text(_dartVersion),
                    ),
                  ],
                ),

                // Debug section
                SectionCard(
                  title: 'Debug',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Data'),
                      subtitle: const Text(
                          'Delete all tokens and settings (cannot be undone)'),
                      onTap: _showClearDataDialog,
                    ),
                  ],
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
      tilePadding: EdgeInsets.zero,
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
          padding: EdgeInsets.zero,
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
              SizedBox(height: 12),
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
