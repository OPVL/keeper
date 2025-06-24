import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode {
  light,
  dark,
  system,
}

enum ColorPalette {
  default_,
  solarizedDark,
  solarizedLight,
  monokai,
  dracula,
  nord,
}

extension ColorPaletteExtension on ColorPalette {
  String get displayName {
    switch (this) {
      case ColorPalette.default_:
        return 'Default';
      case ColorPalette.solarizedDark:
        return 'Solarized Dark';
      case ColorPalette.solarizedLight:
        return 'Solarized Light';
      case ColorPalette.monokai:
        return 'Monokai';
      case ColorPalette.dracula:
        return 'Dracula';
      case ColorPalette.nord:
        return 'Nord';
    }
  }
}

class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _paletteKey = 'color_palette';
  
  // Get current theme mode
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    if (themeString == null) {
      return ThemeMode.system;
    }
    
    return ThemeMode.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeMode.system,
    );
  }
  
  // Save theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }
  
  // Get current color palette
  Future<ColorPalette> getColorPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteString = prefs.getString(_paletteKey);
    
    if (paletteString == null) {
      return ColorPalette.default_;
    }
    
    return ColorPalette.values.firstWhere(
      (e) => e.toString() == paletteString,
      orElse: () => ColorPalette.default_,
    );
  }
  
  // Save color palette
  Future<void> setColorPalette(ColorPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.toString());
  }
  
  // Get theme data based on mode and palette
  ThemeData getThemeData(ThemeMode mode, ColorPalette palette, bool isDarkMode) {
    if (mode == ThemeMode.system) {
      // Use system preference
      if (isDarkMode) {
        return _getDarkTheme(palette);
      } else {
        return _getLightTheme(palette);
      }
    } else if (mode == ThemeMode.dark) {
      return _getDarkTheme(palette);
    } else {
      return _getLightTheme(palette);
    }
  }
  
  ThemeData _getLightTheme(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.default_:
        return AppTheme.lightTheme;
      case ColorPalette.solarizedLight:
        return AppTheme.solarizedLightTheme;
      case ColorPalette.monokai:
        return AppTheme.monokaiLightTheme;
      case ColorPalette.dracula:
        return AppTheme.draculaLightTheme;
      case ColorPalette.nord:
        return AppTheme.nordLightTheme;
      case ColorPalette.solarizedDark:
        return AppTheme.solarizedLightTheme; // Fallback to light version
    }
  }
  
  ThemeData _getDarkTheme(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.default_:
        return AppTheme.darkTheme;
      case ColorPalette.solarizedDark:
        return AppTheme.solarizedDarkTheme;
      case ColorPalette.monokai:
        return AppTheme.monokaiDarkTheme;
      case ColorPalette.dracula:
        return AppTheme.draculaDarkTheme;
      case ColorPalette.nord:
        return AppTheme.nordDarkTheme;
      case ColorPalette.solarizedLight:
        return AppTheme.solarizedDarkTheme; // Fallback to dark version
    }
  }
}

