import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clipboard/clipboard.dart';
import 'package:keeper/ui/common/accessibility_utils.dart';
import 'package:path/path.dart' as path;
import '../models/token.dart';
import '../models/settings.dart';
import '../services/git_service.dart';
import '../services/service_factory.dart';
import '../services/settings_service.dart';
import '../services/token_storage.dart';
import '../utils/token_formatter.dart';
import 'common/ui_components.dart';

class TokenDetailsPage extends StatefulWidget {
  final ApiToken token;

  const TokenDetailsPage({
    super.key,
    required this.token,
  });

  @override
  State<TokenDetailsPage> createState() => _TokenDetailsPageState();
}

class _TokenDetailsPageState extends State<TokenDetailsPage> {
  late ApiToken _token;
  final TokenStorage _tokenStorage = TokenStorage();
  final SettingsService _settingsService = SettingsService();
  String _username = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final settings = await _settingsService.getSettings();
    final serviceId = _token.service.toLowerCase();

    // Find the service settings for this token's service
    final serviceSettings = settings.services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () =>
          ServiceSettings(id: serviceId, name: _token.service, baseUrl: ''),
    );

    setState(() {
      _username = serviceSettings.username;
    });
  }

  Future<void> _refreshToken() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show loading indicator
      showAppNotification(context, 'Refreshing token...');

      // Refresh token
      final refreshedToken = await ServiceFactory.refreshToken(_token);

      if (refreshedToken != null) {
        // Save the refreshed token
        await _tokenStorage.saveToken(refreshedToken);

        setState(() {
          _token = refreshedToken;
          _isLoading = false;
        });

        // Show success message
        showAppNotification(context, 'Token refreshed successfully');

        // Copy the new token to clipboard
        FlutterClipboard.copy(refreshedToken.token).then((_) {
          showAppNotification(context, 'New token copied to clipboard');
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        showAppNotification(context, 'Failed to refresh token', isError: true);
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');

      setState(() {
        _isLoading = false;
      });

      showAppNotification(context, 'Error refreshing token: $e', isError: true);
    }
  }

  Future<void> _addRepository() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if username is set
      if (_username.isEmpty) {
        _showUsernameDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Notify that file picker is open
      Function(bool)? onDialogOpenChanged;
      try {
        onDialogOpenChanged =
            ModalRoute.of(context)?.settings.arguments as Function(bool)?;
      } catch (e) {
        debugPrint('No dialog state callback provided: $e');
      }
      onDialogOpenChanged?.call(true);

      // Pick directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Git Repository',
      );

      // Notify that file picker is closed
      onDialogOpenChanged?.call(false);

      debugPrint('Selected directory: $directoryPath');

      if (directoryPath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate Git repository
      debugPrint('Validating Git repository: $directoryPath');
      final isValid = await GitService.isValidGitRepository(directoryPath);
      debugPrint('Repository valid: $isValid');

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

      // Update Git config
      debugPrint('Updating Git config with username: $_username');
      final success = await GitService.updateGitConfig(
        directoryPath,
        _username,
        _token.token,
      );

      if (success) {
        // Add repository to token
        final newRepo = TokenRepository(
          path: directoryPath,
          username: _username,
        );

        final updatedRepositories =
            List<TokenRepository>.from(_token.repositories);
        updatedRepositories.add(newRepo);

        final updatedToken = _token.copyWith(
          repositories: updatedRepositories,
          lastUsed: DateTime.now(),
        );

        await _tokenStorage.saveToken(updatedToken);

        setState(() {
          _token = updatedToken;
          _isLoading = false;
        });

        showAppNotification(context, 'Repository added successfully');
      } else {
        // Show dialog to manually enter URL
        _showManualUrlDialog(directoryPath);
      }
    } catch (e) {
      debugPrint('Error adding repository: $e');
      showAppNotification(context, 'Error adding repository: $e',
          isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showUsernameDialog() async {
    // Get dialog state callback
    Function(bool)? onDialogOpenChanged;
    try {
      onDialogOpenChanged =
          ModalRoute.of(context)?.settings.arguments as Function(bool)?;
    } catch (e) {
      debugPrint('No dialog state callback provided: $e');
    }

    // Notify that dialog is open
    onDialogOpenChanged?.call(true);

    // Get service name with proper capitalization
    final serviceName = _token.service.substring(0, 1).toUpperCase() +
        _token.service.substring(1).toLowerCase();

    final controller = TextEditingController(text: _username);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $serviceName Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter your $serviceName username:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '$serviceName Username',
                hintText: 'Enter your $serviceName username',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Notify that dialog is closed
    onDialogOpenChanged?.call(false);

    if (result != null && result.isNotEmpty) {
      final settings = await _settingsService.getSettings();
      final serviceId = _token.service.toLowerCase();

      // Find the index of the service
      final serviceIndex =
          settings.services.indexWhere((s) => s.id == serviceId);

      if (serviceIndex >= 0) {
        // Update the existing service
        final updatedServices = List<ServiceSettings>.from(settings.services);
        updatedServices[serviceIndex] =
            updatedServices[serviceIndex].copyWith(username: result);

        await _settingsService
            .saveSettings(settings.copyWith(services: updatedServices));
      } else {
        // Add a new service if it doesn't exist
        final updatedServices = List<ServiceSettings>.from(settings.services);
        updatedServices.add(ServiceSettings(
          id: serviceId,
          name: _token.service,
          baseUrl: '',
          username: result,
        ));

        await _settingsService
            .saveSettings(settings.copyWith(services: updatedServices));
      }

      setState(() {
        _username = result;
      });
    }
  }

  Future<void> _showManualUrlDialog(String directoryPath) async {
    // Get dialog state callback
    Function(bool)? onDialogOpenChanged;
    try {
      onDialogOpenChanged =
          ModalRoute.of(context)?.settings.arguments as Function(bool)?;
    } catch (e) {
      debugPrint('No dialog state callback provided: $e');
    }

    // Notify that dialog is open
    onDialogOpenChanged?.call(true);

    final controller = TextEditingController(text: 'https://');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Repository URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Could not automatically detect the repository URL. Please enter it manually:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Repository URL',
                hintText: 'https://example.com/repo.git',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Notify that dialog is closed
    onDialogOpenChanged?.call(false);

    if (result != null && result.isNotEmpty) {
      await _addRepositoryWithManualUrl(directoryPath, result);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addRepositoryWithManualUrl(
      String directoryPath, String url) async {
    try {
      // Create the Git config file with the manual URL
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

      // Parse the URL and create a new URL with credentials
      final Uri uri = Uri.parse(url);
      final String domain = '${uri.host}${uri.path}';
      final String newUrl = 'https://$_username:${_token.token}@$domain';

      // Check if the remote "origin" section exists
      final RegExp remoteOriginRegex = RegExp(
        r'\[remote\s+"origin"\]',
        multiLine: true,
      );

      if (remoteOriginRegex.hasMatch(content)) {
        // Update the existing remote "origin" section
        final RegExp urlRegex = RegExp(
          r'(\[remote\s+"origin"\][\s\S]*?url\s*=\s*)([^\n]+)',
          multiLine: true,
        );

        if (urlRegex.hasMatch(content)) {
          content = content.replaceFirstMapped(
            urlRegex,
            (match) => '${match.group(1)}$newUrl',
          );
        } else {
          // Add URL to existing remote "origin" section
          content = content.replaceFirst(
            remoteOriginRegex,
            '[remote "origin"]\n\turl = $newUrl',
          );
        }
      } else {
        // Add new remote "origin" section
        content += '\n[remote "origin"]\n\turl = $newUrl\n';
      }

      await configFile.writeAsString(content);

      // Add repository to token
      final newRepo = TokenRepository(
        path: directoryPath,
        username: _username,
      );

      final updatedRepositories =
          List<TokenRepository>.from(_token.repositories);
      updatedRepositories.add(newRepo);

      final updatedToken = _token.copyWith(
        repositories: updatedRepositories,
        lastUsed: DateTime.now(),
      );

      await _tokenStorage.saveToken(updatedToken);

      setState(() {
        _token = updatedToken;
        _isLoading = false;
      });

      showAppNotification(context, 'Repository added successfully');
    } catch (e) {
      debugPrint('Error adding repository with manual URL: $e');
      showAppNotification(context, 'Error adding repository: $e',
          isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeRepository(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Repository'),
        content: Text(
            'Are you sure you want to remove this repository?\n\nPath: ${_token.repositories[index].path}\n\nThis will not modify the Git config file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedRepositories =
          List<TokenRepository>.from(_token.repositories);
      updatedRepositories.removeAt(index);

      final updatedToken = _token.copyWith(
        repositories: updatedRepositories,
      );

      await _tokenStorage.saveToken(updatedToken);

      setState(() {
        _token = updatedToken;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppHeader(
        title: _token.name,
        showBackButton: true,
        actions: [
          Semantics(
            label: 'Refresh Token',
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: background.contrastingTextColor,
              ),
              onPressed: _refreshToken,
              tooltip: 'Refresh Token',
            ),
          ),
          Semantics(
            label: 'Copy Token to Clipboard',
            child: IconButton(
              icon: Icon(
                Icons.copy,
                color: background.contrastingTextColor,
              ),
              tooltip: 'Copy Token',
              onPressed: () {
                FlutterClipboard.copy(_token.token).then((_) {
                  showAppNotification(context, 'Token copied to clipboard');
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Token details
                  SectionCard(
                    title: 'Token Details',
                    children: [
                      DetailRow(label: 'Service', value: _token.service),
                      DetailRow(label: 'Expires', value: _token.expiryDateOnly),
                      DetailRow(
                          label: 'Last Used', value: _token.lastUsedFormatted),
                      DetailRow(
                        label: 'Token',
                        value: TokenFormatter.obscureToken(_token.token),
                      ),
                      DetailRow(
                        label: 'Username',
                        value: _username.isEmpty ? 'Not set' : _username,
                      ),
                    ],
                  ),

                  // Repositories
                  SectionCard(
                    title: 'Repositories',
                    actions: [
                      ElevatedButton.icon(
                        style: Theme.of(context).elevatedButtonTheme.style,
                        icon: Icon(
                          Icons.add,
                          semanticLabel: 'Add Repository',
                          color: background.contrastingTextColor,
                        ),
                        label: Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: background.contrastingTextColor,
                          ),
                        ),
                        onPressed: _addRepository,
                      ),
                    ],
                    children: [
                      if (_token.repositories.isEmpty)
                        const Text('No repositories added yet')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _token.repositories.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final repo = _token.repositoriesSorted[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                repo.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'path: ${repo.path}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remove Repository',
                                onPressed: () => _removeRepository(index),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  // Refresh history
                  SectionCard(
                    title: 'Refresh History',
                    children: [
                      if (_token.refreshHistory.isEmpty)
                        const Text('No refresh history')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _token.refreshHistory.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final refresh = _token.refreshHistory[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(refresh.formattedTimestamp),
                              subtitle: Text(
                                'Previous token: ${TokenFormatter.obscureToken(refresh.previousToken)}',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
