import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import '../models/token.dart';
import '../services/service_factory.dart';
import '../services/token_storage.dart';
import '../services/theme_service.dart' as app_theme;
import '../utils/token_formatter.dart';
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

    final result = await showDialog<ApiToken>(
      context: context,
      builder: (context) => const TokenDialog(),
    );

    // Notify that dialog is closed
    widget.onDialogOpenChanged?.call(false);

    if (result != null) {
      await _tokenStorage.saveToken(result);
      await _loadTokens();
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
    return Scaffold(
      appBar: AppHeader(
        title: 'Keeper',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Tokens',
            onPressed: () => _loadTokens(updateFromRemote: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
                        icon: const Icon(Icons.add),
                        label: const Text('Add Token'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tokens.length,
                  itemBuilder: (context, index) {
                    final token = _tokens[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(token.name)),
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
                        subtitle: Text(
                          '${token.service} - ${token.isValid ? 'Valid until ${token.expiryFormatted}' : 'Expired'}',
                        ),
                        leading: Icon(
                          token.isValid ? Icons.check_circle : Icons.error,
                          color: token.isValid ? Colors.green : Colors.red,
                        ),
                        trailing: PopupMenuButton<String>(
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
                                FlutterClipboard.copy(token.token).then((_) {
                                  showAppNotification(
                                      context, 'Token copied to clipboard');
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToken,
        child: const Icon(Icons.add),
      ),
    );
  }
}
