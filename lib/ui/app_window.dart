import 'dart:io';
import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:keeper/models/settings.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/token.dart';
import '../services/git_service.dart';
import '../services/service_factory.dart';
import '../services/token_storage.dart';
import '../services/theme_service.dart' as app_theme;
import '../services/settings_service.dart';
import '../utils/token_formatter.dart';
import 'common/accessibility_utils.dart';
import 'common/ui_components.dart';
import 'token_dialog.dart';
import 'token_details_page.dart';
import 'settings_page.dart';

class AppWindow extends StatefulWidget {
  final Function(bool)? onDialogOpenChanged;
  final Function(app_theme.ThemeMode)? onThemeChanged;
  final Function(app_theme.ColorPalette)? onPaletteChanged;
  final app_theme.ThemeMode currentThemeMode;
  final app_theme.ColorPalette currentPalette;

  const AppWindow({
    super.key,
    this.onDialogOpenChanged,
    this.onThemeChanged,
    this.onPaletteChanged,
    this.currentThemeMode = app_theme.ThemeMode.system,
    this.currentPalette = app_theme.ColorPalette.default_,
  });

  @override
  State<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends State<AppWindow> {
  final TokenStorage _tokenStorage = TokenStorage();
  List<ApiToken> _tokens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens({bool updateFromRemote = true}) async {
    setState(() {
      _isLoading = true;
    });

    if (updateFromRemote) {
      // Update tokens from remote services
      await _tokenStorage.updateTokensFromRemote();
    }

    final tokens = await _tokenStorage.getTokens();

    setState(() {
      _tokens = tokens;
      _isLoading = false;
    });
  }

  Future<void> _addToken() async {
    // Notify that dialog is open
    widget.onDialogOpenChanged?.call(true);

    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const TokenDialog(),
    );

    // Notify that dialog is closed
    widget.onDialogOpenChanged?.call(false);

    if (result == 'import_from_repo') {
      await _importTokenFromRepo();
    } else if (result != null) {
      await _tokenStorage.saveToken(result);
      await _loadTokens();
    }
  }

