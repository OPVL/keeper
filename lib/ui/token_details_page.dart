import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clipboard/clipboard.dart';
import 'package:path/path.dart' as path;
import '../models/token.dart';
import '../models/settings.dart';
import '../services/git_service.dart';
import '../services/service_factory.dart';
import '../services/settings_service.dart';
import '../services/token_storage.dart';
import '../utils/token_formatter.dart';

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
    setState(() {
      _username = settings.username;
    });
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
        onDialogOpenChanged = ModalRoute.of(context)?.settings.arguments as Function(bool)?;
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Git repository. No .git directory found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        
        final updatedRepositories = List<TokenRepository>.from(_token.repositories);
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repository added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          // Show dialog to manually enter URL
          _showManualUrlDialog(directoryPath);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error adding repository: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding repository: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showUsernameDialog() async {
    // Get dialog state callback
    Function(bool)? onDialogOpenChanged;
    try {
      onDialogOpenChanged = ModalRoute.of(context)?.settings.arguments as Function(bool)?;
    } catch (e) {
      debugPrint('No dialog state callback provided: $e');
    }
    
    // Notify that dialog is open
    onDialogOpenChanged?.call(true);
    
    final controller = TextEditingController(text: _username);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please set your username for Git repositories:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
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
      await _settingsService.saveSettings(settings.copyWith(username: result));
      
      setState(() {
        _username = result;
      });
    }
  }
  
  Future<void> _showManualUrlDialog(String directoryPath) async {
    // Get dialog state callback
    Function(bool)? onDialogOpenChanged;
    try {
      onDialogOpenChanged = ModalRoute.of(context)?.settings.arguments as Function(bool)?;
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
            const Text('Could not automatically detect the repository URL. Please enter it manually:'),
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
  
  Future<void> _addRepositoryWithManualUrl(String directoryPath, String url) async {
    try {
      // Create the Git config file with the manual URL
      final configPath = path.join(directoryPath, '.git', 'config');
      final configFile = File(configPath);
      
      if (!await configFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Git config file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      
      final updatedRepositories = List<TokenRepository>.from(_token.repositories);
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repository added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding repository with manual URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding repository: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshToken() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get service type
      final serviceType = ServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == _token.service,
      );
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing token...')),
      );
      
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token refreshed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Copy the new token to clipboard
          FlutterClipboard.copy(refreshedToken.token).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New token copied to clipboard')),
            );
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeRepository(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Repository'),
        content: Text('Are you sure you want to remove this repository?\n\nPath: ${_token.repositories[index].path}\n\nThis will not modify the Git config file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final updatedRepositories = List<TokenRepository>.from(_token.repositories);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_token.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Token',
            onPressed: _refreshToken,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Token',
            onPressed: () {
              FlutterClipboard.copy(_token.token).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied to clipboard')),
                );
              });
            },
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Token Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Service', _token.service),
                          _buildDetailRow('Expires', _token.expiryFormatted),
                          _buildDetailRow('Last Used', _token.lastUsedFormatted),
                          _buildDetailRow('Token', TokenFormatter.obscureToken(_token.token)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Repositories
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Repositories',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                                onPressed: _addRepository,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _token.repositories.isEmpty
                              ? const Text('No repositories added yet')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _token.repositories.length,
                                  itemBuilder: (context, index) {
                                    final repo = _token.repositories[index];
                                    return ListTile(
                                      title: Text(
                                        repo.path,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text('Username: ${repo.username}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeRepository(index),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Refresh history
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Refresh History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _token.refreshHistory.isEmpty
                              ? const Text('No refresh history')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _token.refreshHistory.length,
                                  itemBuilder: (context, index) {
                                    final refresh = _token.refreshHistory[index];
                                    return ListTile(
                                      title: Text(refresh.formattedTimestamp),
                                      subtitle: Text(
                                        'Previous token: ${TokenFormatter.obscureToken(refresh.previousToken)}',
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}