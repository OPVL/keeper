import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/app_window.dart';
import 'ui/menu_bar.dart';
import 'services/theme_service.dart' as app_theme;

void main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Set window options
  const windowOptions = WindowOptions(
    alwaysOnTop: true,
    size: Size(420, 580),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true, // Hide from taskbar/dock
    titleBarStyle: TitleBarStyle.hidden, // Hide title bar
    windowButtonVisibility: false, // Hide window buttons
    title: 'keeper',
    fullScreen: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions);
  await windowManager.setPreventClose(true);

  // Additional window configuration to hide controls
  await windowManager.setResizable(false);
  await windowManager.setMinimizable(false);
  await windowManager.setMaximizable(false);

  // Set system UI overlay style to remove window controls
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Hide window initially
  await windowManager.hide();

  // Run the app
  runApp(const KeeperApp());
}

class KeeperApp extends StatefulWidget {
  const KeeperApp({super.key});

  @override
  State<KeeperApp> createState() => _KeeperAppState();
}

class _KeeperAppState extends State<KeeperApp>
    with WindowListener, TrayListener {
  MenuBarManager? _menuBarManager;
  final app_theme.ThemeService _themeService = app_theme.ThemeService();
  bool _isDialogOpen = false;
  app_theme.ThemeMode _themeMode = app_theme.ThemeMode.system;
  app_theme.ColorPalette _colorPalette = app_theme.ColorPalette.default_;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _setupPeriodicUpdates();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeMode = await _themeService.getThemeMode();
    final colorPalette = await _themeService.getColorPalette();

    // Determine if we're in dark mode based on platform brightness
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = platformBrightness == Brightness.dark;

    setState(() {
      _themeMode = themeMode;
      _colorPalette = colorPalette;
      _isDarkMode = isDarkMode;
    });
  }

  Future<void> setThemeMode(app_theme.ThemeMode mode) async {
    await _themeService.setThemeMode(mode);
    setState(() {
      _themeMode = mode;
    });
  }

  Future<void> setColorPalette(app_theme.ColorPalette palette) async {
    await _themeService.setColorPalette(palette);
    setState(() {
      _colorPalette = palette;
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _menuBarManager?.dispose();
    super.dispose();
  }

  void _setupPeriodicUpdates() {
    Future.delayed(const Duration(minutes: 5), () async {
      if (_menuBarManager != null) {
        await _menuBarManager!.updateMenuFromRemote();
      }
      _setupPeriodicUpdates(); // Schedule next update
    });
  }

  @override
  void onWindowClose() async {
    debugPrint('Window close event');
    await windowManager.hide();
  }

  @override
  void onWindowFocus() {
    debugPrint('Window focus event');
  }

  @override
  void onWindowBlur() {
    debugPrint('Window blur event');
    // Only hide the window if no dialog is open
    if (!_isDialogOpen) {
      Future.delayed(const Duration(milliseconds: 100), () {
        windowManager.hide();
      });
    }
  }

  // Track dialog state
  void setDialogOpen(bool isOpen) {
    _isDialogOpen = isOpen;
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme data based on mode and palette
    final themeData =
        _themeService.getThemeData(_themeMode, _colorPalette, _isDarkMode);

    return MultiProvider(
      providers: [
        Provider<app_theme.ThemeService>.value(value: _themeService),
      ],
      child: MaterialApp(
        title: 'Keeper',
        theme: themeData,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            // Initialize menu bar manager after the app is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _menuBarManager ??= MenuBarManager(context);
            });

            return AppWindow(
              onDialogOpenChanged: setDialogOpen,
              onThemeChanged: setThemeMode,
              onPaletteChanged: setColorPalette,
              currentThemeMode: _themeMode,
              currentPalette: _colorPalette,
            );
          },
        ),
      ),
    );
  }
}