// Theme data
class AppTheme {
  // Common styles
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );
  
  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
  );
  
  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide.none,
  );
  
  // Default Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF2979FF),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2979FF),
      secondary: Color(0xFF2979FF),
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2979FF),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2979FF),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF757575),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Default Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF64B5F6),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF323232),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF64B5F6),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF64B5F6),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFBBBBBB),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Solarized Dark Theme
  static ThemeData solarizedDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF268BD2), // Blue
    scaffoldBackgroundColor: const Color(0xFF002B36), // Base03
    cardColor: const Color(0xFF073642), // Base02
    dividerColor: const Color(0xFF586E75), // Base01
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF268BD2), // Blue
      secondary: Color(0xFF2AA198), // Cyan
      surface: Color(0xFF073642), // Base02
      background: Color(0xFF002B36), // Base03
      error: Color(0xFFDC322F), // Red
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF073642), // Base02
      foregroundColor: Color(0xFF93A1A1), // Base1
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF073642), // Base02
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF268BD2), // Blue
        foregroundColor: const Color(0xFF002B36), // Base03
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF268BD2), width: 1), // Blue
      ),
      filled: true,
      fillColor: const Color(0xFF073642), // Base02
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF268BD2), // Blue
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF93A1A1), // Base1
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF93A1A1)), // Base1
      bodyMedium: TextStyle(color: Color(0xFF93A1A1)), // Base1
      bodySmall: TextStyle(color: Color(0xFF839496)), // Base0
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Solarized Light Theme
  static ThemeData solarizedLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF268BD2), // Blue
    scaffoldBackgroundColor: const Color(0xFFFDF6E3), // Base3
    cardColor: const Color(0xFFEEE8D5), // Base2
    dividerColor: const Color(0xFF93A1A1), // Base1
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF268BD2), // Blue
      secondary: Color(0xFF2AA198), // Cyan
      surface: Color(0xFFEEE8D5), // Base2
      background: Color(0xFFFDF6E3), // Base3
      error: Color(0xFFDC322F), // Red
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF268BD2), // Blue
      foregroundColor: Color(0xFFFDF6E3), // Base3
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFFEEE8D5), // Base2
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF268BD2), // Blue
        foregroundColor: const Color(0xFFFDF6E3), // Base3
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF268BD2), width: 1), // Blue
      ),
      filled: true,
      fillColor: const Color(0xFFEEE8D5), // Base2
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF268BD2), // Blue
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF586E75), // Base01
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF586E75)), // Base01
      bodyMedium: TextStyle(color: Color(0xFF586E75)), // Base01
      bodySmall: TextStyle(color: Color(0xFF657B83)), // Base00
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Monokai Dark Theme
  static ThemeData monokaiDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFA6E22E), // Green
    scaffoldBackgroundColor: const Color(0xFF272822), // Background
    cardColor: const Color(0xFF3E3D32), // Lighter Background
    dividerColor: const Color(0xFF75715E), // Comment
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFA6E22E), // Green
      secondary: Color(0xFFF92672), // Pink
      surface: Color(0xFF3E3D32), // Lighter Background
      background: Color(0xFF272822), // Background
      error: Color(0xFFF92672), // Pink
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF272822), // Background
      foregroundColor: Color(0xFFF8F8F2), // Foreground
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF3E3D32), // Lighter Background
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFFA6E22E), // Green
        foregroundColor: const Color(0xFF272822), // Background
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFA6E22E), width: 1), // Green
      ),
      filled: true,
      fillColor: const Color(0xFF3E3D32), // Lighter Background
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF66D9EF), // Blue
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFF8F8F2), // Foreground
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF8F8F2)), // Foreground
      bodyMedium: TextStyle(color: Color(0xFFF8F8F2)), // Foreground
      bodySmall: TextStyle(color: Color(0xFFE6DB74)), // Yellow
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Monokai Light Theme (adaptation)
  static ThemeData monokaiLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4D9A06), // Green
    scaffoldBackgroundColor: const Color(0xFFF9F9F5), // Light Background
    cardColor: const Color(0xFFFFFFFA), // White
    dividerColor: const Color(0xFFCCCCC7), // Light Gray
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4D9A06), // Green
      secondary: Color(0xFFD01F5B), // Pink
      surface: Color(0xFFFFFFFA), // White
      background: Color(0xFFF9F9F5), // Light Background
      error: Color(0xFFD01F5B), // Pink
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4D9A06), // Green
      foregroundColor: Color(0xFFFFFFFA), // White
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFFFFFFFA), // White
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF4D9A06), // Green
        foregroundColor: const Color(0xFFFFFFFA), // White
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF4D9A06), width: 1), // Green
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F0), // Light Gray
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0089B3), // Blue
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF272822), // Dark
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF272822)), // Dark
      bodyMedium: TextStyle(color: Color(0xFF272822)), // Dark
      bodySmall: TextStyle(color: Color(0xFF75715E)), // Comment
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Dracula Theme
  static ThemeData draculaDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF50FA7B), // Green
    scaffoldBackgroundColor: const Color(0xFF282A36), // Background
    cardColor: const Color(0xFF44475A), // Current Line
    dividerColor: const Color(0xFF6272A4), // Comment
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF50FA7B), // Green
      secondary: Color(0xFFFF79C6), // Pink
      surface: Color(0xFF44475A), // Current Line
      background: Color(0xFF282A36), // Background
      error: Color(0xFFFF5555), // Red
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF282A36), // Background
      foregroundColor: Color(0xFFF8F8F2), // Foreground
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF44475A), // Current Line
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF50FA7B), // Green
        foregroundColor: const Color(0xFF282A36), // Background
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF50FA7B), width: 1), // Green
      ),
      filled: true,
      fillColor: const Color(0xFF44475A), // Current Line
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF8BE9FD), // Cyan
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFF8F8F2), // Foreground
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF8F8F2)), // Foreground
      bodyMedium: TextStyle(color: Color(0xFFF8F8F2)), // Foreground
      bodySmall: TextStyle(color: Color(0xFFBD93F9)), // Purple
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Dracula Light Theme (adaptation)
  static ThemeData draculaLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF26A269), // Green
    scaffoldBackgroundColor: const Color(0xFFF8F8F2), // Light Background
    cardColor: const Color(0xFFFFFFFF), // White
    dividerColor: const Color(0xFFD8D8D2), // Light Gray
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF26A269), // Green
      secondary: Color(0xFFE356A7), // Pink
      surface: Color(0xFFFFFFFF), // White
      background: Color(0xFFF8F8F2), // Light Background
      error: Color(0xFFE35555), // Red
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF26A269), // Green
      foregroundColor: Color(0xFFFFFFFF), // White
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFFFFFFFF), // White
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF26A269), // Green
        foregroundColor: const Color(0xFFFFFFFF), // White
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF26A269), width: 1), // Green
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F0), // Light Gray
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0086B3), // Cyan
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF282A36), // Background
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF282A36)), // Background
      bodyMedium: TextStyle(color: Color(0xFF282A36)), // Background
      bodySmall: TextStyle(color: Color(0xFF6272A4)), // Comment
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Nord Theme
  static ThemeData nordDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF88C0D0), // Nord8
    scaffoldBackgroundColor: const Color(0xFF2E3440), // Nord0
    cardColor: const Color(0xFF3B4252), // Nord1
    dividerColor: const Color(0xFF4C566A), // Nord3
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF88C0D0), // Nord8
      secondary: Color(0xFF81A1C1), // Nord9
      surface: Color(0xFF3B4252), // Nord1
      background: Color(0xFF2E3440), // Nord0
      error: Color(0xFFBF616A), // Nord11
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3B4252), // Nord1
      foregroundColor: Color(0xFFECEFF4), // Nord6
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFF3B4252), // Nord1
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF88C0D0), // Nord8
        foregroundColor: const Color(0xFF2E3440), // Nord0
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF88C0D0), width: 1), // Nord8
      ),
      filled: true,
      fillColor: const Color(0xFF3B4252), // Nord1
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF88C0D0), // Nord8
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFD8DEE9), // Nord4
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFECEFF4)), // Nord6
      bodyMedium: TextStyle(color: Color(0xFFE5E9F0)), // Nord5
      bodySmall: TextStyle(color: Color(0xFFD8DEE9)), // Nord4
    ),
    fontFamily: 'JetBrainsMono',
  );
  
  // Nord Light Theme
  static ThemeData nordLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF5E81AC), // Nord10
    scaffoldBackgroundColor: const Color(0xFFECEFF4), // Nord6
    cardColor: const Color(0xFFE5E9F0), // Nord5
    dividerColor: const Color(0xFFD8DEE9), // Nord4
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5E81AC), // Nord10
      secondary: Color(0xFF81A1C1), // Nord9
      surface: Color(0xFFE5E9F0), // Nord5
      background: Color(0xFFECEFF4), // Nord6
      error: Color(0xFFBF616A), // Nord11
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF5E81AC), // Nord10
      foregroundColor: Color(0xFFECEFF4), // Nord6
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: _cardShape,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFFE5E9F0), // Nord5
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        elevation: 0,
        backgroundColor: const Color(0xFF5E81AC), // Nord10
        foregroundColor: const Color(0xFFECEFF4), // Nord6
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF5E81AC), width: 1), // Nord10
      ),
      filled: true,
      fillColor: const Color(0xFFE5E9F0), // Nord5
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF5E81AC), // Nord10
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF4C566A), // Nord3
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2E3440)), // Nord0
      bodyMedium: TextStyle(color: Color(0xFF3B4252)), // Nord1
      bodySmall: TextStyle(color: Color(0xFF434C5E)), // Nord2
    ),
    fontFamily: 'JetBrainsMono',
  );
}