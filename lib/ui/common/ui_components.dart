import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'accessibility_utils.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final double height;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.height = 48.0,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).primaryColor;
    // Ensure text has sufficient contrast against the background
    final Color textColor = backgroundColor.contrastingTextColor;

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (showBackButton)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor, size: 24),
                    tooltip: 'Back',
                    onPressed:
                        onBackPressed ?? () => Navigator.of(context).pop(),
                    // semanticLabel: 'Go back',
                  ),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  semanticsLabel: title,
                ),
              ],
            ),
            Row(
              children: [
                ...actions,
                IconButton(
                  icon: Icon(Icons.close, color: textColor, size: 24),
                  tooltip: 'Hide Window',
                  onPressed: () => windowManager.hide(),
                  // semanticLabel: 'Hide window',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              semanticsLabel: label,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
              semanticsLabel: '$label: $value',
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  semanticsLabel: title,
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

void showAppNotification(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.white : null,
          fontWeight: isError ? FontWeight.bold : null,
        ),
      ),
      backgroundColor: isError ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