  Future<void> _importTokenFromRepo() async {
    try {
      // Notify that dialog is open
      widget.onDialogOpenChanged?.call(true);

      setState(() {
        _isLoading = true;
      });

      // Pick directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Git Repository',
      );

      // Notify that file picker is closed
      widget.onDialogOpenChanged?.call(false);

      if (directoryPath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate Git repository
      final isValid = await GitService.isValidGitRepository(directoryPath);

      if (!isValid) {
        showAppNotification(
          context,
          'Invalid Git repository. No .git directory found.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Extract credentials from Git config
      final configPath = path.join(directoryPath, '.git', 'config');
      final configFile = File(configPath);

      if (!await configFile.exists()) {
        showAppNotification(context, 'Git config file not found',
            isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String content = await configFile.readAsString();

      // Find URL with credentials
      final RegExp urlRegex = RegExp(
        r'url\s*=\s*https?:\/\/([^:]+):([^@]+)@([^\s]+)',
        multiLine: true,
      );

      final match = urlRegex.firstMatch(content);

      if (match == null) {
        showAppNotification(
          context,
          'No credentials found in Git config',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final username = match.group(1)!;
      final token = match.group(2)!;
      final fullDomain = match.group(3)!;
      
      // Extract just the base domain (without path)
      final domain = fullDomain.split('/').first;

      // Determine service type - only GitLab is fully supported
      ServiceType serviceType = ServiceType.gitlab;
      bool isGitLab = domain.toLowerCase().contains('gitlab');

      // Create token name from domain
      final name = domain;

      // Notify that dialog is open
      widget.onDialogOpenChanged?.call(true);

      // Show confirmation dialog with extracted info
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Found credentials in repository: $directoryPath'),
              const SizedBox(height: 16),
              DetailRow(
                  label: 'Service',
                  value: serviceType.toString().split('.').last),
              DetailRow(label: 'Domain', value: domain),
              DetailRow(label: 'Repository', value: fullDomain),
              DetailRow(label: 'Username', value: username),
              DetailRow(
                label: 'Token',
                value: TokenFormatter.obscureToken(token),
              ),
              if (!isGitLab) const SizedBox(height: 16),
              if (!isGitLab)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Non-GitLab Service Detected',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keeper currently only supports full functionality with GitLab. '
                        'Your token will be stored, but automatic refreshing and other '
                        'GitLab-specific features will not work.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      // Notify that dialog is closed
      widget.onDialogOpenChanged?.call(false);

      if (confirmed == true) {
        final serviceName = serviceType.toString().split('.').last;

        // Create new token
        final newToken = ApiToken(
          id: const Uuid().v4(),
          name: name,
          token: token,
          expiresAt: DateTime.now()
              .add(const Duration(days: 365)), // Default to 1 year
          service: serviceName,
          repositories: [
            TokenRepository(
              path: directoryPath,
              username: username,
            ),
          ],
          lastUsed: DateTime.now(),
        );

        // Save the token
        await _tokenStorage.saveToken(newToken);

        // Also update the service settings to save the username
        final settingsService = SettingsService();
        final settings = await settingsService.getSettings();

        // Find if service already exists
        final serviceIndex = settings.services
            .indexWhere((s) => s.id == serviceName.toLowerCase());

        if (serviceIndex >= 0) {
          // Update existing service
          final updatedServices = List<ServiceSettings>.from(settings.services);
          updatedServices[serviceIndex] =
              updatedServices[serviceIndex].copyWith(
            username: username,
            baseUrl: 'https://$domain',
          );

          await settingsService
              .saveSettings(settings.copyWith(services: updatedServices));
        } else {
          // Add new service
          final updatedServices = List<ServiceSettings>.from(settings.services);
          updatedServices.add(ServiceSettings(
            id: serviceName.toLowerCase(),
            name: serviceName,
            baseUrl: 'https://$domain',
            username: username,
          ));

          await settingsService
              .saveSettings(settings.copyWith(services: updatedServices));
        }
        await _loadTokens();

        showAppNotification(context, 'Token imported successfully');
      }
    } catch (e) {
      debugPrint('Error importing token from repository: $e');
      showAppNotification(
        context,
        'Error importing token: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editToken(ApiToken token) async {
    // Notify that dialog is open
    widget.onDialogOpenChanged?.call(true);

    final serviceType = ServiceType.values.firstWhere(
      (e) => e.toString().split('.').last == token.service,
    );

    final result = await showDialog<ApiToken>(
      context: context,
      builder: (context) => TokenDialog(
        serviceType: serviceType,
        token: token,
      ),
    );

    // Notify that dialog is closed
    widget.onDialogOpenChanged?.call(false);

    if (result != null) {
      await _tokenStorage.saveToken(result);
      await _loadTokens();
    }
  }

  Future<void> _deleteToken(ApiToken token) async {
    // Notify that dialog is open
    widget.onDialogOpenChanged?.call(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Token'),
        content: Text('Are you sure you want to delete ${token.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Notify that dialog is closed
    widget.onDialogOpenChanged?.call(false);

    if (confirmed == true) {
      await _tokenStorage.deleteToken(token.id);
      await _loadTokens();
    }
  }

  Future<void> _refreshToken(ApiToken token) async {
    try {
      // Show loading indicator
      showAppNotification(context, 'Refreshing token...');

      final refreshedToken = await ServiceFactory.refreshToken(token);

      if (refreshedToken != null) {
        await _tokenStorage.saveToken(refreshedToken);
        await _loadTokens(updateFromRemote: false);

        showAppNotification(context, 'Token refreshed successfully');

        // Copy the new token to clipboard
        FlutterClipboard.copy(refreshedToken.token);
      } else {
        showAppNotification(context, 'Failed to refresh token', isError: true);
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      showAppNotification(context, 'Error refreshing token: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppHeader(
        title: 'Keeper',
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: background.contrastingTextColor,
            ),
            tooltip: 'Refresh Tokens',
            onPressed: () => _loadTokens(updateFromRemote: true),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: background.contrastingTextColor,
            ),
            tooltip: 'Settings',
            onPressed: () {
              // Notify that dialog is open
              widget.onDialogOpenChanged?.call(true);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    currentThemeMode: widget.currentThemeMode,
                    currentPalette: widget.currentPalette,
                    onThemeChanged: widget.onThemeChanged,
                    onPaletteChanged: widget.onPaletteChanged,
                  ),
                ),
              ).then((_) {
                // Notify that dialog is closed
                widget.onDialogOpenChanged?.call(false);
                _loadTokens(); // Reload tokens when returning from settings
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tokens.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No tokens added yet'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addToken,
                        icon: Icon(
                          Icons.add,
                          color: background.contrastingTextColor,
                        ),
                        label: Text(
                          'Add Token',
                          style: TextStyle(
                            color: background.contrastingTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('or'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _importTokenFromRepo,
                        icon: Icon(
                          Icons.folder_open,
                          color: background.contrastingTextColor,
                        ),
                        label: Text(
                          'Import from Repo',
                          style: TextStyle(
                            color: background.contrastingTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tokens.length,
                  itemBuilder: (context, index) {
                    final token = _tokens[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TokenDetailsPage(token: token),
                            settings: RouteSettings(
                              arguments: widget.onDialogOpenChanged,
                            ),
                          ),
                        ).then((_) => _loadTokens(updateFromRemote: false));
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: token.isValid
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    token.isValid
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: token.isValid
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      token.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 32.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        token.service,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Options',
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'edit':
                                          await _editToken(token);
                                          break;
                                        case 'delete':
                                          await _deleteToken(token);
                                          break;
                                        case 'refresh':
                                          await _refreshToken(token);
                                          break;
                                        case 'copy':
                                          FlutterClipboard.copy(token.token)
                                              .then((_) {
                                            showAppNotification(context,
                                                'Token copied to clipboard');
                                          });
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'copy',
                                        child: Row(
                                          children: [
                                            Icon(Icons.copy, size: 18),
                                            SizedBox(width: 8),
                                            Text('Copy'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'refresh',
                                        child: Row(
                                          children: [
                                            Icon(Icons.refresh, size: 18),
                                            SizedBox(width: 8),
                                            Text('Refresh'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        token.isValid
                                            ? 'Valid until ${token.expiryDateOnly}'
                                            : 'Expired',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: token.isValid
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    TokenFormatter.obscureToken(token.token),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToken,
        tooltip: 'Add New Token',
        child: const Icon(Icons.add, size: 24),
        // Ensure high contrast for accessibility
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
