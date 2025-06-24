import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:clipboard/clipboard.dart';
import '../models/token.dart';
import '../services/token_storage.dart';
import '../services/service_factory.dart';
import 'token_dialog.dart';
import 'settings_page.dart';

class MenuBarManager {
  final BuildContext context;
  final TokenStorage _tokenStorage = TokenStorage();

  MenuBarManager(this.context) {
    _initTray();
  }

  Future<void> _initTray() async {
    try {
      debugPrint('Initializing tray icon');

      // Set the tray icon
      await trayManager.setIcon(
        'assets/icons/tray_icon.png',
        isTemplate: true,
      );
      await trayManager.setToolTip('API Token Keeper');

      // Update the menu
      await _updateMenu();

      debugPrint('Tray icon initialized successfully');
    } catch (e) {
      debugPrint('Error initializing tray icon: $e');
    }
  }

  Future<void> updateMenuFromRemote() async {
    await _updateMenu(updateFromRemote: true);
  }

  Future<void> _updateMenu({bool updateFromRemote = false}) async {
    try {
      debugPrint('Updating menu');

      if (updateFromRemote) {
        await _tokenStorage.updateTokensFromRemote();
      }

      // Always get fresh tokens from storage
      final List<ApiToken> tokens = await _tokenStorage.getTokens();
      debugPrint('Retrieved ${tokens.length} tokens for menu');

      final List<MenuItem> menuItems = [];

      // Group tokens by service
      final Map<String, List<ApiToken>> tokensByService = {};
      for (final token in tokens) {
        if (!tokensByService.containsKey(token.service)) {
          tokensByService[token.service] = [];
        }
        tokensByService[token.service]!.add(token);
      }

      // Add service sections
      for (final service in tokensByService.keys) {
        menuItems.add(MenuItem(
          label: service.toUpperCase(),
          disabled: true,
        ));

        for (final token in tokensByService[service]!) {
          menuItems.add(MenuItem(
            label: token.name,
            onClick: (_) => _copyToken(token),
            submenu: Menu(items: [
              MenuItem(
                label: 'Copy Token',
                onClick: (_) => _copyToken(token),
              ),
              MenuItem(
                label: 'Refresh Token',
                onClick: (_) => _refreshToken(token),
              ),
            ]),
          ));
        }

        menuItems.add(MenuItem.separator());
      }

      // Add standard menu items
      menuItems.add(MenuItem(
        label: 'Add New',
        onClick: (_) => _showAddTokenDialog(),
      ));

      menuItems.add(MenuItem(
        label: 'Settings',
        onClick: (_) => _showSettingsDialog(),
      ));

      menuItems.add(MenuItem.separator());

      menuItems.add(MenuItem(
        label: 'Quit',
        onClick: (_) {
          windowManager.destroy();
        },
      ));

      await trayManager.setContextMenu(Menu(items: menuItems));
      debugPrint('Menu updated successfully');
    } catch (e) {
      debugPrint('Error updating menu: $e');
    }
  }

  void _copyToken(ApiToken token) {
    debugPrint('Copying token to clipboard: ${token.name}');
    FlutterClipboard.copy(token.token).then((_) {
      _showNotification('Token copied to clipboard');
    });
  }

  Future<void> _refreshToken(ApiToken token) async {
    try {
      debugPrint('Refreshing token: ${token.name}');

      // Show notification that refresh is in progress
      _showNotification('Refreshing token...');

      final refreshedToken = await ServiceFactory.refreshToken(token);

      if (refreshedToken != null) {
        debugPrint('Token refreshed successfully: ${refreshedToken.name}');

        // Save the refreshed token
        await _tokenStorage.saveToken(refreshedToken);

        // Copy the new token to clipboard immediately
        await FlutterClipboard.copy(refreshedToken.token);
        _showNotification('New token copied to clipboard');

        // Completely rebuild the menu to ensure it has the latest token
        await _rebuildMenu();
      } else {
        debugPrint('Failed to refresh token: ${token.name}');
        _showNotification('Failed to refresh token');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      _showNotification('Error refreshing token');
    }
  }

  Future<void> _rebuildMenu() async {
    try {
      // Destroy and recreate the tray icon to ensure a clean state
      await trayManager.destroy();
      await trayManager.setIcon('assets/icons/tray_icon.png', isTemplate: true);
      await trayManager.setToolTip('API Token Keeper');

      // Get fresh tokens and build a new menu
      final List<ApiToken> tokens = await _tokenStorage.getTokens();
      debugPrint('Rebuilding menu with ${tokens.length} tokens');

      final List<MenuItem> menuItems = [];

      // Group tokens by service
      final Map<String, List<ApiToken>> tokensByService = {};
      for (final token in tokens) {
        if (!tokensByService.containsKey(token.service)) {
          tokensByService[token.service] = [];
        }
        tokensByService[token.service]!.add(token);
      }

      // Add service sections
      for (final service in tokensByService.keys) {
        menuItems.add(MenuItem(
          label: service.toUpperCase(),
          disabled: true,
        ));

        for (final token in tokensByService[service]!) {
          debugPrint(
              'Adding menu item for token: ${token.name} with value: ${token.token.substring(0, 5)}...');
          menuItems.add(MenuItem(
            label: token.name,
            onClick: (_) => _copyToken(token),
            submenu: Menu(items: [
              MenuItem(
                label: 'Copy Token',
                onClick: (_) => _copyToken(token),
              ),
              MenuItem(
                label: 'Refresh Token',
                onClick: (_) => _refreshToken(token),
              ),
            ]),
          ));
        }

        menuItems.add(MenuItem.separator());
      }

      // Add standard menu items
      menuItems.add(MenuItem(
        label: 'Add New',
        onClick: (_) => _showAddTokenDialog(),
      ));

      menuItems.add(MenuItem(
        label: 'Settings',
        onClick: (_) => _showSettingsDialog(),
      ));

      menuItems.add(MenuItem.separator());

      menuItems.add(MenuItem(
        label: 'Quit',
        onClick: (_) {
          windowManager.destroy();
        },
      ));

      await trayManager.setContextMenu(Menu(items: menuItems));
      debugPrint('Menu rebuilt successfully');
    } catch (e) {
      debugPrint('Error rebuilding menu: $e');
    }
  }

  Future<void> _showAddTokenDialog() async {
    await windowManager.show();
    await windowManager.focus();

    final result = await showDialog<ApiToken>(
      context: context,
      builder: (context) => const TokenDialog(),
    );

    if (result != null) {
      await _tokenStorage.saveToken(result);
      await _updateMenu();
    }
  }

  Future<void> _showSettingsDialog() async {
    await windowManager.show();
    await windowManager.focus();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    await _updateMenu();
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void dispose() {
    // Clean up resources if needed
  }
}
