import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:clipboard/clipboard.dart';
import '../models/token.dart';
import '../services/service_factory.dart';
import '../services/token_storage.dart';
import '../utils/token_formatter.dart';
import 'token_dialog.dart';
import 'token_details_page.dart';
import 'settings_page.dart';

class AppWindow extends StatefulWidget {
  final Function(bool)? onDialogOpenChanged;

  const AppWindow({
    super.key,
    this.onDialogOpenChanged,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing token...')),
      );

      final refreshedToken = await ServiceFactory.refreshToken(token);

      if (refreshedToken != null) {
        await _tokenStorage.saveToken(refreshedToken);
        await _loadTokens(updateFromRemote: false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Copy the new token to clipboard
        FlutterClipboard.copy(refreshedToken.token);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh token'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'API Token Keeper',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
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
                              builder: (context) => const SettingsPage()),
                        ).then((_) {
                          // Notify that dialog is closed
                          widget.onDialogOpenChanged?.call(false);
                          _loadTokens(); // Reload tokens when returning from settings
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Hide Window',
                      onPressed: () => windowManager.hide(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tokens.isEmpty
              ? const Center(child: Text('No tokens added yet'))
              : ListView.builder(
                  itemCount: _tokens.length,
                  itemBuilder: (context, index) {
                    final token = _tokens[index];
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(token.name)),
                          Text(
                            TokenFormatter.obscureToken(token.token),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                          '${token.service} - ${token.isValid ? 'Valid until ${token.expiryFormatted}' : 'Expired'}'),
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
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Text('Refresh Token'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                      onLongPress: () =>
                          FlutterClipboard.copy(token.token).then((_) {
                        _showNotification('Token copied to clipboard');
                      }),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TokenDetailsPage(token: token),
                            settings: RouteSettings(
                              arguments: widget.onDialogOpenChanged,
                            ),
                          ),
                        ).then((_) => _loadTokens(updateFromRemote: false));
                      },
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
