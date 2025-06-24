import 'package:flutter/material.dart';

/// Ensures text has sufficient contrast against its background
class AccessibilityUtils {
  /// Minimum contrast ratio for normal text (WCAG AA)
  static const double minContrastRatio = 4.5;
  
  /// Minimum contrast ratio for large text (WCAG AA)
  static const double minContrastRatioLargeText = 3.0;
  
  /// Returns a color with sufficient contrast against the background
  static Color ensureContrast(Color textColor, Color backgroundColor) {
    if (calculateContrastRatio(textColor, backgroundColor) < minContrastRatio) {
      // If contrast is insufficient, return either black or white based on background
      return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
    return textColor;
  }
  
  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color foreground, Color background) {
    final double foregroundLuminance = foreground.computeLuminance();
    final double backgroundLuminance = background.computeLuminance();
    
    final double lighter = max(foregroundLuminance, backgroundLuminance);
    final double darker = min(foregroundLuminance, backgroundLuminance);
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Returns either black or white depending on which has better contrast with the background
  static Color contrastingColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Helper function for min
  static double min(double a, double b) => a < b ? a : b;
  
  /// Helper function for max
  static double max(double a, double b) => a > b ? a : b;
}

/// Extension methods for Color to add accessibility features
extension AccessibleColorExtension on Color {
  /// Returns a color with sufficient contrast against this color
  Color get contrastingTextColor => AccessibilityUtils.contrastingColor(this);
  
  /// Returns true if this color has sufficient contrast against the background
  bool hasGoodContrast(Color backgroundColor) {
    return AccessibilityUtils.calculateContrastRatio(this, backgroundColor) >= 
        AccessibilityUtils.minContrastRatio;
  }
}